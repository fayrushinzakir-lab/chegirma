import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final store = DealsStore.I;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final favs = store.favorites;
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(children: [
                  IconCircleButton(Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Избранное', style: T.screenTitle),
                    Text('${favs.length} сохранённых скидок', style: T.meta),
                  ])),
                ]),
              )),
              if (favs.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 72, height: 72,
                      decoration: BoxDecoration(color: C.card, shape: BoxShape.circle, border: Border.all(color: C.border)),
                      child: const Icon(Icons.favorite_border, color: C.textDim, size: 32)),
                    const SizedBox(height: 16),
                    const Text('Пока пусто', style: TextStyle(fontFamily: kFont, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Нажимайте ♥ на скидках — они появятся здесь',
                        textAlign: TextAlign.center, style: T.meta),
                  ]),
                )))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.58),
                    delegate: SliverChildBuilderDelegate((_, i) => DealCard(
                      deal: favs[i],
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealDetailScreen(deal: favs[i]))),
                      onFav: () => store.toggleFav(favs[i]),
                    ), childCount: favs.length),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}
