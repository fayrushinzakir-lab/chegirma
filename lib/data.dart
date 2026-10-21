import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

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

  // ───────── Избранное (сохраняется на устройстве) ─────────
  final Set<String> favIds = {};
  bool _favLoaded = false;

  Future<void> loadFavs() async {
    if (_favLoaded) return;
    _favLoaded = true;
    try {
      final sp = await SharedPreferences.getInstance();
      favIds.addAll(sp.getStringList('favIds') ?? const []);
      for (final d in all) {
        d.favorite = favIds.contains(d.id);
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFav(Deal d) async {
    d.favorite = !d.favorite;
    if (d.favorite) {
      favIds.add(d.id);
    } else {
      favIds.remove(d.id);
    }
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList('favIds', favIds.toList());
    } catch (_) {}
  }

  List<Deal> get favorites => all.where((d) => favIds.contains(d.id)).toList();

  List<Deal> byCategory(String? cat) {
    final list = cat == null ? [...all] : all.where((d) => d.category == cat).toList();
    list.sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));
    return list;
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
