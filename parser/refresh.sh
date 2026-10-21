#!/bin/bash
# Автообновление скидок: запуск парсера + пуш в GitHub. Вызывается launchd каждые 2 ч.
export PATH="$HOME/Library/Python/3.12/bin:$HOME/.local/bin:/Library/Frameworks/Python.framework/Versions/3.12/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
PY=/Library/Frameworks/Python.framework/Versions/3.12/bin/python3
[ -x "$PY" ] || PY=python3
LOG=/tmp/chegirmalar_parser.log
REPO=/Users/zakir.fayrushin/discounts_app

cd "$REPO" || exit 1
echo "=== $(date) запуск парсера ===" >> "$LOG"
"$PY" parser/run.py >> "$LOG" 2>&1

git add docs/deals.json
if git diff --staged --quiet; then
  echo "$(date) изменений нет" >> "$LOG"
else
  git commit -q -m "data: автообновление скидок [skip ci]" >> "$LOG" 2>&1
  TOKEN=$(gh auth token 2>/dev/null)
  if [ -n "$TOKEN" ]; then
    git push -q "https://x-access-token:${TOKEN}@github.com/fayrushinzakir-lab/chegirma.git" main >> "$LOG" 2>&1
    echo "$(date) запушено" >> "$LOG"
  else
    git push -q origin main >> "$LOG" 2>&1
  fi
fi
