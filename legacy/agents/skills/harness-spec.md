# Harness Script Generation Specification

Core concepts for generating project-specific harness scripts.

---

## Output Contract

All harness scripts must follow this format:

```sh
#!/usr/bin/env sh
set -eu

echo "[script-name] ============================================"
echo "[script-name] <action description>"
echo "[script-name] ============================================"

# Operations...

echo ""
echo "[script-name] ============================================"
echo "[script-name] <summary>"
echo "[script-name] ============================================"
```

---

## Quality Gate Phases

| Phase | Purpose | Failure Mode |
|-------|---------|--------------|
| test | Run project's test suite | Hard fail |
| lint | Run configured linters/static analysis | Hard fail |
| arch | Run architecture validation | Hard fail |
| coverage | Check code coverage | Soft (warn) |
| security | Scan for vulnerabilities | Soft (warn) |
| metrics | Collect and compare code metrics | Soft/Hard on regression |

---

## Key Principle

> **Do not assume tools exist. Read the project files and generate only what is configured.**

For each phase:
1. Check if a tool is configured (look for config files)
2. If configured → generate the command
3. If not configured → skip OR use a basic fallback
4. Never assume a tool exists without evidence

---

## Stack-Specific Commands

See `stacks/<detected-stack>.md` for:
- Config files to check
- Commands per phase
- Fallback behavior
