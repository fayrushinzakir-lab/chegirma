import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deals_list.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DealsStore.I;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final stores = store.topStores(8);
          final cats = categories.where((c) => c.id != 'other').toList();
          return CustomScrollView(slivers: [
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 14), child: Text('Каталог', style: T.screenTitle))),
            SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverToBoxAdapter(child: SearchBarField(onTap: () {}))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82),
                delegate: SliverChildBuilderDelegate((_, i) {
                  final c = cats[i];
                  final n = store.countIn(c.id);
                  return PressScale(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DealsListScreen(title: c.name, deals: store.byCategory(c.id)))),
                    child: Container(
                      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        TintedPlate(tint: c.tint, icon: c.icon, size: 52, radius: 15),
                        const SizedBox(height: 10),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: kFont, fontSize: 12, fontWeight: FontWeight.w600, height: 1.15))),
                        if (n > 0) ...[
                          const SizedBox(height: 2),
                          Text('$n', style: T.meta.copyWith(fontSize: 11, color: C.green, fontWeight: FontWeight.w700)),
                        ],
                      ]),
                    ),
                  );
                }, childCount: cats.length),
              ),
            ),
            if (stores.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14), child: Text('Популярные магазины', style: T.section))),
              SliverToBoxAdapter(child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  itemCount: stores.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) => PressScale(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DealsListScreen(
                            title: stores[i].name,
                            deals: store.all.where((d) => d.store == stores[i].name).toList()))),
                    child: Column(children: [
                      StoreAvatar(stores[i].name, size: 60),
                      const SizedBox(height: 8),
                      SizedBox(width: 72, child: Text(stores[i].name, textAlign: TextAlign.center, maxLines: 1,
                          overflow: TextOverflow.ellipsis, style: T.meta.copyWith(fontWeight: FontWeight.w600))),
                      Text('${stores[i].count} скидок', style: T.meta.copyWith(fontSize: 10)),
                    ]),
                  ),
                ),
              )),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ]);
        },
      ),
    );
  }
}
