# Self-Evals

This directory contains regression checks for SDLC prompt and harness behavior.

## Deterministic Evals (Required)

```bash
./evals/run-deterministic-evals.sh
```

Checks:
- deterministic harness generation across stack fixtures,
- generated script validity and phase wiring,
- skill directive parsing edge cases,
- stack detection alignment.

## Model Evals (API-Backed, Warn-Only)

```bash
./evals/run-model-evals.sh
```

The model-eval runner calls the Responses API and evaluates generated harness artifacts from fixture projects.

Required env:

- `OPENAI_API_KEY`

Optional env:

- `OPENAI_MODEL` (default: `gpt-4.1-mini`)
- `OPENAI_BASE_URL` (default: `https://api.openai.com/v1`)
- `MODEL_EVAL_CONFIG` (default: `evals/model-eval-config.json`)
- `MODEL_EVAL_STRICT=1` (fail script on overall `fail` status)

Output report:

- `evals/reports/model-evals.json`

## CI Policy

- Deterministic eval regressions: **fail CI**
- Model eval drift/failures: **warn only**
