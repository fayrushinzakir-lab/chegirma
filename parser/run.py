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
HIST = os.path.join(os.path.dirname(__file__), "..", "docs", "price_history.json")


def _apply_price_history(deals: list[Deal], now: datetime) -> None:
    """Копит историю цен по товару и ставит вердикт «честная скидка».

    Фейк = заявленная старая цена заметно выше всего, что реально наблюдали.
    Пока наблюдений мало — вердикт None (история копится).
    """
    try:
        hist = json.load(open(HIST, encoding="utf-8")) if os.path.exists(HIST) else {}
    except Exception:  # noqa: BLE001
        hist = {}
    ts = now.strftime("%Y-%m-%dT%H:%M")
    for d in deals:
        if not d.new_price:
            continue
        rec = hist.get(d.id) or []
        rec.append([ts, d.new_price])   # одно наблюдение на прогон (каждые ~2ч)
        rec = rec[-10:]
        hist[d.id] = rec
        prices = [p for _, p in rec]
        d.price_history = prices
        if len(prices) >= 3:
            observed_max = max(prices)
            d.fair = not (d.old_price and d.old_price > observed_max * 1.25)
        else:
            d.fair = None  # ещё копим
    # прунинг: не виденные 14 дней — выкидываем (ограничение роста файла)
    cutoff = (now - timedelta(days=14)).strftime("%Y-%m-%d")
    hist = {k: v for k, v in hist.items() if v and v[-1][0] >= cutoff}
    try:
        json.dump(hist, open(HIST, "w", encoding="utf-8"), ensure_ascii=False)
    except Exception:  # noqa: BLE001
        pass


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

    # история цен + вердикт «честная скидка»
    _apply_price_history(all_deals, now)

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
