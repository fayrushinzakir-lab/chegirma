"""Парсер Uzum Market через headless-браузер (Playwright).

Uzum — SPA с GraphQL за авторизацией. Обходим «по-человечески»: реальный
Chromium сам получает токен и рендерит товары, мы читаем DOM. Берём карточки,
где есть старая (зачёркнутая) и новая цена — настоящая скидка.

Требует: pip install playwright && playwright install chromium.
Работает локально (на Mac через launchd), не в облаке.
"""
from __future__ import annotations

import re

from .base import Deal, categorize

QUERIES = [
    "chegirma", "aksiya", "telefon", "noutbuk", "televizor", "kiyim", "poyabzal",
    "kosmetika", "parfum", "oziq ovqat", "bolalar", "kitob", "sport", "mebel",
    "maishiy texnika", "aksessuar", "soat", "sumka",
]


def _num(s: str):
    d = re.sub(r"\D", "", s or "")
    return int(d) if d else None


def parse() -> list[Deal]:
    try:
        from playwright.sync_api import sync_playwright
    except Exception as e:  # noqa: BLE001
        print(f"  ! Uzum: playwright не установлен ({e})")
        return []

    deals: list[Deal] = []
    seen: set[str] = set()
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True, args=["--no-sandbox"])
            page = browser.new_page(locale="ru-RU", viewport={"width": 1280, "height": 1600})
            for q in QUERIES:
                try:
                    page.goto(f"https://uzum.uz/ru/search?query={q}", timeout=45000, wait_until="domcontentloaded")
                    page.wait_for_timeout(4500)
                    page.mouse.wheel(0, 4000)
                    page.wait_for_timeout(1500)
                    cards = page.query_selector_all('a[href*="/product/"]')
                except Exception as e:  # noqa: BLE001
                    print(f"  ! Uzum '{q}' failed: {e}")
                    continue

                for c in cards:
                    try:
                        href = c.get_attribute("href") or ""
                        m = re.search(r"/product/[^/?#]+?-(\d+)", href) or re.search(r"-(\d+)", href)
                        pid = m.group(1) if m else href
                        if not pid or pid in seen:
                            continue

                        title_el = c.query_selector('[class*="title"]')
                        title = (title_el.inner_text().strip() if title_el else "")
                        if len(title) < 4:
                            continue

                        price_el = c.query_selector('[class*="card-price"]')
                        ptext = price_el.inner_text() if price_el else ""
                        prices = []
                        for line in ptext.split("\n"):
                            if "мес" in line.lower():
                                continue
                            v = _num(line)
                            if v and 1000 <= v <= 500_000_000:
                                prices.append(v)
                        if len(prices) < 2:
                            continue
                        new_price, old_price = prices[0], prices[1]
                        if old_price <= new_price:
                            continue
                        pct = round((old_price - new_price) / old_price * 100)
                        if pct < 3 or pct > 95:
                            continue

                        img_el = c.query_selector('img[src*="images.uzum"]') or c.query_selector("img")
                        img = img_el.get_attribute("src") if img_el else ""

                        seen.add(pid)
                        deals.append(Deal(
                            id=f"uzum-{pid}",
                            title=title,
                            store="Uzum Market",
                            source="uzum",
                            category=categorize(title),
                            new_price=new_price,
                            currency="UZS",
                            old_price=old_price,
                            discount_percent=pct,
                            city="",
                            image_url=img or "",
                            url=("https://uzum.uz" + href) if href.startswith("/") else href,
                            seller="Uzum Market",
                        ))
                    except Exception:  # noqa: BLE001
                        continue
            browser.close()
    except Exception as e:  # noqa: BLE001
        print(f"  ! Uzum browser error: {e}")
    return deals


if __name__ == "__main__":
    ds = parse()
    print(f"Uzum: {len(ds)} deals")
    for d in ds[:6]:
        print(f"  -{d.discount_percent}% {d.new_price} (было {d.old_price}) | {d.title[:45]}")
