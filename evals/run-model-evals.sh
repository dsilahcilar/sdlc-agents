#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/reports"
REPORT_FILE="$REPORT_DIR/model-evals.json"

mkdir -p "$REPORT_DIR"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  cat > "$REPORT_FILE" <<'JSON'
{
  "status": "skipped",
  "reason": "OPENAI_API_KEY is not configured",
  "mode": "scaffold"
}
JSON
  echo "[evals-model] OPENAI_API_KEY not set; model grading scaffold skipped"
  exit 0
fi

cat > "$REPORT_FILE" <<'JSON'
{
  "status": "not_implemented",
  "reason": "Model/trace grading scaffold only. Add API-backed grader in next iteration.",
  "mode": "scaffold"
}
JSON

echo "[evals-model] Model eval scaffold executed (implementation pending)"
exit 0
