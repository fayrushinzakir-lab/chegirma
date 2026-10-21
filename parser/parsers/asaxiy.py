"""Парсер Asaxiy.uz — страница скидок (SSR HTML, без API).

https://asaxiy.uz/discount/product?page=N — только товары со скидкой.
Старая/новая цена, фото, ссылка из HTML-карточек.
"""
from __future__ import annotations

import html
import re
import ssl
import urllib.request

from .base import Deal, categorize

URL = "https://asaxiy.uz/discount/product?page={}"
UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
PAGES = 10

_CARD = re.compile(r'<div class="product__item[ "].*?(?=<div class="product__item[ "]|</section|</main)', re.S)
_ACTUAL = re.compile(r'data-actual-price="(\d+)"')
_HREF = re.compile(r'href="(/product/[^"]+)"')
_TITLE = re.compile(r'product__item__info-title[^>]*>(.*?)</', re.S)
_OLD = re.compile(r'product__item-old--price[^>]*>([^<]*)<')
_IMG = re.compile(r'<img[^>]+src="(https://[^"]+asaxiy[^"]+)"')
_NUM = re.compile(r'\d+')


def _ctx() -> ssl.SSLContext:
    try:
        import certifi
        return ssl.create_default_context(cafile=certifi.where())
    except Exception:  # noqa: BLE001
        return ssl.create_default_context()


_CTX = _ctx()


def _num(s: str):
    digits = re.sub(r"\D", "", s or "")
    return int(digits) if digits else None


def _fetch(page: int) -> str:
    req = urllib.request.Request(URL.format(page), headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=20, context=_CTX) as r:
        return r.read().decode("utf-8", "ignore")


def parse() -> list[Deal]:
    deals: list[Deal] = []
    seen: set[str] = set()
    for page in range(1, PAGES + 1):
        try:
            page_html = _fetch(page)
        except Exception as e:  # noqa: BLE001
            print(f"  ! Asaxiy page {page} failed: {e}")
            continue
        cards = _CARD.findall(page_html)
        if not cards:
            break
        for card in cards:
            m_actual = _ACTUAL.search(card)
            m_href = _HREF.search(card)
            m_title = _TITLE.search(card)
            if not (m_actual and m_href and m_title):
                continue
            new = int(m_actual.group(1))
            old = None
            m_old = _OLD.search(card)
            if m_old:
                old = _num(m_old.group(1))
            # Качество: оставляем только правдоподобную старую цену (реальная скидка).
            if not (old and new < old <= new * 10):
                continue
            pct = round((old - new) / old * 100)
            if new < 1000 or pct < 3 or pct > 90:
                continue

            slug = m_href.group(1)
            if slug in seen:
                continue
            seen.add(slug)
            title = html.unescape(re.sub(r"<[^>]+>", "", m_title.group(1))).strip()
            m_img = _IMG.search(card)

            deals.append(Deal(
                id=f"asaxiy-{slug.rsplit('/', 1)[-1][:40]}",
                title=title,
                store="Asaxiy",
                source="asaxiy",
                category=categorize(title),
                new_price=new,
                currency="UZS",
                old_price=old,
                discount_percent=pct,
                city="Ташкент",
                image_url=m_img.group(1) if m_img else "",
                url=f"https://asaxiy.uz{slug}",
                seller="Asaxiy",
            ))
    return deals


if __name__ == "__main__":
    ds = parse()
    print(f"Asaxiy: {len(ds)} deals")
    for d in ds[:5]:
        print(f"  -{d.discount_percent}% {d.new_price} (было {d.old_price}) | {d.title[:45]}")
