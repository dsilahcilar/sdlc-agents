#!/usr/bin/env sh
set -eu

usage() {
  cat <<'USAGE'
Usage: generate-harness.sh [options]

Deterministically generate project-specific harness scripts.

Options:
  --project-root <path>      Target project root (default: current directory)
  --sdlc-agents-root <path>  Path to .sdlc-agents (or agents/) root
  --target-dir <path>        Output harness directory (default: <project-root>/agent-context/harness)
  --force                    Overwrite scripts even when no content change
  -h, --help                 Show this help message
USAGE
}

PROJECT_ROOT=""
SDLC_AGENTS_ROOT=""
TARGET_DIR=""
FORCE="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --sdlc-agents-root)
      SDLC_AGENTS_ROOT="${2:-}"
      shift 2
      ;;
    --target-dir)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    --force)
      FORCE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[harness-generator] ERROR: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT=$(pwd)
fi

PROJECT_ROOT=$(cd "$PROJECT_ROOT" && pwd)

if [ -z "$SDLC_AGENTS_ROOT" ]; then
  SDLC_AGENTS_ROOT="$PROJECT_ROOT/.sdlc-agents"
fi

SDLC_AGENTS_ROOT=$(cd "$SDLC_AGENTS_ROOT" 2>/dev/null && pwd) || {
  echo "[harness-generator] ERROR: Invalid sdlc-agents root: $SDLC_AGENTS_ROOT" >&2
  exit 1
}

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$PROJECT_ROOT/agent-context/harness"
fi

mkdir -p "$TARGET_DIR"

is_configured() {
  file="$1"
  pattern="$2"
  [ -f "$file" ] && grep -Eiq "$pattern" "$file"
}

find_first_existing() {
  while [ $# -gt 0 ]; do
    if [ -f "$PROJECT_ROOT/$1" ]; then
      printf '%s' "$1"
      return 0
    fi
    shift
  done
  return 1
}

append_cmd() {
  current="$1"
  next="$2"
  if [ -z "$current" ]; then
    printf '%s' "$next"
  else
    printf '%s && %s' "$current" "$next"
  fi
}

write_script() {
  path="$1"
  tmp="${path}.tmp.$$"
  cat > "$tmp"

  if [ "$FORCE" = "true" ] || [ ! -f "$path" ] || ! cmp -s "$tmp" "$path"; then
    mv "$tmp" "$path"
  else
    rm -f "$tmp"
  fi

  chmod +x "$path"
}

detect_stack() {
  # Prefer shared detector when available.
  SHARED_STACK_LIB="$SDLC_AGENTS_ROOT/templates/harness/lib/stack-detection.sh"
  if [ -f "$SHARED_STACK_LIB" ]; then
    # shellcheck source=/dev/null
    . "$SHARED_STACK_LIB"
    STACK=$(detect_stack "$PROJECT_ROOT")
  elif [ -f "$PROJECT_ROOT/pom.xml" ] || [ -f "$PROJECT_ROOT/build.gradle" ] || [ -f "$PROJECT_ROOT/build.gradle.kts" ]; then
    STACK="java"
  elif [ -f "$PROJECT_ROOT/package.json" ]; then
    STACK="typescript"
  elif [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/setup.py" ] || [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    STACK="python"
  elif [ -f "$PROJECT_ROOT/go.mod" ]; then
    STACK="go"
  elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
    STACK="rust"
  else
    STACK="unknown"
  fi

  if [ "$STACK" = "javascript" ]; then
    STACK="typescript"
  fi

  printf '%s' "$STACK"
}

pm_install_cmd() {
  case "$1" in
    yarn) printf 'yarn install' ;;
    pnpm) printf 'pnpm install' ;;
    *) printf 'npm install' ;;
  esac
}

pm_test_cmd() {
  case "$1" in
    yarn) printf 'yarn test' ;;
    pnpm) printf 'pnpm test' ;;
    *) printf 'npm test' ;;
  esac
}

pm_run_script_cmd() {
  pm="$1"
  script="$2"
  case "$pm" in
    yarn) printf 'yarn %s' "$script" ;;
    pnpm) printf 'pnpm %s' "$script" ;;
    *) printf 'npm run %s' "$script" ;;
  esac
}

STACK=$(detect_stack)
BUILD_SYSTEM="unknown"
INIT_CMD=""
TEST_CMD=""
FEATURE_TEST_TEMPLATE=""
FEATURE_MODULE_TEST_TEMPLATE=""
LINT_CMD=""
ARCH_CMD=""
ARCH_SOFT_FAIL="true"
COVERAGE_CMD=""
SECURITY_CMD=""

