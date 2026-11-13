#!/usr/bin/env bash
# progress.sh — đếm checkbox trong repo, xem còn gì chưa làm
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

count_file() {
  local f="$1"
  [[ -f "$f" ]] || { echo "0 0"; return; }
  local done total
  done=$(grep -cE '^- \[[xX]\]|[|][[:space:]]*\[[xX]\][[:space:]]*[|]' "$f" 2>/dev/null || true)
  total=$(grep -cE '^- \[[ xX]\]|[|][[:space:]]*\[[ xX]\][[:space:]]*[|]' "$f" 2>/dev/null || true)
  echo "${done:-0} ${total:-0}"
}

echo "================ AZ-104 PROGRESS ================"
TOTAL_DONE=0; TOTAL_ALL=0
for f in README.md PLAN.md progress/tracker.md; do
  read -r d t <<< "$(count_file "$f")"
  TOTAL_DONE=$((TOTAL_DONE + d)); TOTAL_ALL=$((TOTAL_ALL + t))
  if [[ $t -gt 0 ]]; then
    pct=$(( d * 100 / t ))
    printf "%-26s %3d/%-3d  %3d%%\n" "$f" "$d" "$t" "$pct"
  fi
done

if [[ $TOTAL_ALL -gt 0 ]]; then
  pct=$(( TOTAL_DONE * 100 / TOTAL_ALL ))
  echo "-------------------------------------------------"
  printf "%-26s %3d/%-3d  %3d%%\n" "TỔNG" "$TOTAL_DONE" "$TOTAL_ALL" "$pct"
fi

echo
echo "---------------- Theo ngày (PLAN.md) -------------"
awk '
  /^## / {
    if (day != "") printf "%-48s %2d/%-2d\n", substr(day,4), done, total
    day=$0; done=0; total=0; next
  }
  /^- \[[xX]\]/ { done++; total++; next }
  /^- \[ \]/    { total++ }
  END { if (day != "") printf "%-48s %2d/%-2d\n", substr(day,4), done, total }
' PLAN.md

echo
echo "---------------- Sổ lỗi (wrong-answers.md) -------"
OPEN=$(grep -c '| open |' progress/wrong-answers.md 2>/dev/null || true)
RESOLVED=$(grep -c '| resolved |' progress/wrong-answers.md 2>/dev/null || true)
printf "  open: %s   resolved: %s\n" "${OPEN:-0}" "${RESOLVED:-0}"
echo "  Mục tiêu ngày 14: còn < 20 open"

echo
echo "Ngày thi: 28/11/2026. Còn $(($(date -d 2026-11-28 +%s) - $(date +%s) > 0 ? ($(date -d 2026-11-28 +%s) - $(date +%s)) / 86400 : 0)) ngày."
