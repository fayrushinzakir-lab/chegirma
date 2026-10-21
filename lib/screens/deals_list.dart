import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

enum _Sort { discount, cheap, expensive }

/// Универсальный экран списка скидок (категория, магазин, событие).
class DealsListScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Deal> deals;
  const DealsListScreen({super.key, required this.title, required this.deals, this.subtitle});
  @override
  State<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends State<DealsListScreen> {
  _Sort sort = _Sort.discount;

  List<Deal> get _sorted {
    final list = [...widget.deals];
    switch (sort) {
      case _Sort.discount:
        list.sort((a, b) => (b.percent ?? 0).compareTo(a.percent ?? 0));
      case _Sort.cheap:
        list.sort((a, b) => (a.newPrice ?? 0).compareTo(b.newPrice ?? 0));
      case _Sort.expensive:
        list.sort((a, b) => (b.newPrice ?? 0).compareTo(a.newPrice ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final deals = _sorted;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(children: [
              IconCircleButton(Symbols.arrow_back, onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: T.screenTitle.copyWith(fontSize: 24), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(widget.subtitle ?? '${deals.length} предложений', style: T.meta),
              ])),
            ]),
          )),
          if (deals.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                children: [
                  _sortChip('По скидке', Symbols.local_fire_department, _Sort.discount),
                  const SizedBox(width: 8),
                  _sortChip('Сначала дешевле', Symbols.arrow_downward, _Sort.cheap),
                  const SizedBox(width: 8),
                  _sortChip('Сначала дороже', Symbols.arrow_upward, _Sort.expensive),
                ],
              ),
            )),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (deals.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: Center(
              child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Symbols.search_off, size: 40, color: C.textDim),
                SizedBox(height: 12),
                Text('Пока нет скидок в этом разделе', style: T.meta),
              ])),
            ))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.58),
                delegate: SliverChildBuilderDelegate((_, i) => DealCard(
                  deal: deals[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deals[i]))),
                  onFav: () => setState(() => DealsStore.I.toggleFav(deals[i])),
                ), childCount: deals.length),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _sortChip(String label, IconData icon, _Sort s) {
    final active = sort == s;
    return PressScale(
      onTap: () => setState(() => sort = s),
      child: Container(
        height: 38, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? C.text : C.card,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: active ? C.text : C.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: active ? C.onAccent : C.textDim, weight: 600),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? C.onAccent : C.textDim)),
        ]),
      ),
    );
  }
}
