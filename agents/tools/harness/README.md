# Harness Tools

Deterministic utilities for generating and validating project harness scripts.

## Scripts

- `generate-harness.sh` - Generates stack-aware harness scripts in `agent-context/harness/`
- `validate-generated-harness.sh` - Validates generated scripts (presence, syntax, markers)

## Usage

```bash
# Generate scripts for current project
.sdlc-agents/tools/harness/generate-harness.sh

# Validate generated scripts
.sdlc-agents/tools/harness/validate-generated-harness.sh
```

You can override paths via `--project-root`, `--sdlc-agents-root`, and `--target-dir`.
