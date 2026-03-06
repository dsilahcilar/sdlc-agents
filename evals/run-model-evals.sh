#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORT_DIR="$SCRIPT_DIR/reports"
REPORT_FILE="$REPORT_DIR/model-evals.json"
CONFIG_FILE="${MODEL_EVAL_CONFIG:-$SCRIPT_DIR/model-eval-config.json}"
MODEL="${OPENAI_MODEL:-gpt-4.1-mini}"
BASE_URL="${OPENAI_BASE_URL:-https://api.openai.com/v1}"
API_URL="$BASE_URL/responses"
STRICT_MODE="${MODEL_EVAL_STRICT:-0}"

mkdir -p "$REPORT_DIR"

write_report() {
  status="$1"
  reason="$2"
  details_json="$3"
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  jq -n \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg timestamp "$now" \
    --arg model "$MODEL" \
    --arg api_url "$API_URL" \
    --argjson details "$details_json" \
    '{
      status: $status,
      reason: $reason,
      timestamp: $timestamp,
      model: $model,
      api_url: $api_url,
      details: $details
    }' > "$REPORT_FILE"
}

if ! command -v jq >/dev/null 2>&1; then
  cat > "$REPORT_FILE" <<'JSON'
{
  "status": "skipped",
  "reason": "jq is required but not installed",
  "mode": "api-backed"
}
JSON
  echo "[evals-model] jq not installed; skipping model evals"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  write_report "skipped" "curl is required but not installed" '{"mode":"api-backed"}'
  echo "[evals-model] curl not installed; skipping model evals"
  exit 0
fi

if [ ! -f "$CONFIG_FILE" ]; then
  write_report "error" "Config file not found" "{}"
  echo "[evals-model] ERROR: config file not found: $CONFIG_FILE"
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  write_report "skipped" "OPENAI_API_KEY is not configured" '{"mode":"api-backed"}'
  echo "[evals-model] OPENAI_API_KEY not set; skipping model evals"
  exit 0
fi

