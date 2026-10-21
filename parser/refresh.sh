#!/bin/bash
# Автообновление скидок: запуск парсера + пуш в GitHub. Вызывается launchd каждые 2 ч.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
LOG=/tmp/chegirmalar_parser.log
REPO=/Users/zakir.fayrushin/discounts_app

cd "$REPO" || exit 1
echo "=== $(date) запуск парсера ===" >> "$LOG"
/usr/bin/python3 parser/run.py >> "$LOG" 2>&1

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
