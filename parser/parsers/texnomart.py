"""Парсер Texnomart — gateway.texnomart.uz (без авторизации).

Настоящие скидки дня: web/v1/home/products-of-day (old_price > sale_price).
"""
from __future__ import annotations

import json
import ssl
import urllib.request

from .base import Deal, categorize

ENDPOINTS = [
    "https://gateway.texnomart.uz/api/web/v1/home/products-of-day",
    "https://gateway.texnomart.uz/api/web/v1/product/salemonth",
]
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def _ctx() -> ssl.SSLContext:
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:  # noqa: BLE001
        return ssl.create_default_context()


_CTX = _ctx()


def _fetch(url: str) -> list[dict]:
    req = urllib.request.Request(url, headers={
        "User-Agent": UA, "Accept": "application/json",
        "Accept-Region": "2", "Accept-Device": "web", "Accept-Language": "ru"})
    with urllib.request.urlopen(req, timeout=20, context=_CTX) as r:
        data = json.loads(r.read().decode("utf-8"))
    d = data.get("data") or {}
    # products-of-day: data.data[]; salemonth: data.products[] или data.data[]
    for key in ("data", "products", "items"):
        v = d.get(key)
        if isinstance(v, list):
            return v
    return []


def parse() -> list[Deal]:
    deals: list[Deal] = []
    seen: set[str] = set()
    for url in ENDPOINTS:
        try:
            products = _fetch(url)
        except Exception as e:  # noqa: BLE001
            print(f"  ! Texnomart {url.split('/')[-1]} failed: {e}")
            continue
        for p in products:
            old = p.get("old_price") or 0
            new = p.get("sale_price") or p.get("price") or 0
            if not new or not old or old <= new:
                continue
            pct = round((old - new) / old * 100)
            if pct < 3:
                continue
            pid = str(p.get("id") or "")
            if not pid or pid in seen:
                continue
            seen.add(pid)
            title = (p.get("name") or "").strip()
            deals.append(Deal(
                id=f"texnomart-{pid}",
                title=title,
                store="Texnomart",
                source="texnomart",
                category=categorize(title) if categorize(title) != "other" else "electronics",
                new_price=int(new),
                currency="UZS",
                old_price=int(old),
                discount_percent=pct,
                city="Ташкент",
                image_url=p.get("image") or "",
                url=f"https://texnomart.uz/product/detail/{pid}/",
                seller="Texnomart",
            ))
    return deals


if __name__ == "__main__":
    ds = parse()
    print(f"Texnomart: {len(ds)} deals")
    for d in ds[:5]:
        print(f"  -{d.discount_percent}% {d.new_price} (было {d.old_price}) | {d.title[:45]}")
