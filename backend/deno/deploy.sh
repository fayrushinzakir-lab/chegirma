#!/bin/bash
# Деплой бэкенда входа на Deno Deploy «под ключ» — без дашборда, одной командой.
#
# Что нужно (один раз):
#   1. Токен Deno Deploy: https://dash.deno.com/account#access-tokens → New Access Token
#   2. Токен бота @chegirma_login_bot (от @BotFather)
#
# Запуск:
#   DENO_DEPLOY_TOKEN=xxx TG_BOT_TOKEN=yyy bash backend/deno/deploy.sh
#
# Скрипт: задеплоит main.ts, выставит env-переменные, привяжет webhook бота
# и напечатает стабильный URL + готовую команду сборки приложения.
set -euo pipefail

PROJECT="${DENO_PROJECT:-chegirmalar-auth}"
BOT_USERNAME="${BOT_USERNAME:-chegirma_login_bot}"
DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$HOME/.deno/bin:$PATH"

if [ -z "${DENO_DEPLOY_TOKEN:-}" ]; then
  echo "✗ Нет DENO_DEPLOY_TOKEN. Создайте токен: https://dash.deno.com/account#access-tokens"
  echo "  затем: DENO_DEPLOY_TOKEN=... TG_BOT_TOKEN=... bash backend/deno/deploy.sh"
  exit 1
fi
if [ -z "${TG_BOT_TOKEN:-}" ]; then
  echo "✗ Нет TG_BOT_TOKEN (токен бота от @BotFather)."
  exit 1
fi

# Секрет сессии: берём заданный или генерируем стабильный и сохраняем локально,
# чтобы при повторном деплое сессии пользователей не сбрасывались.
SECRET_FILE="$DIR/.session_secret"
if [ -n "${SESSION_SECRET:-}" ]; then
  echo "$SESSION_SECRET" > "$SECRET_FILE"
elif [ -f "$SECRET_FILE" ]; then
  SESSION_SECRET="$(cat "$SECRET_FILE")"
else
  SESSION_SECRET="$(openssl rand -hex 32)$(openssl rand -hex 32)"
  echo "$SESSION_SECRET" > "$SECRET_FILE"
fi
chmod 600 "$SECRET_FILE" 2>/dev/null || true

echo "→ Деплой проекта '$PROJECT' на Deno Deploy…"
deployctl deploy \
  --project="$PROJECT" \
  --entrypoint="$DIR/main.ts" \
  --token="$DENO_DEPLOY_TOKEN" \
  --prod \
  --env="TG_BOT_TOKEN=$TG_BOT_TOKEN" \
  --env="SESSION_SECRET=$SESSION_SECRET" \
  --env="BOT_USERNAME=$BOT_USERNAME"

URL="https://$PROJECT.deno.dev"
echo "→ Привязываю webhook бота к $URL/tg-webhook …"
curl -fsS "https://api.telegram.org/bot$TG_BOT_TOKEN/setWebhook?url=$URL/tg-webhook" && echo

echo
echo "✅ Готово. Стабильный backend: $URL"
echo "   Проверка:  curl -X POST $URL/auth/start"
echo
echo "Соберите приложение с этим URL (вход заработает навсегда):"
echo "   flutter build apk --release --dart-define=AUTH_URL=$URL"
