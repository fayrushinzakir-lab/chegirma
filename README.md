# Chegirma — агрегатор скидок для Узбекистана

Мобильное приложение (Flutter), которое само собирает актуальные скидки и акции
по всему Узбекистану — от продуктов до стройматериалов — и показывает их в одной
ленте. Чёрная матовая тема.

## Как это устроено (бесплатно, без своего сервера)

```
GitHub Actions (cron каждые 2 ч)
   └── parser/run.py  →  парсеры источников  →  нормализация + дедуп
                                                     │
                                                     ▼
                                         docs/deals.json  (в репозитории)
                                                     │  raw.githubusercontent.com
                                                     ▼
                                    Flutter-приложение (реальные данные, кэш офлайн)
```

GitHub Actions = бесплатный планировщик и раннеры. Приложение читает `docs/deals.json`
напрямую по raw-ссылке — отдельный сервер не нужен.

## Источники

| Источник | Статус | Данные |
|----------|--------|--------|
| OLX.uz | ✅ работает | публичный JSON-API; скидка извлекается из текста объявления |
| Texnomart / Olcha / Korzinka | 🔜 план | ритейлеры со старой/новой ценой |
| Telegram-каналы | 🔜 нужны `api_id`/`api_hash` | основной источник акций в Уз |
| Instagram | ⛔ исключён | против ToS, высокий риск бана |

## Структура

```
lib/                     Flutter-приложение (экраны, тема, виджеты)
parser/
  parsers/base.py        Deal + нормализация, извлечение скидки, категоризация, дедуп
  parsers/olx.py         парсер OLX.uz (реальный)
  run.py                 оркестратор → docs/deals.json
  requirements.txt
.github/workflows/parse.yml   расписание сборки
docs/deals.json          публикуемые данные (обновляет бот)
docs/superpowers/specs/  дизайн-документ
```

## Запуск

Парсер локально:
```bash
python3 parser/run.py        # пишет docs/deals.json
```

Приложение на подключённом Android:
```bash
export PATH="$HOME/development/flutter/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
