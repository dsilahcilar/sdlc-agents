#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GENERATOR="$REPO_ROOT/agents/tools/harness/generate-harness.sh"
VALIDATOR="$REPO_ROOT/agents/tools/harness/validate-generated-harness.sh"
PARSER="$REPO_ROOT/agents/tools/skills/parse-skill-directives.sh"
STACK_LIB="$REPO_ROOT/agents/templates/harness/lib/stack-detection.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "[evals] ERROR: jq is required for deterministic evals"
  exit 1
fi

assert_contains() {
  file="$1"
  expected="$2"
  if ! grep -Fq "$expected" "$file"; then
    echo "[evals] ✗ Expected '$expected' in $file"
    exit 1
  fi
}

assert_not_contains() {
  file="$1"
  needle="$2"
  if grep -Fq "$needle" "$file"; then
    echo "[evals] ✗ Unexpected '$needle' in $file"
    exit 1
  fi
}

run_fixture_eval() {
  fixture_name="$1"
  fixture_dir="$REPO_ROOT/evals/fixtures/$fixture_name"
  temp_project="$TMP_ROOT/$fixture_name"

  mkdir -p "$temp_project"
  cp -R "$fixture_dir"/. "$temp_project"/
  mkdir -p "$temp_project/agent-context/harness"

  echo "[evals] Running generator for fixture: $fixture_name"
  "$GENERATOR" --project-root "$temp_project" --sdlc-agents-root "$REPO_ROOT/agents" --target-dir "$temp_project/agent-context/harness"
  "$VALIDATOR" --project-root "$temp_project" --target-dir "$temp_project/agent-context/harness"

  for script in init-project.sh run-feature.sh run-arch-tests.sh run-quality-gates.sh; do
    sh -n "$temp_project/agent-context/harness/$script"
    assert_not_contains "$temp_project/agent-context/harness/$script" "FALLBACK_TEMPLATE"
  done

  cksum "$temp_project/agent-context/harness/init-project.sh" \
    "$temp_project/agent-context/harness/run-feature.sh" \
    "$temp_project/agent-context/harness/run-arch-tests.sh" \
    "$temp_project/agent-context/harness/run-quality-gates.sh" > "$temp_project/checksums.1"

  "$GENERATOR" --project-root "$temp_project" --sdlc-agents-root "$REPO_ROOT/agents" --target-dir "$temp_project/agent-context/harness"

  cksum "$temp_project/agent-context/harness/init-project.sh" \
    "$temp_project/agent-context/harness/run-feature.sh" \
    "$temp_project/agent-context/harness/run-arch-tests.sh" \
    "$temp_project/agent-context/harness/run-quality-gates.sh" > "$temp_project/checksums.2"

  if ! diff -u "$temp_project/checksums.1" "$temp_project/checksums.2" >/dev/null; then
    echo "[evals] ✗ Generator output is not deterministic for fixture $fixture_name"
    exit 1
  fi

  case "$fixture_name" in
    java)
      assert_contains "$temp_project/agent-context/harness/run-quality-gates.sh" "mvn test"
      assert_contains "$temp_project/agent-context/harness/run-quality-gates.sh" "mvn checkstyle:check"
      assert_contains "$temp_project/agent-context/harness/run-arch-tests.sh" "*Arch*"
      ;;
    typescript)
      assert_contains "$temp_project/agent-context/harness/run-quality-gates.sh" "npm run lint"
      assert_contains "$temp_project/agent-context/harness/run-arch-tests.sh" "depcruise"
      ;;
    python)
      assert_contains "$temp_project/agent-context/harness/run-feature.sh" "pytest"
      assert_contains "$temp_project/agent-context/harness/run-arch-tests.sh" "lint-imports"
      ;;
  esac
}

run_parser_eval() {
  echo "[evals] Running directive parser deterministic checks"

  out=$("$PARSER" "Implement auth #TDD,Security !Kafka")
  echo "$out" | jq -e '.only_mode == false' >/dev/null
  echo "$out" | jq -e '.includes | index("tdd")' >/dev/null
  echo "$out" | jq -e '.includes | index("security")' >/dev/null
  echo "$out" | jq -e '.excludes | index("kafka")' >/dev/null

  out=$("$PARSER" "Write tests #only:TDD, Security")
  echo "$out" | jq -e '.only_mode == true' >/dev/null
  echo "$out" | jq -e '.includes | index("tdd")' >/dev/null
  echo "$out" | jq -e '.includes | index("security")' >/dev/null
  echo "$out" | jq -e '.includes | index("") | not' >/dev/null

  if "$PARSER" "Do stuff #only:" >/dev/null 2>&1; then
    echo "[evals] ✗ Expected malformed #only directive to fail"
    exit 1
  fi
}

run_stack_alignment_eval() {
  echo "[evals] Running stack detection alignment check"
  stack=$(sh -c '. "$1"; detect_stack "$2"' sh "$STACK_LIB" "$REPO_ROOT/evals/fixtures/typescript")
  if [ "$stack" != "typescript" ]; then
    echo "[evals] ✗ Expected package.json fixture to resolve to typescript, got: $stack"
    exit 1
  fi
}

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sdlc-evals.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM

echo "[evals] ============================================"
echo "[evals] SDLC deterministic eval suite"
echo "[evals] ============================================"

run_fixture_eval java
run_fixture_eval typescript
run_fixture_eval python
run_parser_eval
run_stack_alignment_eval

echo "[evals] ============================================"
echo "[evals] ✓ Deterministic evals passed"
echo "[evals] ============================================"
