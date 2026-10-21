"""Оркестратор сборщиков Chegirma.

Запускает все парсеры → нормализует → дедуп → пишет docs/deals.json,
который читает мобильное приложение (через raw.githubusercontent.com).
"""
from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone, timedelta

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from parsers.base import Deal, dedupe  # noqa: E402
from parsers import olx, olcha, texnomart, asaxiy  # noqa: E402

# Активные источники. Новый парсер = добавить сюда функцию .parse().
SOURCES = [
    ("OLX.uz", olx.parse),
    ("Olcha.uz", olcha.parse),
    ("Texnomart", texnomart.parse),
    ("Asaxiy.uz", asaxiy.parse),
]

OUT = os.path.join(os.path.dirname(__file__), "..", "docs", "deals.json")


def _is_expired(d: Deal, now: datetime) -> bool:
    if not d.ends_at:
        return False
    try:
        dt = datetime.fromisoformat(d.ends_at.replace("Z", "+00:00"))
        return dt < now
    except ValueError:
        return False


def main() -> int:
    now = datetime.now(timezone.utc)
    all_deals: list[Deal] = []

    for name, fn in SOURCES:
        print(f"→ {name} …")
        try:
            got = fn()
            print(f"  {len(got)} сырых")
            all_deals.extend(got)
        except Exception as e:  # noqa: BLE001
            print(f"  ! источник {name} упал: {e}")

    # фильтр истёкших + с валидной ценой
    all_deals = [d for d in all_deals if d.new_price and not _is_expired(d, now)]
    # дедуп
    all_deals = dedupe(all_deals)
    # сортировка: сначала с известной скидкой (по %), затем свежие
    all_deals.sort(key=lambda d: (d.discount_percent or -1), reverse=True)

    # Защита: если все источники упали (напр. 403 с заблокированного IP),
    # НЕ затираем прошлые хорошие данные нулём — выходим, оставив файл как есть.
    if not all_deals:
        print("\n! 0 скидок — вероятно источник заблокировал IP. "
              "Файл не перезаписан, прошлые данные сохранены.")
        return 1

    payload = {
        "generatedAt": now.isoformat(),
        "count": len(all_deals),
        "sources": [s[0] for s in SOURCES],
        "deals": [d.to_json() for d in all_deals],
    }

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)

    with_pct = sum(1 for d in all_deals if d.discount_percent)
    print(f"\n✓ {len(all_deals)} скидок записано в {os.path.relpath(OUT)}")
    print(f"  из них с явным процентом: {with_pct}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
