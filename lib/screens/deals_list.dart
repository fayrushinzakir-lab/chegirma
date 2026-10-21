import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

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
  @override
  Widget build(BuildContext context) {
    final deals = widget.deals;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(children: [
              IconCircleButton(Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: T.screenTitle.copyWith(fontSize: 24), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(widget.subtitle ?? '${deals.length} предложений', style: T.meta),
              ])),
            ]),
          )),
          if (deals.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: Center(
              child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.search_off, size: 40, color: C.textDim),
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
                  onFav: () => setState(() => deals[i].favorite = !deals[i].favorite),
                ), childCount: deals.length),
              ),
            ),
        ]),
      ),
    );
  }
}
