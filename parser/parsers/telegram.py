"""Парсер публичных Telegram-каналов через веб-превью t.me/s/<канал>.

БЕЗ api_id/api_hash — читаем HTML публичной ленты канала. Берём посты,
в которых есть сигнал скидки (процент / было-стало). Фото — из поста.
"""
from __future__ import annotations

import html
import re
import ssl
import urllib.request

from .base import Deal, extract_discount, categorize

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

# Публичные каналы магазинов и агрегаторов скидок РУз. Мёртвые → 0 постов (ок).
CHANNELS = [
    ("korzinkauz", "Korzinka"),
    ("texnomart_official", "Texnomart"),
    ("skidki_tashkent", "Skidki Tashkent"),
    ("aksiya_uz", "Aksiya UZ"),
    ("chegirmalar_uzb", "Chegirmalar"),
    ("mediapark_uz", "Mediapark"),
    ("idea_electronics", "Idea"),
    ("havas_market", "Havas"),
    ("makro_supermarket", "Makro"),
    ("uzum_market", "Uzum Market"),
    ("asaxiy_books", "Asaxiy"),
    ("olcha_uz", "Olcha"),
    ("elmakon_uz", "Elmakon"),
    ("sales_uzbekistan", "Sales UZ"),
    ("aksiya_skidka_uz", "Aksiya Skidka"),
]

_MSG = re.compile(r'tgme_widget_message_text[^>]*>(.*?)</div>', re.S)
_PHOTO = re.compile(r"background-image:url\('([^']+)'\)")
_LINK = re.compile(r'tgme_widget_message_date[^>]*href="([^"]+)"')
_KW = re.compile(r'скидк|chegirm|chegarm|aksiy|акци|распродаж|sale|arzon|-\d{1,2}\s*%|\d{1,2}\s*%', re.I)
_PRICE = re.compile(r'(\d[\d\s. ]{3,12}\d)\s*(?:сум|so\'?m|som|uzs)', re.I)


def _ctx() -> ssl.SSLContext:
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:  # noqa: BLE001
        return ssl.create_default_context()


_CTX = _ctx()


def _clean(raw: str) -> str:
    raw = re.sub(r'<br\s*/?>', '\n', raw)
    raw = re.sub(r'<[^>]+>', '', raw)
    raw = html.unescape(raw)
    raw = re.sub(r'https?://\S+', '', raw)       # ссылки убираем
    raw = re.sub(r'@\w+', '', raw)               # @упоминания
    raw = re.sub(r'[ \t]+', ' ', raw)
    return raw.strip()


def _title(text: str) -> str:
    for line in text.split('\n'):
        line = line.strip(' *•—-').strip()
        if len(line) >= 8:
            return line[:90]
    return text[:90]


def _fetch(channel: str) -> str:
    req = urllib.request.Request(f"https://t.me/s/{channel}", headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=20, context=_CTX) as r:
        return r.read().decode("utf-8", "ignore")


def _price(text: str):
    best = None
    for m in _PRICE.finditer(text):
        digits = re.sub(r'\D', '', m.group(1))
        if digits:
            v = int(digits)
            if 1000 <= v <= 500_000_000 and (best is None or v > best):
                best = v
    return best


def parse() -> list[Deal]:
    deals: list[Deal] = []
    seen: set[str] = set()
    for handle, store in CHANNELS:
        try:
            page = _fetch(handle)
        except Exception as e:  # noqa: BLE001
            print(f"  ! TG {handle} failed: {e}")
            continue
        # каждый пост начинается с message_bubble
        chunks = page.split('tgme_widget_message_bubble')[1:]
        for b in chunks:
            mt = _MSG.search(b)
            if not mt:
                continue
            text = _clean(mt.group(1))
            if len(text) < 12 or not _KW.search(text):
                continue
            old, new, pct = extract_discount(text, None)
            price = _price(text)
            new_price = new or price
            # нужен хоть какой-то ценовой/процентный сигнал
            if not pct and not new_price:
                continue
            link_m = _LINK.search(b)
            link = link_m.group(1) if link_m else f"https://t.me/{handle}"
            if link in seen:
                continue
            seen.add(link)
            photo_m = _PHOTO.search(b)
            if pct and new_price and not old:
                old = round(new_price / (1 - pct / 100))
            deals.append(Deal(
                id=f"tg-{handle}-{link.rsplit('/', 1)[-1]}",
                title=_title(text),
                store=store,
                source="telegram",
                category=categorize(text),
                new_price=new_price,
                currency="UZS",
                old_price=old,
                discount_percent=pct,
                city="",
                image_url=photo_m.group(1) if photo_m else "",
                url=link,
                seller=store,
            ))
    return deals


if __name__ == "__main__":
    ds = parse()
    print(f"Telegram: {len(ds)} deals")
    for d in ds[:8]:
        print(f"  -{d.discount_percent}% | {d.store} | {d.title[:50]}")
