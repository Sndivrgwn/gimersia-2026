#!/usr/bin/env bash
# Mission 10 (T4): twin bash dari tools/run_tests.ps1. Timeout keras 120 s.
set -u
DIR="${DIR:-res://tests/unit,res://tests/integration}"
TEST="${TEST:-}"
TIMEOUT="${TIMEOUT:-120}"
GODOT_BIN="${GODOT:-D:/Programming/Gamedev/Godot_v4.7.2-stable_win64_console.exe}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$(mktemp -t gimersia_gut_XXXXXX.log)"

args=(--headless --path "$REPO" -s res://addons/gut/gut_cmdln.gd -gexit -glog=1)
if [ -n "$TEST" ]; then
  args+=(-gtest "$TEST")
else
  IFS=',' read -ra dirs <<< "$DIR"
  for d in "${dirs[@]}"; do [ -n "$d" ] && args+=(-gdir "$d"); done
fi

start=$(date +%s)
timeout "$TIMEOUT" "$GODOT_BIN" "${args[@]}" > "$OUT" 2>&1
code=$?
end=$(date +%s)

if [ "$code" -eq 124 ]; then
  echo "TIMEOUT after ${TIMEOUT} s - cut off"
  rm -f "$OUT"
  exit 124
fi

echo "elapsed: $((end-start)) s"
tail -30 "$OUT"
echo "--- summary ---"
grep -E "Tests |Passing Tests|Failing Tests|Risky|Pending|Asserts|All tests passed|FAILED" "$OUT" | sed 's/^[[:space:]]*//'
if grep -q "All tests passed" "$OUT"; then rm -f "$OUT"; exit 0; fi
rm -f "$OUT"
exit 1
