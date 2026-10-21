# Вход через Telegram — бэкенд на Deno Deploy (бесплатно)

Один файл `main.ts` обслуживает вход: `/auth/start`, `/auth/status`, webhook бота `/tg-webhook`.
Хранилище — встроенное Deno KV. Публичный URL — бесплатно.

## Деплой (10 минут)

1. Зайдите на **https://dash.deno.com** → войдите через GitHub.
2. **New Project** → **Deploy from GitHub** → выберите репозиторий `chegirma`.
3. Entry point: `backend/deno/main.ts`. Prod branch: `main`.
4. В **Settings → Environment Variables** добавьте:
   - `TG_BOT_TOKEN` = токен бота (@chegirma_login_bot)
   - `SESSION_SECRET` = любая длинная случайная строка
   - `BOT_USERNAME` = `chegirma_login_bot`
5. Deploy. Получите URL вида `https://chegirma-xxxx.deno.dev`.

## Привязать бота к webhook (один запрос)

```bash
curl "https://api.telegram.org/bot<TG_BOT_TOKEN>/setWebhook?url=https://<ВАШ-URL>.deno.dev/tg-webhook"
```

## Включить вход в приложении

Собрать приложение с URL бэкенда:
```bash
flutter build apk --release --dart-define=AUTH_URL=https://<ВАШ-URL>.deno.dev
```
(или вписать URL в `lib/auth.dart` → `kAuthBaseUrl`).

После этого «Войти через Telegram» в профиле открывает бота, пользователь жмёт
«Поделиться номером» — и входит. Бесплатно, без SMS.
