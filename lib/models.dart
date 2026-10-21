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
  Category('other', 'Разное', Icons.local_offer_outlined, Tint.soft),
];

Category catOf(String id) =>
    categories.firstWhere((c) => c.id == id, orElse: () => categories.last);

const _months = ['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];

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
  bool favorite;

  Deal({
    required this.id, required this.title, required this.store, required this.source,
    required this.category, this.oldPrice, this.newPrice, this.discountPercent,
    this.city = '', this.address = '', this.imageUrl = '', this.url = '', this.endsAt = '',
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
      );

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
