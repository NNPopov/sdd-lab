#!/usr/bin/env bash
# Architecture + style gate for flutter_application_1.
# Enforces:
#   1. dart format (no drift)
#   2. dart analyze (no issues)
#   3. dart_code_linter metrics (complexity, parameters, nesting, SLOC)
#   4. Architectural import boundaries (grep-based, zero extra deps)
#
# Exit code: 0 = clean, non-zero = at least one violation found.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILED=0
PKG="flutter_application_1"

# ──────────────────────────────────────────────────────────────
pass() { echo "  ✓  $*"; }
fail() { echo "  ✗  $*"; FAILED=1; }

section() {
  echo ""
  echo "════════════════════════════════════════"
  echo "  $*"
  echo "════════════════════════════════════════"
}

boundary_check() {
  local label="$1"; local glob="$2"; local pattern="$3"
  local hits
  hits=$(grep -rn --include="*.dart" -E "$pattern" $glob 2>/dev/null \
        | grep -v -E '\.(g|freezed|gr|config)\.dart' || true)
  if [ -n "$hits" ]; then
    fail "$label"
    echo "$hits" | sed 's/^/      /'
  else
    pass "$label"
  fi
}

# ── 1. Format ─────────────────────────────────────────────────
section "1/4  dart format (dry-run)"
if ! dart format --set-exit-if-changed lib/ test/ 2>&1; then
  fail "Formatting violations. Run: dart format lib/ test/"
else
  pass "Format OK"
fi

# ── 2. Analyzer ───────────────────────────────────────────────
section "2/4  dart analyze"
if ! dart analyze lib/ 2>&1; then
  fail "Analyzer violations found."
else
  pass "Analyzer OK"
fi

# ── 3. Metrics ────────────────────────────────────────────────
section "3/4  dart_code_linter metrics"
if ! dart run dart_code_linter:metrics analyze lib/ \
      --cyclomatic-complexity=10 \
      --number-of-parameters=5 \
      --maximum-nesting-level=5 \
      --source-lines-of-code=50 \
      --reporter=console \
      --no-congratulate 2>&1; then
  fail "Metrics violations found."
else
  pass "Metrics OK"
fi

# ── 4. Architectural boundaries ───────────────────────────────
section "4/4  Architectural import boundaries"

# 4a. domain/ must be pure Dart — no Flutter, Dio, or infra packages
boundary_check \
  "domain/ imports package:flutter" \
  "lib/**/domain" \
  "import 'package:flutter/"

boundary_check \
  "domain/ imports package:dio" \
  "lib/**/domain" \
  "import 'package:(dio|retrofit)/"

boundary_check \
  "domain/ imports infra packages (hive, secure_storage, get_it, injectable)" \
  "lib/**/domain" \
  "import 'package:(hive|flutter_secure_storage|get_it|injectable)/"

# 4b. presentation/ must not call HTTP directly
boundary_check \
  "presentation/ imports package:dio or retrofit" \
  "lib/**/presentation" \
  "import 'package:(dio|retrofit)/"

# 4c. core/ must not know about features/
# Exception: core/routing/app_router.dart is the composition root for routes
# and necessarily imports all feature route files. Exclude it from this check.
CORE_IMPORTS_FEATURES=$(
  grep -rn --include="*.dart" \
    "import 'package:${PKG}/features/" lib/core/ 2>/dev/null \
  | grep -v "\.\(g\|freezed\|gr\|config\)\.dart" \
  | grep -v "lib/core/routing/app_router\.dart" || true
)
if [ -n "$CORE_IMPORTS_FEATURES" ]; then
  fail "core/ imports features/ (excluding app_router.dart composition root)"
  echo "$CORE_IMPORTS_FEATURES" | sed 's/^/      /'
else
  pass "core/ isolation (app_router.dart excluded as composition root)"
fi

# 4d. Feature isolation — posts
boundary_check \
  "posts/ imports tiers or users feature" \
  "lib/features/posts" \
  "import 'package:${PKG}/features/(tiers|users)/"

# 4e. Feature isolation — tiers
boundary_check \
  "tiers/ imports posts or users feature" \
  "lib/features/tiers" \
  "import 'package:${PKG}/features/(posts|users)/"

# 4f. Feature isolation — users
boundary_check \
  "users/ imports posts or tiers feature" \
  "lib/features/users" \
  "import 'package:${PKG}/features/(posts|tiers)/"

# 4g. No setState in widgets that already have a Cubit/Bloc dependency
CUBIT_WITH_SETSTATE=$(
  grep -rln --include="*.dart" "setState" lib/features/ lib/core/ 2>/dev/null \
  | xargs grep -l "Cubit\|BlocProvider\|BlocConsumer\|BlocListener\|BlocBuilder" 2>/dev/null \
  | grep -v -E '\.(g|freezed|gr|config)\.dart' || true
)
if [ -n "$CUBIT_WITH_SETSTATE" ]; then
  fail "setState used in widget that already uses Cubit/Bloc:"
  echo "$CUBIT_WITH_SETSTATE" | sed 's/^/      /'
else
  pass "No setState+Cubit mixing"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "✅  All checks passed."
else
  echo "❌  One or more checks failed. See output above."
fi

exit "$FAILED"