extract_response_text() {
  jq -r '
    if (.output_text? and (.output_text | type == "string")) then
      .output_text
    elif (.output? | type == "array") then
      ([.output[]?.content[]? | if type == "object" then (.text // .value // "") else "" end] | join("\n"))
    elif (.choices? | type == "array") then
      (if (.choices[0].message.content | type) == "string" then
         .choices[0].message.content
       else
         ([.choices[0].message.content[]?.text // ""] | join("\n"))
       end)
    else
      ""
    end
  '
}

normalize_grade_json() {
  raw_text="$1"

  if printf '%s' "$raw_text" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$raw_text"
    return 0
  fi

  candidate=$(printf '%s\n' "$raw_text" | sed -n '/{/,/}/p')
  if [ -n "$candidate" ] && printf '%s' "$candidate" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$candidate"
    return 0
  fi

  return 1
}

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sdlc-model-evals.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM

RESULTS_NDJSON="$TMP_ROOT/results.ndjson"
: > "$RESULTS_NDJSON"

SYSTEM_PROMPT='You are evaluating generated CI harness shell scripts for software quality automation.
Respond with JSON only using this exact schema:
{"verdict":"pass|warn|fail","score":0-100,"summary":"...","findings":["..."],"recommendations":["..."]}
Scoring rubric:
- Correct phase coverage for intended purpose
- Safety and deterministic behavior
- Clarity and maintainability
- Practical reliability for CI usage
Be strict and evidence-based.'

echo "[evals-model] Running API-backed model evals with model=$MODEL"

jq -c '.cases[]' "$CONFIG_FILE" | while IFS= read -r case_json; do
  case_id=$(printf '%s' "$case_json" | jq -r '.id')
  fixture=$(printf '%s' "$case_json" | jq -r '.fixture')
  target_script=$(printf '%s' "$case_json" | jq -r '.target_script')
  min_score=$(printf '%s' "$case_json" | jq -r '.min_score')
  baseline_score=$(printf '%s' "$case_json" | jq -r '.baseline_score')
  max_drop=$(printf '%s' "$case_json" | jq -r '.max_drop')

  fixture_src="$SCRIPT_DIR/fixtures/$fixture"
  project_root="$TMP_ROOT/$fixture"
  harness_dir="$project_root/agent-context/harness"

  if [ ! -d "$fixture_src" ]; then
    jq -n \
      --arg id "$case_id" \
      --arg fixture "$fixture" \
      --arg script "$target_script" \
      '{id:$id, fixture:$fixture, script:$script, verdict:"warn", score:0, summary:"Fixture missing", findings:["Fixture directory not found"], recommendations:["Fix model-eval config fixture path"], error:"fixture_missing"}' >> "$RESULTS_NDJSON"
    continue
  fi

  mkdir -p "$project_root"
  cp -R "$fixture_src"/. "$project_root"/
  mkdir -p "$harness_dir"

  if ! "$REPO_ROOT/agents/tools/harness/generate-harness.sh" --project-root "$project_root" --sdlc-agents-root "$REPO_ROOT/agents" --target-dir "$harness_dir" >/dev/null; then
    jq -n \
      --arg id "$case_id" \
      --arg fixture "$fixture" \
      --arg script "$target_script" \
      '{id:$id, fixture:$fixture, script:$script, verdict:"warn", score:0, summary:"Harness generation failed", findings:["Generator failed for fixture"], recommendations:["Check fixture manifest and generator logic"], error:"generator_failed"}' >> "$RESULTS_NDJSON"
    continue
  fi

  script_path="$harness_dir/$target_script"
  if [ ! -f "$script_path" ]; then
    jq -n \
      --arg id "$case_id" \
      --arg fixture "$fixture" \
      --arg script "$target_script" \
      '{id:$id, fixture:$fixture, script:$script, verdict:"warn", score:0, summary:"Target script missing", findings:["Generated harness missing target script"], recommendations:["Verify generator output contract"], error:"script_missing"}' >> "$RESULTS_NDJSON"
    continue
  fi

  script_content=$(cat "$script_path")
  user_prompt=$(printf '%s\n' \
    "Case ID: $case_id" \
    "Fixture: $fixture" \
    "Target script: $target_script" \
    "Minimum acceptable score: $min_score" \
    "Baseline score: $baseline_score" \
    "Allowed drop: $max_drop" \
    "" \
    "Evaluate this generated script." \
    "BEGIN_SCRIPT" \
    "$script_content" \
    "END_SCRIPT")

  payload=$(jq -n \
    --arg model "$MODEL" \
    --arg system "$SYSTEM_PROMPT" \
    --arg user "$user_prompt" \
    '{
      model: $model,
      temperature: 0,
      input: [
        {role:"system", content:$system},
        {role:"user", content:$user}
      ]
    }')

  response_file="$TMP_ROOT/$case_id.response.json"
  http_code=$(curl -sS \
    -w "%{http_code}" \
    -o "$response_file" \
    -X POST "$API_URL" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" || true)

  if [ -z "$http_code" ]; then
    http_code="000"
  fi

  if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
    error_text=$(cat "$response_file" 2>/dev/null || echo "")
    jq -n \
      --arg id "$case_id" \
      --arg fixture "$fixture" \
      --arg script "$target_script" \
      --arg http_code "$http_code" \
      --arg error_text "$error_text" \
      '{id:$id, fixture:$fixture, script:$script, verdict:"warn", score:0, summary:"API request failed", findings:[("HTTP status: " + $http_code)], recommendations:["Check OPENAI_API_KEY/model/base URL and rerun"], error:"api_request_failed", api_error:$error_text}' >> "$RESULTS_NDJSON"
    continue
  fi

  model_text=$(extract_response_text < "$response_file")
  grade_json=$(normalize_grade_json "$model_text" || true)

  if [ -z "$grade_json" ]; then
    jq -n \
      --arg id "$case_id" \
      --arg fixture "$fixture" \
      --arg script "$target_script" \
      --arg raw "$model_text" \
      '{id:$id, fixture:$fixture, script:$script, verdict:"warn", score:0, summary:"Could not parse model response as JSON", findings:["Model response format mismatch"], recommendations:["Adjust response prompt/schema and retry"], error:"parse_failed", raw_response:$raw}' >> "$RESULTS_NDJSON"
    continue
  fi

  verdict=$(printf '%s' "$grade_json" | jq -r '.verdict // "warn"')
  score=$(printf '%s' "$grade_json" | jq -r '
    .score as $raw
    | if ($raw | type) == "number" then $raw
      elif ($raw | type) == "string" then ($raw | tonumber? // 0)
      else 0
      end
    | if . < 0 then 0 elif . > 100 then 100 else . end
  ')
  summary=$(printf '%s' "$grade_json" | jq -r '.summary // ""')
  findings=$(printf '%s' "$grade_json" | jq '.findings // []')
  recommendations=$(printf '%s' "$grade_json" | jq '.recommendations // []')

  drift=$(jq -n --argjson baseline "$baseline_score" --argjson score "$score" '$baseline - $score')
  score_below_min=$(jq -n --argjson score "$score" --argjson min "$min_score" '$score < $min')
  drift_exceeds_max=$(jq -n --argjson drift "$drift" --argjson max "$max_drop" '$drift > $max')
  drift_flag="none"
  final_verdict="$verdict"

  if [ "$score_below_min" = "true" ] && [ "$final_verdict" = "pass" ]; then
    final_verdict="warn"
  fi

  if [ "$drift_exceeds_max" = "true" ]; then
    drift_flag="exceeds_max_drop"
    if [ "$final_verdict" = "pass" ]; then
      final_verdict="warn"
    fi
  fi

  jq -n \
    --arg id "$case_id" \
    --arg fixture "$fixture" \
    --arg script "$target_script" \
    --arg verdict "$final_verdict" \
    --arg summary "$summary" \
    --argjson score "$score" \
    --argjson min_score "$min_score" \
    --argjson baseline_score "$baseline_score" \
    --argjson max_drop "$max_drop" \
    --argjson drift "$drift" \
    --arg drift_flag "$drift_flag" \
    --argjson findings "$findings" \
    --argjson recommendations "$recommendations" \
    '{
      id:$id,
      fixture:$fixture,
      script:$script,
      verdict:$verdict,
      score:$score,
      min_score:$min_score,
      baseline_score:$baseline_score,
      max_drop:$max_drop,
      drift:$drift,
      drift_flag:$drift_flag,
      summary:$summary,
      findings:$findings,
      recommendations:$recommendations
    }' >> "$RESULTS_NDJSON"
done

results_json=$(jq -s '.' "$RESULTS_NDJSON")

has_fail=$(printf '%s' "$results_json" | jq 'map(select(.verdict == "fail")) | length > 0')
has_warn=$(printf '%s' "$results_json" | jq 'map(select(.verdict == "warn")) | length > 0')

overall_status="pass"
overall_reason="Model evals passed"
if [ "$has_fail" = "true" ]; then
  overall_status="fail"
  overall_reason="One or more cases failed"
elif [ "$has_warn" = "true" ]; then
  overall_status="warn"
  overall_reason="Model eval warnings detected"
fi

details=$(jq -n --argjson cases "$results_json" '{mode:"api-backed", cases:$cases}')
write_report "$overall_status" "$overall_reason" "$details"

echo "[evals-model] status=$overall_status report=$REPORT_FILE"

if [ "$STRICT_MODE" = "1" ] && [ "$overall_status" = "fail" ]; then
  exit 1
fi

exit 0
