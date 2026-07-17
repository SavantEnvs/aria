#!/usr/bin/env bash
#
# mayhem/test.sh — behavioral oracle for the aria interpreter.
#
# Upstream ships no assertion-based test suite; the oracle runs the interpreter
# (built by mayhem/build.sh as /mayhem/aria-oracle, normal flags) over the five
# demo programs upstream ships in script/ plus two authored known-answer programs
# in mayhem/tests/, and diffs each program's full stdout against a committed
# golden output. Every case asserts concrete computed values (fib 20 = 6765,
# Game-of-Life grids, mandelbrot rendering, list/string/arith/macro/pcall
# results), so a patch that neuters the interpreter fails the diff.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

ORACLE=/mayhem/aria-oracle
if [ ! -x "$ORACLE" ]; then
  echo "FATAL: $ORACLE missing — mayhem/build.sh must build it first" >&2
  emit_ctrf aria-golden 0 1
  exit 1
fi

passed=0
failed=0

run_case() {
  local name="$1" prog="$2"
  local golden="$SRC/mayhem/tests/expected/$name.out"
  local out=/tmp/aria-test-"$name".out
  if timeout 60 "$ORACLE" "$prog" > "$out" 2>&1 && diff -u "$golden" "$out" > /tmp/aria-test-"$name".diff 2>&1; then
    echo "PASS $name"
    passed=$(( passed + 1 ))
  else
    echo "FAIL $name"
    cat /tmp/aria-test-"$name".diff 2>/dev/null | head -40
    failed=$(( failed + 1 ))
  fi
}

run_case fib        script/fib.lsp
run_case hello      script/hello.lsp
run_case titleize   script/titleize.lsp
run_case mandelbrot script/mandelbrot.lsp
run_case life       script/life.lsp
run_case core       mayhem/tests/core.lsp
run_case control    mayhem/tests/control.lsp

emit_ctrf aria-golden "$passed" "$failed"
