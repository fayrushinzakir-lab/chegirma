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
from parsers import olx, olcha, texnomart, asaxiy, uzum  # noqa: E402

# Активные источники. Новый парсер = добавить сюда функцию .parse().
SOURCES = [
    ("OLX.uz", olx.parse),
    ("Olcha.uz", olcha.parse),
    ("Texnomart", texnomart.parse),
    ("Asaxiy.uz", asaxiy.parse),
    ("Uzum Market", uzum.parse),  # headless-браузер (Playwright) — только локально
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

    # фильтр качества: валидная цена, есть фото, не истёкшие, не абсурд
    def _ok(d: Deal) -> bool:
        if not d.new_price or d.new_price < 1000:
            return False
        if not d.image_url:
            return False
        if _is_expired(d, now):
            return False
        pct = d.discount_percent
        if pct is not None and (pct < 3 or pct > 95):
            return False
        # абсурдная старая цена
        if d.old_price and d.new_price and (d.old_price <= d.new_price or d.old_price > d.new_price * 15):
            return False
        return True

    all_deals = [d for d in all_deals if _ok(d)]
    all_deals = dedupe(all_deals)

    # сортировка по качеству (как в приложении): настоящая скидка с фото — вперёд
    def _quality(d: Deal) -> int:
        s = 0
        if d.old_price and d.discount_percent:
            s += 200 + d.discount_percent
        elif d.discount_percent:
            s += 100 + d.discount_percent
        if d.source != "olx":
            s += 40
        if d.category == "other":
            s -= 70
        return s

    all_deals.sort(key=_quality, reverse=True)

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