if [ "$STACK" = "java" ]; then
  if [ -f "$PROJECT_ROOT/pom.xml" ]; then
    BUILD_SYSTEM="maven"
    INIT_CMD='mvn -q -DskipTests compile'
    TEST_CMD='mvn test'
    FEATURE_TEST_TEMPLATE='mvn test'
    FEATURE_MODULE_TEST_TEMPLATE='mvn test -pl "__FEATURE_MODULE__" -am'

    if is_configured "$PROJECT_ROOT/pom.xml" 'checkstyle'; then
      LINT_CMD=$(append_cmd "$LINT_CMD" 'mvn checkstyle:check')
    fi
    if is_configured "$PROJECT_ROOT/pom.xml" 'spotbugs'; then
      LINT_CMD=$(append_cmd "$LINT_CMD" 'mvn spotbugs:check')
    fi

    ARCH_CMD='mvn test -Dtest="*Arch*" -DfailIfNoTests=false'
    if is_configured "$PROJECT_ROOT/pom.xml" 'archunit'; then
      ARCH_SOFT_FAIL='false'
    fi

    if is_configured "$PROJECT_ROOT/pom.xml" 'jacoco'; then
      COVERAGE_CMD='mvn jacoco:report'
    fi
    if is_configured "$PROJECT_ROOT/pom.xml" 'dependency-check'; then
      SECURITY_CMD='mvn dependency-check:check'
    fi
  else
    BUILD_SYSTEM="gradle"
    INIT_CMD='./gradlew assemble --quiet'
    TEST_CMD='./gradlew test'
    FEATURE_TEST_TEMPLATE='./gradlew test'
    FEATURE_MODULE_TEST_TEMPLATE='./gradlew ":__FEATURE_MODULE__:test"'

    if is_configured "$PROJECT_ROOT/build.gradle" 'checkstyle|spotbugs' || is_configured "$PROJECT_ROOT/build.gradle.kts" 'checkstyle|spotbugs'; then
      LINT_CMD='./gradlew check'
    fi

    ARCH_CMD='./gradlew test --tests "*Arch*"'
    if is_configured "$PROJECT_ROOT/build.gradle" 'archunit' || is_configured "$PROJECT_ROOT/build.gradle.kts" 'archunit'; then
      ARCH_SOFT_FAIL='false'
    fi

    if is_configured "$PROJECT_ROOT/build.gradle" 'jacoco' || is_configured "$PROJECT_ROOT/build.gradle.kts" 'jacoco'; then
      COVERAGE_CMD='./gradlew jacocoTestReport'
    fi
  fi
elif [ "$STACK" = "typescript" ]; then
  BUILD_SYSTEM="node"
  PM="npm"
  if [ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]; then
    PM="pnpm"
  elif [ -f "$PROJECT_ROOT/yarn.lock" ]; then
    PM="yarn"
  fi

  INIT_CMD=$(pm_install_cmd "$PM")

  if is_configured "$PROJECT_ROOT/package.json" '"test"[[:space:]]*:'; then
    TEST_CMD=$(pm_test_cmd "$PM")
    FEATURE_TEST_TEMPLATE="$(pm_test_cmd "$PM") -- --testPathPattern __FEATURE_ID__"
  elif find_first_existing 'vitest.config.ts' 'vitest.config.js' 'vitest.config.mjs' 'vitest.config.cjs' >/dev/null 2>&1; then
    TEST_CMD='npx vitest run'
    FEATURE_TEST_TEMPLATE='npx vitest run __FEATURE_ID__'
  elif find_first_existing 'jest.config.ts' 'jest.config.js' 'jest.config.mjs' 'jest.config.cjs' >/dev/null 2>&1; then
    TEST_CMD='npx jest'
    FEATURE_TEST_TEMPLATE='npx jest __FEATURE_ID__'
  fi

  if is_configured "$PROJECT_ROOT/package.json" '"lint"[[:space:]]*:'; then
    LINT_CMD=$(pm_run_script_cmd "$PM" 'lint')
  elif find_first_existing '.eslintrc' '.eslintrc.js' '.eslintrc.cjs' '.eslintrc.json' >/dev/null 2>&1; then
    LINT_CMD='npx eslint .'
  elif [ -f "$PROJECT_ROOT/biome.json" ]; then
    LINT_CMD='npx biome check .'
  fi

  DEPCRUISE_CONFIG=$(find_first_existing '.dependency-cruiser.js' '.dependency-cruiser.cjs' '.dependency-cruiser.mjs' '.dependency-cruiser.json' || true)
  if [ -n "$DEPCRUISE_CONFIG" ]; then
    ARCH_CMD="npx depcruise src --config $DEPCRUISE_CONFIG"
    ARCH_SOFT_FAIL='false'
  else
    ARCH_CMD='npx madge --circular --extensions ts,tsx,js,jsx src/'
    ARCH_SOFT_FAIL='true'
  fi

  if find_first_existing 'vitest.config.ts' 'vitest.config.js' 'vitest.config.mjs' 'vitest.config.cjs' >/dev/null 2>&1; then
    COVERAGE_CMD='npx vitest run --coverage'
  elif find_first_existing 'jest.config.ts' 'jest.config.js' 'jest.config.mjs' 'jest.config.cjs' >/dev/null 2>&1; then
    COVERAGE_CMD='npx jest --coverage'
  elif is_configured "$PROJECT_ROOT/package.json" '"nyc"'; then
    COVERAGE_CMD='npx nyc npm test'
  fi

  case "$PM" in
    yarn) SECURITY_CMD='yarn audit --level moderate' ;;
    pnpm) SECURITY_CMD='pnpm audit --audit-level moderate' ;;
    *) SECURITY_CMD='npm audit --audit-level=moderate' ;;
  esac
