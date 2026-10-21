import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  Deal? selected;
  int chip = 0;
  static const chips = ['Все', 'Продукты', 'Стройка', 'Техника', 'Рестораны'];
  static const chipCat = [null, 'food', 'building', 'electronics', 'restaurants'];

  @override
  void dispose() { mapController.dispose(); super.dispose(); }

  List<Deal> get _withGeo => DealsStore.I.all
      .where((d) => d.lat != null && d.lon != null && d.hasDiscount)
      .where((d) => chipCat[chip] == null || d.category == chipCat[chip])
      .take(80)
      .toList();

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
                  width: 86, height: 40,
                  alignment: Alignment.center,
                  child: MapMarker(
                    store: d.store, percent: d.percent ?? 0, selected: selected?.id == d.id,
                    onTap: () {
                      setState(() => selected = d);
                      mapController.move(LatLng(d.lat!, d.lon!), 14);
                    },
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
          const SearchBarField(hint: 'Скидки рядом', showFilter: false),
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
              PriceText(d.newPrice!, size: 16),
            ])),
            const SizedBox(width: 8),
            Container(width: 48, height: 48,
              decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
              child: const Icon(Icons.near_me, color: C.onAccent, size: 22)),
          ]),
        ),
      ));
}
