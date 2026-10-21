"""Парсер Olcha.uz — публичный JSON-API mobile.olcha.uz (без авторизации).

Настоящий ритейлер: старая/новая цена и процент скидки. Товары со скидкой
фильтруем по discount_value > 0 / sale == 1.
"""
from __future__ import annotations

import json
import ssl
import urllib.request

from .base import Deal, categorize

# sale=1 — только товары со скидкой (все 14/страница со снижением цены).
API = "https://mobile.olcha.uz/api/v2/products?page={}&sale=1"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
PAGES = 50


def _ctx() -> ssl.SSLContext:
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:  # noqa: BLE001
        return ssl.create_default_context()


_CTX = _ctx()


def _num(v):
    """Цены у Olcha могут приходить строками/числами — приводим к int."""
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return int(v)
    import re as _re
    digits = _re.sub(r"\D", "", str(v))
    return int(digits) if digits else None


def _fetch(page: int) -> list[dict]:
    req = urllib.request.Request(
        API.format(page),
        headers={"User-Agent": UA, "Accept": "application/json", "Accept-Language": "ru"})
    with urllib.request.urlopen(req, timeout=20, context=_CTX) as r:
        data = json.loads(r.read().decode("utf-8"))
    return ((data.get("data") or {}).get("products")) or []


def parse() -> list[Deal]:
    deals: list[Deal] = []
    seen: set[str] = set()
    for page in range(1, PAGES + 1):
        try:
            products = _fetch(page)
        except Exception as e:  # noqa: BLE001
            print(f"  ! Olcha page {page} failed: {e}")
            continue
        if not products:
            break
        for p in products:
            new_price = _num(p.get("total_price")) or _num(p.get("discount_price"))
            old_price = _num(p.get("max_price"))
            if not new_price:
                continue
            # Процент считаем из цен (поле discount_value приходит в странных единицах).
            if not (old_price and old_price > new_price):
                continue
            pct = round((old_price - new_price) / old_price * 100)
            if pct < 3 or pct > 95:
                continue

            pid = str(p.get("id") or p.get("alias") or "")
            if not pid or pid in seen:
                continue
            seen.add(pid)

            title = p.get("name_ru") or p.get("name_uz") or p.get("name_en") or ""
            cat = p.get("category") or {}
            cat_name = cat.get("name_ru") or ""
            alias = p.get("alias") or ""

            deals.append(Deal(
                id=f"olcha-{pid}",
                title=title.strip(),
                store="Olcha",
                source="olcha",
                category=categorize(f"{title} {cat_name}"),
                new_price=int(new_price),
                currency="UZS",
                old_price=int(old_price) if old_price else None,
                discount_percent=pct,
                city="Ташкент",
                address="",
                image_url=p.get("main_image") or "",
                url=f"https://olcha.uz/ru/product/{alias}" if alias else "",
                seller="Olcha",
            ))
    return deals


if __name__ == "__main__":
    ds = parse()
    print(f"Olcha: {len(ds)} deals")
    for d in ds[:5]:
        print(f"  -{d.discount_percent}% {d.new_price} (было {d.old_price}) | {d.title[:45]}")
