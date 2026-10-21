import 'package:flutter/material.dart';
import 'theme.dart';

enum Tint { food, build, tech, soft }

Color tintBg(Tint t) => switch (t) {
      Tint.food => C.tFoodBg, Tint.build => C.tBuildBg, Tint.tech => C.tTechBg, Tint.soft => C.tSoftBg,
    };
Color tintIc(Tint t) => switch (t) {
      Tint.food => C.tFoodIc, Tint.build => C.tBuildIc, Tint.tech => C.tTechIc, Tint.soft => C.tSoftIc,
    };

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Tint tint;
  const Category(this.id, this.name, this.icon, this.tint);
}

const categories = <Category>[
  Category('food', 'Продукты', Icons.shopping_basket_outlined, Tint.food),
  Category('drinks', 'Напитки', Icons.local_cafe_outlined, Tint.food),
  Category('household', 'Бытовая химия', Icons.cleaning_services_outlined, Tint.soft),
  Category('electronics', 'Электроника', Icons.devices_other_outlined, Tint.tech),
  Category('phones', 'Телефоны', Icons.smartphone_outlined, Tint.tech),
  Category('clothing', 'Одежда', Icons.checkroom_outlined, Tint.soft),
  Category('building', 'Стройматериалы', Icons.construction_outlined, Tint.build),
  Category('plumbing', 'Сантехника', Icons.plumbing_outlined, Tint.build),
  Category('tools', 'Инструменты', Icons.handyman_outlined, Tint.build),
  Category('furniture', 'Мебель', Icons.chair_outlined, Tint.build),
  Category('pharmacy', 'Аптека', Icons.medication_outlined, Tint.soft),
  Category('kids', 'Детям', Icons.child_care_outlined, Tint.soft),
  Category('auto', 'Авто', Icons.directions_car_outlined, Tint.tech),
  Category('restaurants', 'Рестораны', Icons.restaurant_outlined, Tint.food),
  Category('other', 'Разное', Icons.local_offer_outlined, Tint.soft),
];

Category catOf(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.last);

const _months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];

/// Событийная акция (Чёрная пятница, 8 Марта и т.д.).
class PromoEvent {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int month;
  final int day;
  final String? categoryFilter; // если задано — показываем только эту категорию
  const PromoEvent(this.title, this.subtitle, this.icon, this.color, this.month, this.day, {this.categoryFilter});

  DateTime get nextDate {
    final now = DateTime.now();
    var d = DateTime(now.year, month, day);
    if (d.isBefore(DateTime(now.year, now.month, now.day))) {
      d = DateTime(now.year + 1, month, day);
    }
    return d;
  }

  int get daysUntil => nextDate.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;

  String get whenText {
    final n = daysUntil;
    if (n == 0) return 'сегодня!';
    if (n == 1) return 'завтра';
    if (n <= 30) return 'через $n дн.';
    return '${nextDate.day} ${_months[nextDate.month - 1]}';
  }
}

const promoEvents = <PromoEvent>[
  PromoEvent('Чёрная пятница', 'Скидки до −70% во всех магазинах', Icons.bolt, Color(0xFFE23D3D), 11, 28),
  PromoEvent('Новый год', 'Подарки и акции к празднику', Icons.ac_unit, Color(0xFF4A9EFF), 12, 31),
  PromoEvent('8 Марта · Женский день', 'Косметика, цветы, подарки', Icons.favorite, Color(0xFFE05AA8), 3, 8, categoryFilter: 'pharmacy'),
  PromoEvent('Навруз', 'Весенние скидки', Icons.local_florist, Color(0xFF3DDC84), 3, 21),
  PromoEvent('1 сентября', 'Всё для школы', Icons.school, Color(0xFFFF9F0A), 9, 1, categoryFilter: 'kids'),
  PromoEvent('Киберпонедельник', 'Техника по лучшим ценам', Icons.devices, Color(0xFF8FB6E8), 12, 1, categoryFilter: 'electronics'),
];

class Deal {
  final String id;
  final String title;
  final String store;
  final String source;       // olx | telegram | ...
  final String category;
  final int? oldPrice;
  final int? newPrice;
  final int? discountPercent;
  final String city;
  final String address;
  final String imageUrl;
  final String url;
  final String endsAt;
  final double? lat;
  final double? lon;
  final String phone;
  final String seller;
  bool favorite;

  Deal({
    required this.id, required this.title, required this.store, required this.source,
    required this.category, this.oldPrice, this.newPrice, this.discountPercent,
    this.city = '', this.address = '', this.imageUrl = '', this.url = '', this.endsAt = '',
    this.lat, this.lon, this.phone = '', this.seller = '',
    this.favorite = false,
  });

  factory Deal.fromJson(Map<String, dynamic> j) => Deal(
        id: '${j['id']}',
        title: (j['title'] ?? '').toString().trim(),
        store: (j['store'] ?? 'OLX').toString(),
        source: (j['source'] ?? 'olx').toString(),
        category: (j['category'] ?? 'other').toString(),
        oldPrice: _asInt(j['oldPrice']),
        newPrice: _asInt(j['newPrice']),
        discountPercent: _asInt(j['discountPercent']),
        city: (j['city'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        endsAt: (j['endsAt'] ?? '').toString(),
        lat: _asDouble(j['lat']),
        lon: _asDouble(j['lon']),
        phone: (j['phone'] ?? '').toString(),
        seller: (j['seller'] ?? '').toString(),
      );

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse('$v');
  }

  int? get percent {
    if (discountPercent != null && discountPercent! > 0) return discountPercent;
    if (oldPrice != null && newPrice != null && oldPrice! > newPrice!) {
      return ((oldPrice! - newPrice!) / oldPrice! * 100).round();
    }
    return null;
  }

  bool get hasDiscount => (percent ?? 0) > 0;
  int? get savings => (oldPrice != null && newPrice != null && oldPrice! > newPrice!) ? oldPrice! - newPrice! : null;

  DateTime? get _end {
    if (endsAt.isEmpty) return null;
    try { return DateTime.parse(endsAt); } catch (_) { return null; }
  }

  int? get daysLeft {
    final e = _end;
    if (e == null) return null;
    final d = e.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  String? get endDateText {
    final e = _end;
    if (e == null) return null;
    return '${e.day} ${_months[e.month - 1]}';
  }
}
