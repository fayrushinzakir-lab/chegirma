import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';
import 'search.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  Deal? selected;
  int chip = 0;
  LatLng? _me;
  static const chips = ['Все', 'Продукты', 'Стройка', 'Техника', 'Рестораны'];
  static const chipCat = [null, 'food', 'building', 'electronics', 'restaurants'];

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate({bool recenter = false}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() => _me = LatLng(pos.latitude, pos.longitude));
      if (recenter) mapController.move(_me!, 14);
    } catch (_) {}
  }

  @override
  void dispose() { mapController.dispose(); super.dispose(); }

  /// Метки: прореживаем по сетке (лучшая скидка на район), чтобы не наслаивались.
  List<Deal> get _withGeo {
    final raw = DealsStore.I.all
        .where((d) => d.lat != null && d.lon != null && d.hasDiscount)
        .where((d) => chipCat[chip] == null || d.category == chipCat[chip]);
    final grid = <String, Deal>{};
    for (final d in raw) {
      final key = '${(d.lat! * 250).round()}_${(d.lon! * 250).round()}'; // ~0.004°
      final cur = grid[key];
      if (cur == null || (d.percent ?? 0) > (cur.percent ?? 0)) grid[key] = d;
    }
    final list = grid.values.toList()
      ..sort((a, b) => (a.percent ?? 0).compareTo(b.percent ?? 0)); // крупные % сверху
    return list.length > 70 ? list.sublist(list.length - 70) : list;
  }

  @override
  Widget build(BuildContext context) {
    final deals = _withGeo;
    return Stack(children: [
      FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: const LatLng(41.311, 69.279), // Ташкент
          initialZoom: 11.5,
          minZoom: 4, maxZoom: 18,
          onTap: (_, __) => setState(() => selected = null),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'uz.chegirmalar.chegirma',
            // Бесплатные светлые тайлы OSM → тёмный фильтр под тему (инверсия яркости).
            tileBuilder: (context, tileWidget, tile) => ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -0.2, -0.7, -0.07, 0, 255,
                -0.2, -0.7, -0.07, 0, 255,
                -0.2, -0.7, -0.07, 0, 255,
                0, 0, 0, 1, 0,
              ]),
              child: tileWidget,
            ),
          ),
          MarkerLayer(
            markers: [
              for (final d in deals)
                Marker(
                  point: LatLng(d.lat!, d.lon!),
                  width: 96, height: 50,
                  alignment: Alignment.bottomCenter,
                  child: MapMarker(
                    store: d.store, percent: d.percent ?? 0, selected: selected?.id == d.id,
                    onTap: () {
                      setState(() => selected = d);
                      mapController.move(LatLng(d.lat!, d.lon!), 14);
                    },
                  ),
                ),
              if (_me != null)
                Marker(
                  point: _me!, width: 26, height: 26, alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: C.userDot.withValues(alpha: 0.25)),
                    child: Center(child: Container(width: 14, height: 14,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: C.userDot,
                          border: Border.all(color: Colors.white, width: 2.5)))),
                  ),
                ),
            ],
          ),
        ],
      ),
      // верхняя панель
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(children: [
          SearchBarField(hint: 'Скидки рядом', showFilter: false,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()))),
          const SizedBox(height: 12),
          SizedBox(height: 38, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChipFilter(chips[i], active: chip == i,
                onTap: () => setState(() { chip = i; selected = null; })),
          )),
        ]),
      )),
      // счётчик
      if (DealsStore.I.all.isNotEmpty)
        Positioned(right: 20, bottom: selected != null ? 300 : 110,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: C.panel, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.borderPanel)),
            child: Text('${deals.length} рядом', style: T.meta.copyWith(fontWeight: FontWeight.w700, color: C.text)),
          )),
      // кнопка «где я»
      Positioned(
        right: 20, bottom: (selected != null ? 300 : 110) + 48,
        child: PressScale(
          onTap: () => _locate(recenter: true),
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: C.panel, shape: BoxShape.circle,
                border: Border.all(color: C.borderPanel),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(Icons.my_location, color: _me != null ? C.green : C.text, size: 22),
          ),
        ),
      ),
      if (selected != null) _selectedCard(selected!),
    ]);
  }

  Widget _selectedCard(Deal d) => Positioned(
      left: 20, right: 20, bottom: 110,
      child: PressScale(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealDetailScreen(deal: d))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.panel, borderRadius: BorderRadius.circular(R.card),
              border: Border.all(color: C.borderPanel),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(children: [
            Stack(children: [
              SizedBox(width: 62, height: 62, child: ImagePlate(deal: d, height: 62, radius: 14)),
              if (d.percent != null) Positioned(left: 4, top: 4, child: DiscountBadge(d.percent!, fontSize: 11)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.store, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w700, color: C.textDim)),
              const SizedBox(height: 2),
              Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.productName),
              const SizedBox(height: 6),
              Row(children: [
                PriceText(d.newPrice!, size: 16),
                if (_me != null) ...[
                  const Spacer(),
                  const Icon(Icons.near_me_outlined, size: 13, color: C.textDim),
                  const SizedBox(width: 3),
                  Text('${const Distance().as(LengthUnit.Kilometer, _me!, LatLng(d.lat!, d.lon!)).toStringAsFixed(1)} км',
                      style: T.meta),
                ],
              ]),
            ])),
            const SizedBox(width: 8),
            Container(width: 48, height: 48,
              decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
              child: const Icon(Icons.near_me, color: C.onAccent, size: 22)),
          ]),
        ),
      ));
}
