"""Парсер OLX.uz — реальный публичный JSON-API.

Собирает: цену, скидку (из текста), фото, город/район, координаты (map.lat/lon),
телефон продавца (limited-phones) и имя продавца. Телефоны тянутся параллельно.
"""
from __future__ import annotations

import json
import ssl
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor

from .base import Deal, extract_discount, categorize

API = "https://www.olx.uz/api/v1/offers/"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def _ssl_context() -> ssl.SSLContext:
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:  # noqa: BLE001
        return ssl.create_default_context()


_CTX = _ssl_context()

QUERIES = [
    "chegirma", "skidka", "акция", "распродажа", "sale",
    "telefon chegirma", "televizor aksiya", "noutbuk chegirma", "planshet aksiya",
    "divan aksiya", "mebel chegirma", "muzlatgich aksiya", "oshxona mebel",
    "kir yuvish mashinasi chegirma", "konditsioner aksiya", "changyutgich",
    "cement", "qurilish mollari chegirma", "bo'yoq aksiya", "kafel chegirma",
    "santexnika aksiya", "smesitel",
    "poyabzal chegirma", "kiyim aksiya", "kurtka chegirma", "krossovka",
    "kosmetika chegirma", "parfum aksiya", "atir",
    "shina aksiya", "akkumulyator",
    "velosiped chegirma", "samokat",
    "mahsulotlar aksiya", "oziq ovqat", "choy qahva",
    "bolalar tovarlari chegirma", "pampers aksiya",
    "bolalar ovqati", "детское питание", "детская смесь nan", "aptechka",
    "ko'ylak chegirma", "sumka aksiya", "palto chegirma", "sport kiyim",
    "restoran aksiya", "kafe chegirma", "pizza aksiya", "dostavka ovqat", "banket to'yxona",
    "mebel divan chegirma", "gaz plita aksiya", "noutbuk aksiya", "monitor chegirma",
]


def _fetch(query: str, limit: int = 30) -> list[dict]:
    params = urllib.parse.urlencode({"query": query, "limit": limit, "offset": 0})
    req = urllib.request.Request(f"{API}?{params}", headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=20, context=_CTX) as r:
        return json.loads(r.read().decode("utf-8")).get("data", []) or []


def _price(offer: dict):
    for p in offer.get("params", []) or []:
        if p.get("key") == "price":
            val = p.get("value") or {}
            v = val.get("value")
            if isinstance(v, (int, float)) and v > 0:
                return int(v), val.get("currency") or "UZS"
    return None, "UZS"


def _image(offer: dict) -> str:
    photos = offer.get("photos") or []
    if photos:
        return photos[0].get("link", "").replace("{width}", "600").replace("{height}", "600")
    return ""


def _fetch_phone(offer_id: str) -> str:
    try:
        req = urllib.request.Request(
            f"{API}{offer_id}/limited-phones/",
            headers={"User-Agent": UA, "Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=12, context=_CTX) as r:
            data = json.loads(r.read().decode("utf-8"))
        phones = (data.get("data") or {}).get("phones") or []
        return phones[0].replace(" ", "") if phones else ""
    except Exception:  # noqa: BLE001
        return ""


def parse() -> list[Deal]:
    seen: set[int] = set()
    raw: list[tuple[int, Deal]] = []

    for q in QUERIES:
        try:
            offers = _fetch(q)
        except Exception as e:  # noqa: BLE001
            print(f"  ! OLX query '{q}' failed: {e}")
            continue
        for o in offers:
            oid = o.get("id")
            if not oid or oid in seen:
                continue
            seen.add(oid)

            price, cur = _price(o)
            if cur not in ("UZS", "сум", "so'm"):
                continue

            title = (o.get("title") or "").strip()
            desc = (o.get("description") or "").strip()
            old, new, pct = extract_discount(f"{title}\n{desc}", price)

            loc = o.get("location") or {}
            city = (loc.get("city") or {}).get("name", "")
            district = (loc.get("district") or {}).get("name", "")
            mp = o.get("map") or {}
            user = o.get("user") or {}
            contact = o.get("contact") or {}

            d = Deal(
                id=f"olx-{oid}",
                title=title,
                store=(o.get("shop") or {}).get("name") or user.get("name") or "OLX",
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
                lat=mp.get("lat"),
                lon=mp.get("lon"),
                seller=user.get("name") or contact.get("name") or "",
            )
            raw.append((oid, d))

    # Телефоны — параллельно (только если продавец их показывает).
    print(f"  тянем телефоны для {len(raw)} объявлений…")
    ids = [oid for oid, _ in raw]
    with ThreadPoolExecutor(max_workers=10) as ex:
        phones = list(ex.map(_fetch_phone, ids))
    for (_, d), ph in zip(raw, phones):
        d.phone = ph

    with_phone = sum(1 for _, d in raw if d.phone)
    print(f"  с телефоном: {with_phone}")
    return [d for _, d in raw]


if __name__ == "__main__":
    ds = parse()
    print(f"OLX: {len(ds)} deals")
