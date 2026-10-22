import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
  Category('food', 'Продукты', Symbols.shopping_basket, Tint.food),
  Category('drinks', 'Напитки', Symbols.local_drink, Tint.food),
  Category('household', 'Бытовая химия', Symbols.cleaning_services, Tint.soft),
  Category('electronics', 'Электроника', Symbols.tv, Tint.tech),
  Category('phones', 'Телефоны', Symbols.smartphone, Tint.tech),
  Category('clothing', 'Одежда', Symbols.checkroom, Tint.soft),
  Category('building', 'Стройматериалы', Symbols.construction, Tint.build),
  Category('plumbing', 'Сантехника', Symbols.plumbing, Tint.build),
  Category('tools', 'Инструменты', Symbols.handyman, Tint.build),
  Category('furniture', 'Мебель', Symbols.chair, Tint.build),
  Category('pharmacy', 'Аптека', Symbols.medical_services, Tint.soft),
  Category('kids', 'Детям', Symbols.toys, Tint.soft),
  Category('auto', 'Авто', Symbols.directions_car, Tint.tech),
  Category('restaurants', 'Рестораны', Symbols.restaurant, Tint.food),
  Category('other', 'Разное', Symbols.local_offer, Tint.soft),
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
  PromoEvent('Чёрная пятница', 'Скидки до −70% во всех магазинах', Symbols.bolt, Color(0xFFE23D3D), 11, 28),
  PromoEvent('Новый год', 'Подарки и акции к празднику', Symbols.ac_unit, Color(0xFF4A9EFF), 12, 31),
  PromoEvent('8 Марта · Женский день', 'Косметика, цветы, подарки', Symbols.favorite, Color(0xFFE05AA8), 3, 8, categoryFilter: 'pharmacy'),
  PromoEvent('Навруз', 'Весенние скидки', Symbols.local_florist, Color(0xFF3DDC84), 3, 21),
  PromoEvent('1 сентября', 'Всё для школы', Symbols.school, Color(0xFFFF9F0A), 9, 1, categoryFilter: 'kids'),
  PromoEvent('Киберпонедельник', 'Техника по лучшим ценам', Symbols.devices, Color(0xFF8FB6E8), 12, 1, categoryFilter: 'electronics'),
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
  final List<int> priceHistory;
  final bool? fair;
  bool favorite;

  Deal({
    required this.id, required this.title, required this.store, required this.source,
    required this.category, this.oldPrice, this.newPrice, this.discountPercent,
    this.city = '', this.address = '', this.imageUrl = '', this.url = '', this.endsAt = '',
    this.lat, this.lon, this.phone = '', this.seller = '',
    this.priceHistory = const [], this.fair,
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
        priceHistory: (j['priceHistory'] as List?)?.map((e) => _asInt(e) ?? 0).where((e) => e > 0).toList() ?? const [],
        fair: j['fair'] is bool ? j['fair'] as bool : null,
      );

  /// Для сохранения избранного (снимок, чтобы не пропадал из ленты).
  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'store': store, 'source': source, 'category': category,
        'oldPrice': oldPrice, 'newPrice': newPrice, 'discountPercent': discountPercent,
        'city': city, 'address': address, 'imageUrl': imageUrl, 'url': url, 'endsAt': endsAt,
        'lat': lat, 'lon': lon, 'phone': phone, 'seller': seller,
        'priceHistory': priceHistory, 'fair': fair,
      };

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
