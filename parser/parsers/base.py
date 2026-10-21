"""Базовые типы и утилиты для парсеров Chegirma.

Без сторонних зависимостей (только stdlib) — чтобы одинаково работало
локально и в GitHub Actions без установки пакетов.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, asdict, field
from typing import Optional


@dataclass
class Deal:
    """Нормализованная скидка — ровно то, что потом читает приложение."""
    id: str
    title: str
    store: str
    source: str              # olx | texnomart | telegram | ...
    category: str
    new_price: Optional[int]
    currency: str = "UZS"
    old_price: Optional[int] = None
    discount_percent: Optional[int] = None
    city: str = ""
    address: str = ""
    image_url: str = ""
    url: str = ""
    created_at: str = ""
    ends_at: str = ""
    promoted: bool = False
    lat: Optional[float] = None
    lon: Optional[float] = None
    phone: str = ""
    seller: str = ""

    def to_json(self) -> dict:
        d = asdict(self)
        # camelCase для Flutter-клиента
        return {
            "id": d["id"],
            "title": d["title"],
            "store": d["store"],
            "source": d["source"],
            "category": d["category"],
            "newPrice": d["new_price"],
            "oldPrice": d["old_price"],
            "currency": d["currency"],
            "discountPercent": d["discount_percent"],
            "city": d["city"],
            "address": d["address"],
            "imageUrl": d["image_url"],
            "url": d["url"],
            "createdAt": d["created_at"],
            "endsAt": d["ends_at"],
            "promoted": d["promoted"],
            "lat": d["lat"],
            "lon": d["lon"],
            "phone": d["phone"],
            "seller": d["seller"],
        }


# ─────────────────────── Извлечение скидки из текста ───────────────────────

_PCT_RE = re.compile(r"(?:скидк\w*|chegirma|aksiy\w*|-)\s*(\d{1,2})\s*%", re.I)
_PCT_RE2 = re.compile(r"(\d{1,2})\s*%\s*(?:скидк\w*|chegirma|off|dan)", re.I)
_WAS_NOW_RE = re.compile(
    r"(?:было|было:|вместо|oldin|avval)\D{0,6}([\d\s]{4,12})"
    r"\D{1,20}?(?:стало|сейчас|hozir|endi|за)\D{0,6}([\d\s]{4,12})",
    re.I,
)
_ARROW_RE = re.compile(r"([\d\s]{4,12})\s*(?:→|->|=>)\s*([\d\s]{4,12})")


def _to_int(s: str) -> Optional[int]:
    digits = re.sub(r"\D", "", s or "")
    if not digits:
        return None
    try:
        v = int(digits)
        return v if v >= 1000 else None  # отсекаем мусорные мелкие числа
    except ValueError:
        return None


def extract_discount(text: str, new_price: Optional[int]):
    """Возвращает (old_price, new_price, percent) из свободного текста.

    Приоритет: явная пара было→стало, затем стрелка, затем процент.
    """
    text = text or ""

    for rx in (_WAS_NOW_RE, _ARROW_RE):
        m = rx.search(text)
        if m:
            old = _to_int(m.group(1))
            new = _to_int(m.group(2))
            if old and new and old > new:
                pct = round((old - new) / old * 100)
                if 3 <= pct <= 95:
                    return old, new, pct

    for rx in (_PCT_RE, _PCT_RE2):
        m = rx.search(text)
        if m:
            pct = int(m.group(1))
            if 3 <= pct <= 95 and new_price:
                old = round(new_price / (1 - pct / 100))
                return old, new_price, pct
            if 3 <= pct <= 95:
                return None, new_price, pct

    return None, new_price, None


# ─────────────────────── Категоризация по ключевым словам ───────────────────────

_CATEGORY_KEYWORDS = {
    "phones": ["iphone", "айфон", "samsung galaxy", "telefon", "телефон", "смартфон", "redmi",
               "xiaomi", "honor", "poco", "наушник", "quloqchin", "airpods", "powerbank", "зарядка"],
    "electronics": ["телевизор", "televizor", "ноутбук", "noutbuk", "ноут", "монитор", "техника",
                    "холодильник", "muzlatgich", "стиральн", "kir yuvish", "кондиционер", "konditsioner",
                    "пылесос", "changyutgich", "микроволнов", "mikroto'lqin", "планшет", "planshet",
                    "компьютер", "kompyuter", "видеокарт", "приставк", "playstation", "camera", "камера"],
    "building": ["цемент", "cement", "кирпич", "g'isht", "гипс", "гипсокартон", "шифер", "профнастил",
                 "арматура", "строй", "qurilish", "краск", "bo'yoq", "утеплител", "пеноблок", "газоблок",
                 "керамзит", "песок", "qum", "щебень", "плитка", "kafel", "обои", "oboi", "ламинат", "линолеум"],
    "plumbing": ["смеситель", "унитаз", "раковина", "сантехника", "santexnika", "труба", "quvur",
                 "ванна", "душ", "dush", "бойлер", "boyler", "водонагрев", "канализац"],
    "tools": ["дрель", "перфоратор", "шуруповёрт", "шуруповерт", "инструмент", "asbob", "болгарк",
              "сварочн", "payvand", "генератор", "компрессор", "станок", "отвёртк", "гайковёрт"],
    "furniture": ["диван", "divan", "шкаф", "мебель", "mebel", "кровать", "krovat", "стол ", "stol",
                  "стул", "stul", "кресло", "kreslo", "матрас", "matras", "комод", "тумб", "гарнитур"],
    "clothing": ["куртка", "обувь", "кроссовк", "одежда", "kiyim", "poyabzal", "платье", "ko'ylak",
                 "джинс", "shim", "футболк", "рубашк", "palto", "пальто", "сумк", "sumka", "ботинк",
                 "сапог", "etik", "кофта", "свитер", "спортивн"],
    "food": ["масло", "yog'", "продукт", "сахар", "shakar", "мука", "un ", "мясо", "go'sht", "рис",
             "guruch", "макарон", "makaron", "чай", "choy", "кофе", "qahva", "мёд", "asal", "орех",
             "конфет", "шоколад", "shokolad", "колбас", "сыр", "pishloq"],
    "drinks": ["сок", "напиток", "ichimlik", "вода", "suv", "газировк", "pepsi", "cola", "кола", "энергетик"],
    "pharmacy": ["витамин", "крем", "парфюм", "atir", "косметик", "kosmetika", "лекарств", "dori",
                 "шампун", "shampun", "маск", "сыворотк", "бад", "гель для душа", "мыло", "sovun",
                 "зубн", "tish", "памперс", "подгузник"],
    "auto": ["шины", "shina", "аккумулятор", "akkumulyator", "автозапчаст", "ehtiyot qism",
             "масло моторн", "автомобил", "mashina uchun", "авторезин", "диски r1", "запчаст"],
    "kids": ["детск", "bolalar", "коляск", "aravacha", "игрушк", "o'yinchoq", "детское пит", "манеж",
             "велосипед детск", "самокат"],
    "household": ["порошок", "kukun", "моющ", "бытовая химия", "ariel", "fairy", "гель для стирк",
                  "кондиционер для бель", "посуд", "idish", "чистящ", "салфетк", "пакет"],
    "restaurants": ["ресторан", "restoran", "кафе", "kafe", "пицц", "pizza", "суши", "sushi",
                    "доставка еды", "ovqat yetkaz", "fast food", "бургер", "burger", "лаваш",
                    "шаурм", "shaurma", "банкет", "to'yxona", "кейтеринг", "osh ", "плов"],
}


def categorize(title: str, fallback: str = "other") -> str:
    t = (title or "").lower()
    for cat, words in _CATEGORY_KEYWORDS.items():
        if any(w in t for w in words):
            return cat
    return fallback


# ─────────────────────── Дедупликация ───────────────────────

def _norm_key(d: Deal) -> str:
    t = re.sub(r"[^a-zа-я0-9ё]", "", (d.title or "").lower())[:40]
    return f"{d.source}:{d.store.lower()}:{t}"


def dedupe(deals: list[Deal]) -> list[Deal]:
    seen: dict[str, Deal] = {}
    for d in deals:
        k = _norm_key(d)
        # оставляем вариант с бОльшей известной скидкой / с ценой
        prev = seen.get(k)
        if prev is None:
            seen[k] = d
        else:
            score = (d.discount_percent or 0, d.new_price or 0)
            pscore = (prev.discount_percent or 0, prev.new_price or 0)
            if score > pscore:
                seen[k] = d
    return list(seen.values())
