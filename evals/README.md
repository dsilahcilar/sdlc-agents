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

## Model Evals (Scaffold)

```bash
./evals/run-model-evals.sh
```

The model-eval runner is scaffolded and non-blocking in v1. It writes a report to:

- `evals/reports/model-evals.json`

## CI Policy

- Deterministic eval regressions: **fail CI**
- Model eval drift/scaffold: **warn only**
