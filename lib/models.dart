import 'package:flutter/material.dart';

/// Категория скидки.
class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color tint;
  const Category(this.id, this.name, this.icon, this.tint);
}

const categories = <Category>[
  Category('food', 'Продукты', Icons.shopping_basket_outlined, Color(0xFFFF9F0A)),
  Category('drinks', 'Напитки', Icons.local_cafe_outlined, Color(0xFF64D2FF)),
  Category('household', 'Бытовая химия', Icons.cleaning_services_outlined, Color(0xFF5E5CE6)),
  Category('electronics', 'Электроника', Icons.devices_other_outlined, Color(0xFF32D74B)),
  Category('phones', 'Телефоны', Icons.smartphone_outlined, Color(0xFF0A84FF)),
  Category('clothing', 'Одежда и обувь', Icons.checkroom_outlined, Color(0xFFFF375F)),
  Category('kids', 'Детские товары', Icons.child_care_outlined, Color(0xFFFFD60A)),
  Category('pharmacy', 'Аптека и красота', Icons.medication_outlined, Color(0xFFBF5AF2)),
  Category('furniture', 'Мебель', Icons.chair_outlined, Color(0xFFFF9F0A)),
  Category('building', 'Стройматериалы', Icons.construction_outlined, Color(0xFFA2845E)),
  Category('plumbing', 'Сантехника', Icons.plumbing_outlined, Color(0xFF64D2FF)),
  Category('tools', 'Инструменты', Icons.handyman_outlined, Color(0xFFFF453A)),
  Category('auto', 'Авто-товары', Icons.directions_car_outlined, Color(0xFF5E5CE6)),
  Category('food_delivery', 'Рестораны', Icons.restaurant_outlined, Color(0xFF32D74B)),
];

/// Скидка/акция.
class Deal {
  final String id;
  final String title;
  final String store;
  final String category;
  final int oldPrice;
  final int newPrice;
  final String city;
  final String address;
  final DateTime endsAt;
  final double distanceKm;
  final bool promoted;
  bool favorite;

  Deal({
    required this.id,
    required this.title,
    required this.store,
    required this.category,
    required this.oldPrice,
    required this.newPrice,
    required this.city,
    required this.address,
    required this.endsAt,
    required this.distanceKm,
    this.promoted = false,
    this.favorite = false,
  });

  int get discountPercent =>
      (((oldPrice - newPrice) / oldPrice) * 100).round();

  int get daysLeft {
    final now = DateTime(2026, 10, 21);
    return endsAt.difference(now).inDays;
  }
}

/// Моковые данные (без бэкенда и ИИ) — имитируют улов сборщиков.
final mockDeals = <Deal>[
  Deal(
    id: '1',
    title: 'Масло подсолнечное Oleyna 1 л',
    store: 'Korzinka',
    category: 'food',
    oldPrice: 28000,
    newPrice: 19500,
    city: 'Ташкент',
    address: 'ул. Амира Темура, 15',
    endsAt: DateTime(2026, 10, 23),
    distanceKm: 0.8,
    promoted: true,
  ),
  Deal(
    id: '2',
    title: 'Цемент М400, мешок 50 кг',
    store: 'Qurilish Market',
    category: 'building',
    oldPrice: 65000,
    newPrice: 48000,
    city: 'Ташкент',
    address: 'Сергелийский р-н, база 7',
    endsAt: DateTime(2026, 10, 28),
    distanceKm: 4.2,
  ),
  Deal(
    id: '3',
    title: 'iPhone 15 128GB',
    store: 'Texnomart',
    category: 'phones',
    oldPrice: 12900000,
    newPrice: 11490000,
    city: 'Ташкент',
    address: 'ТРЦ Samarqand Darvoza',
    endsAt: DateTime(2026, 10, 25),
    distanceKm: 2.1,
    promoted: true,
  ),
  Deal(
    id: '4',
    title: 'Стиральный порошок Ariel 6 кг',
    store: 'Makro',
    category: 'household',
    oldPrice: 145000,
    newPrice: 99000,
    city: 'Самарканд',
    address: 'ул. Регистан, 3',
    endsAt: DateTime(2026, 10, 22),
    distanceKm: 1.5,
  ),
  Deal(
    id: '5',
    title: 'Куртка зимняя мужская',
    store: 'Havas',
    category: 'clothing',
    oldPrice: 520000,
    newPrice: 312000,
    city: 'Ташкент',
    address: 'Чиланзар, квартал 12',
    endsAt: DateTime(2026, 10, 30),
    distanceKm: 3.7,
  ),
  Deal(
    id: '6',
    title: 'Дрель-шуруповёрт Bosch 18V',
    store: 'Idea',
    category: 'tools',
    oldPrice: 1250000,
    newPrice: 890000,
    city: 'Ташкент',
    address: 'Юнусабад, 4-й квартал',
    endsAt: DateTime(2026, 10, 24),
    distanceKm: 5.9,
  ),
  Deal(
    id: '7',
    title: 'Смеситель для кухни',
    store: 'Santexnika Plus',
    category: 'plumbing',
    oldPrice: 340000,
    newPrice: 229000,
    city: 'Бухара',
    address: 'ул. Накшбанди, 22',
    endsAt: DateTime(2026, 10, 27),
    distanceKm: 2.8,
  ),
  Deal(
    id: '8',
    title: 'Молоко Nestle 2.5% 1 л',
    store: 'Korzinka',
    category: 'food',
    oldPrice: 14000,
    newPrice: 10500,
    city: 'Ташкент',
    address: 'Мирзо-Улугбек, массив Ц-1',
    endsAt: DateTime(2026, 10, 22),
    distanceKm: 1.1,
  ),
  Deal(
    id: '9',
    title: 'Телевизор Samsung 55" 4K',
    store: 'Mediapark',
    category: 'electronics',
    oldPrice: 8900000,
    newPrice: 6999000,
    city: 'Ташкент',
    address: 'ТРЦ Compass',
    endsAt: DateTime(2026, 11, 2),
    distanceKm: 6.4,
    promoted: true,
  ),
  Deal(
    id: '10',
    title: 'Витамин C Solgar 60 таб',
    store: 'Oxymed',
    category: 'pharmacy',
    oldPrice: 185000,
    newPrice: 139000,
    city: 'Ташкент',
    address: 'Яшнабад, ул. Фергана йули',
    endsAt: DateTime(2026, 10, 26),
    distanceKm: 0.5,
  ),
];

String categoryName(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.first).name;
