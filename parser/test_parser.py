"""Юнит-тесты парсера. Запуск: python3 parser/test_parser.py"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parsers.base import categorize, extract_discount, dedupe, Deal  # noqa: E402

_fail = 0


def check(name, cond):
    global _fail
    print(("  ✓ " if cond else "  ✗ ") + name)
    if not cond:
        _fail += 1


print("categorize:")
check("духи → красота", categorize("Духи женские Gucci Flora") == "beauty")
check("блеск для губ → красота (не еда)", categorize("Блеск для губ матовый") == "beauty")
check("гель для бровей → красота (не other)", categorize("Гель для укладки бровей фиксатор") == "beauty")
check("электроплитка → электроника (не стройка)", categorize("Электроплитка настольная") == "electronics")
check("смесь Kabrita → детям", categorize("Смесь молочная Kabrita 3 Gold") == "kids")
check("iPhone → телефоны", categorize("Смартфон iPhone 15 128GB") == "phones")
check("цемент → стройка", categorize("Цемент М400 мешок") == "building")
check("кроссовки → одежда", categorize("Мужские кроссовки Nike") == "clothing")
check("турник → спорт", categorize("Турник универсальный настенный") == "sports")
check("женские часы → одежда/аксессуары", categorize("Женские часы с кожаным ремешком") == "clothing")
check("колготки → одежда", categorize("Женские капроновые колготки теплые") == "clothing")

print("extract_discount:")
o, n, p = extract_discount("Скидка 30% на всё", 70000)
check("'скидка 30%' → 30%", p == 30)
o, n, p = extract_discount("было 100000 стало 70000", None)
check("было→стало", o == 100000 and n == 70000 and p == 30)
o, n, p = extract_discount("обычный текст без скидки", 50000)
check("нет скидки → None", p is None)

print("dedupe:")
a = Deal(id="1", title="iPhone 15", store="Uzum", source="uzum", category="phones", new_price=10000000, discount_percent=10)
b = Deal(id="2", title="iPhone 15", store="Olcha", source="olcha", category="phones", new_price=10000000, discount_percent=20)
c = Deal(id="3", title="Диван", store="OLX", source="olx", category="furniture", new_price=500000, discount_percent=15)
res = dedupe([a, b, c])
check("межисточниковый дубль схлопнут (2 из 3)", len(res) == 2)
check("оставлен вариант с бОльшей скидкой", any(d.discount_percent == 20 for d in res if "iPhone" in d.title))

print()
if _fail:
    print(f"ПРОВАЛЕНО: {_fail}")
    sys.exit(1)
print("ВСЕ ТЕСТЫ ПРОШЛИ ✓")
