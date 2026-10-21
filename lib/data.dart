import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'persist.dart';

/// Источник реальных данных: публикуется GitHub Actions / парсером в репозиторий.
const kDealsUrl =
    'https://raw.githubusercontent.com/fayrushinzakir-lab/chegirma/main/docs/deals.json';

class Store {
  final String name;
  final int count;
  const Store(this.name, this.count);
}

/// Глобальное хранилище скидок (реальные данные OLX и др.).
class DealsStore extends ChangeNotifier {
  DealsStore._();
  static final DealsStore I = DealsStore._();

  List<Deal> all = [];
  bool loading = false;
  String? error;
  DateTime? generatedAt;

  // ───────── Избранное (сохраняется) ─────────
  final Set<String> favIds = {};

  Future<void> loadFavs() async {}

  /// Восстановление из хранилища (вызывается в main до runApp).
  void restore() {
    favIds.addAll(Persist.getList('favIds'));
    final w = Persist.getList('watchlist');
    if (w.isNotEmpty) { watchlist..clear()..addAll(w); }
  }

  void toggleFav(Deal d) {
    d.favorite = !d.favorite;
    if (d.favorite) {
      favIds.add(d.id);
    } else {
      favIds.remove(d.id);
    }
    Persist.set('favIds', favIds.toList());
    notifyListeners();
  }

  List<Deal> get favorites => all.where((d) => favIds.contains(d.id)).toList();

  // ───────── Список покупок (сохраняется) ─────────
  final List<String> watchlist = ['Кофе Jacobs', 'Подгузники Huggies', 'Шуруповёрт'];

  void addWatch(String q) {
    final s = q.trim();
    if (s.isEmpty || watchlist.any((w) => w.toLowerCase() == s.toLowerCase())) return;
    watchlist.insert(0, s);
    Persist.set('watchlist', watchlist);
    notifyListeners();
  }

  void removeWatch(String q) {
    watchlist.remove(q);
    Persist.set('watchlist', watchlist);
    notifyListeners();
  }

  /// Лучшая найденная скидка по запросу (или null).
  Deal? bestMatch(String q) {
    final m = search(q);
    return m.isEmpty ? null : m.first;
  }

  // Выбранный город (null = все города).
  String? selectedCity;

  void setCity(String? city) {
    selectedCity = city;
    notifyListeners();
  }

  /// Города из данных, по количеству скидок.
  List<String> get cities {
    final m = <String, int>{};
    for (final d in all) {
      if (d.city.isNotEmpty) m[d.city] = (m[d.city] ?? 0) + 1;
    }
    final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return e.map((x) => x.key).toList();
  }

  /// Оценка качества скидки — лучшее показываем первым.
  static int quality(Deal d) {
    var s = 0;
    if (d.oldPrice != null && d.percent != null) {
      s += 200 + (d.percent ?? 0);        // настоящая скидка (старая/новая цена)
    } else if (d.percent != null) {
      s += 100 + (d.percent ?? 0);        // процент извлечён из текста
    }
    if (d.imageUrl.isNotEmpty) s += 30;
    if (d.source != 'olx') s += 40;       // ритейлеры чище доски объявлений
    if (d.category == 'other') s -= 70;   // «Разное» — ниже
    return s;
  }

  List<Deal> byCategory(String? cat) {
    var list = all.where((d) {
      if (cat != null && d.category != cat) return false;
      if (selectedCity != null && d.city != selectedCity) return false;
      return true;
    }).toList();
    list.sort((a, b) => quality(b).compareTo(quality(a)));
    return list;
  }

  /// Лента для главной — без явного мусора («Разное» без скидки).
  List<Deal> feed(String? cat) =>
      byCategory(cat).where((d) => !(d.category == 'other' && d.percent == null)).toList();

  /// Поиск по названию/магазину.
  List<Deal> search(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return [];
    final list = all.where((d) =>
        d.title.toLowerCase().contains(s) || d.store.toLowerCase().contains(s)).toList();
    list.sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));
    return list;
  }

  /// Топ скидок с фото (для баннера).
  List<Deal> topDeals(int n) {
    final list = all.where((d) => d.hasDiscount && d.imageUrl.isNotEmpty).toList()
      ..sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));
    return list.take(n).toList();
  }

  /// Магазины по количеству скидок.
  List<Store> topStores([int limit = 10]) {
    final m = <String, int>{};
    for (final d in all) {
      m[d.store] = (m[d.store] ?? 0) + 1;
    }
    final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return e.take(limit).map((x) => Store(x.key, x.value)).toList();
  }

  int countIn(String cat) => all.where((d) => d.category == cat).length;

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (all.isNotEmpty && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final r = await http.get(Uri.parse(kDealsUrl)).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw 'HTTP ${r.statusCode}';
      final data = json.decode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final deals = (data['deals'] as List)
          .map((e) => Deal.fromJson(e as Map<String, dynamic>))
          .where((d) => d.newPrice != null && d.title.isNotEmpty)
          .toList();
      for (final d in deals) {
        d.favorite = favIds.contains(d.id);
      }
      all = deals;
      final g = data['generatedAt'];
      generatedAt = g is String ? DateTime.tryParse(g) : null;
    } catch (e) {
      error = '$e';
      if (kDebugMode) debugPrint('DealsStore.load error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

/// «Обновлено N минут назад».
String updatedAgo(DateTime? t) {
  if (t == null) return 'обновляется';
  final m = DateTime.now().toUtc().difference(t.toUtc()).inMinutes;
  if (m < 1) return 'обновлено только что';
  if (m < 60) return 'обновлено $m мин назад';
  final h = m ~/ 60;
  if (h < 24) return 'обновлено $h ч назад';
  return 'обновлено ${h ~/ 24} дн назад';
}