elif [ "$STACK" = "python" ]; then
  BUILD_SYSTEM="python"
  if is_configured "$PROJECT_ROOT/pyproject.toml" '\[tool.poetry\]'; then
    INIT_CMD='poetry install'
  elif [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    INIT_CMD='pip install -r requirements.txt'
  else
    INIT_CMD='pip install -e .'
  fi

  if [ -f "$PROJECT_ROOT/pytest.ini" ] || is_configured "$PROJECT_ROOT/pyproject.toml" '\[tool.pytest'; then
    TEST_CMD='pytest'
    FEATURE_TEST_TEMPLATE='pytest -k __FEATURE_ID__'
  else
    TEST_CMD='python -m unittest discover'
  fi

  if is_configured "$PROJECT_ROOT/pyproject.toml" '\[tool.ruff\]' || [ -f "$PROJECT_ROOT/ruff.toml" ]; then
    LINT_CMD=$(append_cmd "$LINT_CMD" 'ruff check .')
  fi
  if [ -f "$PROJECT_ROOT/.flake8" ] || is_configured "$PROJECT_ROOT/setup.cfg" '\[flake8\]'; then
    LINT_CMD=$(append_cmd "$LINT_CMD" 'flake8')
  fi
  if [ -f "$PROJECT_ROOT/mypy.ini" ] || is_configured "$PROJECT_ROOT/pyproject.toml" '\[tool.mypy\]'; then
    LINT_CMD=$(append_cmd "$LINT_CMD" 'mypy src/')
  fi

  if [ -f "$PROJECT_ROOT/.importlinter" ] || is_configured "$PROJECT_ROOT/pyproject.toml" 'importlinter'; then
    ARCH_CMD='lint-imports'
    ARCH_SOFT_FAIL='false'
  fi

  if is_configured "$PROJECT_ROOT/requirements.txt" 'pytest-cov' || is_configured "$PROJECT_ROOT/pyproject.toml" 'pytest-cov'; then
    COVERAGE_CMD='pytest --cov=src'
  fi
  if is_configured "$PROJECT_ROOT/requirements.txt" 'bandit' || is_configured "$PROJECT_ROOT/pyproject.toml" 'bandit'; then
    SECURITY_CMD='bandit -r src/'
  fi
fi

TEMPLATE_HARNESS_DIR="$SDLC_AGENTS_ROOT/templates/harness"
for metrics_script in collect-metrics.sh compare-metrics.sh archive-metrics.sh; do
  if [ -f "$TEMPLATE_HARNESS_DIR/$metrics_script" ] && [ ! -f "$TARGET_DIR/$metrics_script" ]; then
    cp "$TEMPLATE_HARNESS_DIR/$metrics_script" "$TARGET_DIR/$metrics_script"
    chmod +x "$TARGET_DIR/$metrics_script"
  fi
done

if [ -d "$TEMPLATE_HARNESS_DIR/lib" ] && [ ! -d "$TARGET_DIR/lib" ]; then
  mkdir -p "$TARGET_DIR/lib"
  cp "$TEMPLATE_HARNESS_DIR/lib/stack-detection.sh" "$TARGET_DIR/lib/stack-detection.sh"
  chmod +x "$TARGET_DIR/lib/stack-detection.sh"
fi

INIT_PATH="$TARGET_DIR/init-project.sh"
FEATURE_PATH="$TARGET_DIR/run-feature.sh"
ARCH_PATH="$TARGET_DIR/run-arch-tests.sh"
QUALITY_PATH="$TARGET_DIR/run-quality-gates.sh"

write_script "$INIT_PATH" <<EOF_INIT
#!/usr/bin/env sh
set -eu

# Generated by SDLC Harness Generator. Do not edit manually.
# stack: $STACK
# build_system: $BUILD_SYSTEM

SCRIPT_DIR="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
PROJECT_ROOT="\$(cd "\$SCRIPT_DIR/../.." && pwd)"

echo "[init-project] ============================================"
echo "[init-project] Initializing project environment"
echo "[init-project] ============================================"

INIT_CMD='$INIT_CMD'

if [ -z "\$INIT_CMD" ]; then
  echo "[init-project] No stack-specific init command detected. Skipping."
  exit 0
fi

echo "[init-project] Running: \$INIT_CMD"
if (cd "\$PROJECT_ROOT" && sh -c "\$INIT_CMD"); then
  echo "[init-project] ✓ Initialization completed"
else
  echo "[init-project] ✗ Initialization failed"
  exit 1
fi
EOF_INIT

write_script "$FEATURE_PATH" <<EOF_FEATURE
#!/usr/bin/env sh
set -eu

# Generated by SDLC Harness Generator. Do not edit manually.
# stack: $STACK

SCRIPT_DIR="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
PROJECT_ROOT="\$(cd "\$SCRIPT_DIR/../.." && pwd)"
FEATURE_ID="\${1:-}"
TEST_CMD='$TEST_CMD'
FEATURE_TEST_TEMPLATE='$FEATURE_TEST_TEMPLATE'
FEATURE_MODULE_TEST_TEMPLATE='$FEATURE_MODULE_TEST_TEMPLATE'

render_template() {
  template="\$1"
  token="\$2"
  value="\$3"
  printf '%s' "\$template" | awk -v t="\$token" -v v="\$value" '{gsub(t, v); print}'
}

echo "[run-feature] ============================================"
echo "[run-feature] Running feature tests"
echo "[run-feature] ============================================"

CMD="\$TEST_CMD"

if [ -n "\$FEATURE_ID" ] && [ -n "\$FEATURE_TEST_TEMPLATE" ]; then
  CMD=\$(render_template "\$FEATURE_TEST_TEMPLATE" '__FEATURE_ID__' "\$FEATURE_ID")
fi

if [ -n "\$FEATURE_ID" ] && [ -n "\$FEATURE_MODULE_TEST_TEMPLATE" ] && [ -f "\$SCRIPT_DIR/../features/\$FEATURE_ID/feature.md" ]; then
  FEATURE_MODULE=\$(grep -E '^module:' "\$SCRIPT_DIR/../features/\$FEATURE_ID/feature.md" 2>/dev/null | head -1 | sed -E 's/^module:[[:space:]]*//')
  if [ -n "\$FEATURE_MODULE" ]; then
    CMD=\$(render_template "\$FEATURE_MODULE_TEST_TEMPLATE" '__FEATURE_MODULE__' "\$FEATURE_MODULE")
  fi
fi

if [ -z "\$CMD" ]; then
  echo "[run-feature] No test command detected for stack '$STACK'."
  exit 0
fi

echo "[run-feature] Running: \$CMD"
if (cd "\$PROJECT_ROOT" && sh -c "\$CMD"); then
  echo "[run-feature] ✓ Feature tests passed"
else
  echo "[run-feature] ✗ Feature tests failed"
  exit 1
fi
EOF_FEATURE

write_script "$ARCH_PATH" <<EOF_ARCH
#!/usr/bin/env sh
set -eu

# Generated by SDLC Harness Generator. Do not edit manually.
# stack: $STACK

SCRIPT_DIR="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
PROJECT_ROOT="\$(cd "\$SCRIPT_DIR/../.." && pwd)"
ARCH_CMD='$ARCH_CMD'
ARCH_SOFT_FAIL='$ARCH_SOFT_FAIL'

echo "[arch-tests] ============================================"
echo "[arch-tests] Running architecture validation"
echo "[arch-tests] ============================================"

if [ -z "\$ARCH_CMD" ]; then
  echo "[arch-tests] No architecture command detected. Skipping."
  exit 0
fi

echo "[arch-tests] Running: \$ARCH_CMD"
if (cd "\$PROJECT_ROOT" && sh -c "\$ARCH_CMD"); then
  echo "[arch-tests] ✓ Architecture checks passed"
  exit 0
fi

if [ "\$ARCH_SOFT_FAIL" = "true" ]; then
  echo "[arch-tests] ⚠ Architecture command failed, but this check is configured as soft-fail for current project signals"
  exit 0
fi

echo "[arch-tests] ✗ Architecture checks failed"
exit 1
EOF_ARCH

write_script "$QUALITY_PATH" <<EOF_QUALITY
#!/usr/bin/env sh
set -eu

# Generated by SDLC Harness Generator. Do not edit manually.
# stack: $STACK

SCRIPT_DIR="\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd)"
PROJECT_ROOT="\$(cd "\$SCRIPT_DIR/../.." && pwd)"
TEST_CMD='$TEST_CMD'
LINT_CMD='$LINT_CMD'
COVERAGE_CMD='$COVERAGE_CMD'
SECURITY_CMD='$SECURITY_CMD'

WARNINGS=0
FAILURES=0

run_phase() {
  phase="\$1"
  cmd="\$2"
  mode="\$3" # hard|soft

  if [ -z "\$cmd" ]; then
    echo "[quality-gates] [\$phase] SKIP (not configured)"
    return 0
  fi

  echo "[quality-gates] [\$phase] Running: \$cmd"
  if (cd "\$PROJECT_ROOT" && sh -c "\$cmd"); then
    echo "[quality-gates] [\$phase] PASS"
    return 0
  fi

  if [ "\$mode" = "soft" ]; then
    WARNINGS=\$((WARNINGS + 1))
    echo "[quality-gates] [\$phase] WARN (soft-fail)"
    return 0
  fi

  FAILURES=\$((FAILURES + 1))
  echo "[quality-gates] [\$phase] FAIL"
  return 1
}

echo "[quality-gates] ============================================"
echo "[quality-gates] Running quality gates"
echo "[quality-gates] ============================================"

run_phase test "\$TEST_CMD" hard || true
run_phase lint "\$LINT_CMD" hard || true

if "\$SCRIPT_DIR/run-arch-tests.sh"; then
  echo "[quality-gates] [arch] PASS"
else
  FAILURES=\$((FAILURES + 1))
  echo "[quality-gates] [arch] FAIL"
fi

run_phase coverage "\$COVERAGE_CMD" soft || true
run_phase security "\$SECURITY_CMD" soft || true

if [ -x "\$SCRIPT_DIR/collect-metrics.sh" ]; then
  if "\$SCRIPT_DIR/collect-metrics.sh"; then
    echo "[quality-gates] [metrics-collect] PASS"
  else
    WARNINGS=\$((WARNINGS + 1))
    echo "[quality-gates] [metrics-collect] WARN"
  fi
fi

if [ -x "\$SCRIPT_DIR/compare-metrics.sh" ]; then
  if "\$SCRIPT_DIR/compare-metrics.sh"; then
    echo "[quality-gates] [metrics-compare] PASS"
  else
    rc=\$?
    if [ "\$rc" -eq 1 ]; then
      WARNINGS=\$((WARNINGS + 1))
      echo "[quality-gates] [metrics-compare] WARN"
    else
      FAILURES=\$((FAILURES + 1))
      echo "[quality-gates] [metrics-compare] FAIL"
    fi
  fi
fi

if [ -x "\$SCRIPT_DIR/archive-metrics.sh" ]; then
  "\$SCRIPT_DIR/archive-metrics.sh" || true
fi

echo ""
echo "[quality-gates] ============================================"
if [ "\$FAILURES" -gt 0 ]; then
  echo "[quality-gates] ✗ FAILED: \$FAILURES failing phase(s), \$WARNINGS warning(s)"
  exit 1
fi
if [ "\$WARNINGS" -gt 0 ]; then
  echo "[quality-gates] ⚠ PASSED WITH WARNINGS: \$WARNINGS warning phase(s)"
  exit 0
fi

echo "[quality-gates] ✓ PASSED: all configured phases succeeded"
EOF_QUALITY

echo "[harness-generator] ============================================"
echo "[harness-generator] Generated scripts in: $TARGET_DIR"
echo "[harness-generator] stack=$STACK build_system=$BUILD_SYSTEM"
echo "[harness-generator] - init-project.sh"
echo "[harness-generator] - run-feature.sh"
echo "[harness-generator] - run-arch-tests.sh"
echo "[harness-generator] - run-quality-gates.sh"
echo "[harness-generator] ============================================"
