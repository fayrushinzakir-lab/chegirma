"""Парсер OLX.uz — реальный публичный JSON-API.

OLX отдаёт объявления (в т.ч. с пометкой «акция/chegirma»). Пары
старая/новая цена в API нет, поэтому скидку извлекаем из текста
(base.extract_discount). Где скидки нет — показываем цену с бейджем «Акция».
"""
from __future__ import annotations

import json
import ssl
import urllib.parse
import urllib.request

from .base import Deal, extract_discount, categorize

API = "https://www.olx.uz/api/v1/offers/"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def _ssl_context() -> ssl.SSLContext:
    """Проверенные сертификаты через certifi; иначе — системные.

    На Ubuntu (GitHub Actions) системные сертификаты работают из коробки;
    на macOS-сборке python.org их нет, поэтому берём certifi.
    """
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:  # noqa: BLE001
        return ssl.create_default_context()


_CTX = _ssl_context()

# Запросы по категориям — так лента получается разнообразной и релевантной.
QUERIES = [
    "chegirma", "skidka", "акция", "распродажа",
    "telefon chegirma", "televizor aksiya", "noutbuk chegirma",
    "divan aksiya", "mebel chegirma", "muzlatgich aksiya",
    "kir yuvish mashinasi chegirma", "konditsioner aksiya",
    "cement", "qurilish mollari chegirma", "bo'yoq aksiya",
    "poyabzal chegirma", "kiyim aksiya", "kosmetika chegirma",
    "shina aksiya", "velosiped chegirma",
]


def _fetch(query: str, limit: int = 30) -> list[dict]:
    params = urllib.parse.urlencode({"query": query, "limit": limit, "offset": 0})
    req = urllib.request.Request(
        f"{API}?{params}",
        headers={"User-Agent": UA, "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=20, context=_CTX) as r:
        data = json.loads(r.read().decode("utf-8"))
    return data.get("data", []) or []


def _price(offer: dict):
    for p in offer.get("params", []) or []:
        if p.get("key") == "price":
            val = p.get("value") or {}
            v = val.get("value")
            cur = val.get("currency") or "UZS"
            if isinstance(v, (int, float)) and v > 0:
                return int(v), cur
    return None, "UZS"


def _image(offer: dict) -> str:
    photos = offer.get("photos") or []
    if photos:
        link = photos[0].get("link", "")
        return link.replace("{width}", "600").replace("{height}", "600")
    return ""


def parse() -> list[Deal]:
    seen_ids: set[int] = set()
    deals: list[Deal] = []

    for q in QUERIES:
        try:
            offers = _fetch(q)
        except Exception as e:  # noqa: BLE001 — сетевые сбои не должны валить весь прогон
            print(f"  ! OLX query '{q}' failed: {e}")
            continue

        for o in offers:
            oid = o.get("id")
            if not oid or oid in seen_ids:
                continue
            seen_ids.add(oid)

            price, cur = _price(o)
            if cur not in ("UZS", "сум", "so'm"):
                # для консистентной витрины в сумах пропускаем цены в у.е.
                continue

            title = (o.get("title") or "").strip()
            desc = (o.get("description") or "").strip()
            old, new, pct = extract_discount(f"{title}\n{desc}", price)

            loc = o.get("location") or {}
            city = (loc.get("city") or {}).get("name", "")
            district = (loc.get("district") or {}).get("name", "")

            shop = o.get("shop") or {}
            store = shop.get("name") if isinstance(shop, dict) and shop.get("name") else "OLX"

            deals.append(Deal(
                id=f"olx-{oid}",
                title=title,
                store=store,
                source="olx",
                category=categorize(f"{title} {q}"),
                new_price=new or price,
                currency="UZS",
                old_price=old,
                discount_percent=pct,
                city=city,
                address=district,
                image_url=_image(o),
                url=o.get("url", ""),
                created_at=o.get("created_time", ""),
                ends_at=o.get("valid_to_time", ""),
                promoted=bool((o.get("promotion") or {}).get("highlighted")),
            ))

    return deals


if __name__ == "__main__":
    ds = parse()
    print(f"OLX: {len(ds)} deals")
    for d in ds[:5]:
        print(f"  {d.discount_percent}% | {d.new_price} | {d.title[:50]} | {d.city}")
