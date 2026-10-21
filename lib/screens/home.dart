import 'dart:async';
import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';
import 'deals_list.dart';
import 'favorites.dart';
import 'profile.dart';
import 'search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int chip = 0;
  static const chips = ['Все', 'Продукты', 'Стройка', 'Техника', 'Телефоны', 'Одежда', 'Мебель', 'Рестораны'];
  static const chipCat = [null, 'food', 'building', 'electronics', 'phones', 'clothing', 'furniture', 'restaurants'];

  @override
  void initState() {
    super.initState();
    DealsStore.I.load().then((_) => DealsStore.I.loadFavs());
    DealsStore.I.loadFavs();
  }

  void _open(Deal d) => Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, a, __) => DealDetailScreen(deal: d),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      )).then((_) => setState(() {}));

  @override
  Widget build(BuildContext context) {
    final store = DealsStore.I;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final deals = store.byCategory(chipCat[chip]);
          return RefreshIndicator(
            color: C.green, backgroundColor: C.card,
            onRefresh: () => store.load(force: true),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  sliver: SliverToBoxAdapter(child: SearchBarField(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())))),
                ),
                SliverToBoxAdapter(child: _HotBanner(onOpenDeal: _open)),
                SliverToBoxAdapter(child: _eventsSection()),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      itemCount: chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ChipFilter(chips[i], active: chip == i, onTap: () => setState(() => chip = i)),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Лучшее рядом с вами', style: T.section),
                        const SizedBox(height: 3),
                        Text(store.loading && store.all.isEmpty ? 'загружаем скидки…' : updatedAgo(store.generatedAt),
                            style: T.meta),
                      ]),
                      PressScale(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                            DealsListScreen(title: 'Все скидки', deals: store.byCategory(chipCat[chip])))),
                        child: Padding(padding: const EdgeInsets.only(top: 4),
                          child: Text('Все', style: T.section.copyWith(color: C.green, fontSize: 14)))),
                    ],
                  ),
                )),
                if (store.error != null && store.all.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _errorBox(store))
                else if (store.all.isEmpty)
                  _skeletonGrid()
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.58),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => DealCard(
                          deal: deals[i],
                          onTap: () => _open(deals[i]),
                          onFav: () => store.toggleFav(deals[i]),
                        ),
                        childCount: deals.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _skeletonGrid() => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.58),
          delegate: SliverChildBuilderDelegate((_, __) => const _CardSkeleton(), childCount: 6),
        ),
      );

  Widget _errorBox(DealsStore store) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: C.textDim),
          const SizedBox(height: 14),
          const Text('Не удалось загрузить скидки', style: TextStyle(fontFamily: kFont, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Проверьте интернет и попробуйте снова', textAlign: TextAlign.center, style: T.meta),
          const SizedBox(height: 18),
          SizedBox(width: 180, child: PrimaryButton('Повторить', onTap: () => store.load(force: true))),
        ]),
      );

  void _showCitySheet() {
    final store = DealsStore.I;
    final cities = store.cities;
    showModalBottomSheet(
      context: context,
      backgroundColor: C.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: C.raised2, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Выберите город', style: T.section))),
          Flexible(child: ListView(shrinkWrap: true, children: [
            _cityTile('Все города Узбекистана', null, store),
            for (final c in cities) _cityTile(c, c, store),
          ])),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _cityTile(String label, String? value, DealsStore store) {
    final active = store.selectedCity == value;
    return ListTile(
      onTap: () { store.setCity(value); Navigator.pop(context); setState(() {}); },
      leading: Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
          color: active ? C.green : C.textDim, size: 22),
      title: Text(label, style: TextStyle(fontFamily: kFont, fontSize: 15,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? C.text : C.textDim)),
      trailing: value == null ? null : Text('${store.all.where((d) => d.city == value).length}', style: T.meta),
    );
  }

  List<Deal> _eventDeals(PromoEvent e) {
    final store = DealsStore.I;
    return e.categoryFilter != null
        ? store.byCategory(e.categoryFilter)
        : store.byCategory(null).where((d) => (d.percent ?? 0) >= 20).toList();
  }

  Widget _eventsSection() {
    final events = [...promoEvents]..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
        child: Row(children: const [
          Text('События и акции', style: T.section),
          SizedBox(width: 8),
          Icon(Icons.auto_awesome, size: 16, color: C.yellow),
        ]),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text('Готовьтесь к распродажам заранее', style: T.meta)),
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final e = events[i];
            final deals = _eventDeals(e);
            return EventCard(event: e, dealsCount: deals.length, onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealsListScreen(
                title: e.title, subtitle: '${e.whenText} · ${deals.length} скидок', deals: deals)));
            });
          },
        ),
      ),
      const SizedBox(height: 22),
    ]);
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PressScale(
                onTap: _showCitySheet,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.place_outlined, size: 15, color: C.textDim),
                  const SizedBox(width: 4),
                  Text(DealsStore.I.selectedCity ?? 'Все города Узбекистана',
                      style: const TextStyle(fontFamily: kFont, fontSize: 13, color: C.textDim, fontWeight: FontWeight.w600)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: C.textDim),
                ]),
              ),
              const SizedBox(height: 4),
              Row(children: const [
                Text('chegirmalar', style: T.logo),
                Text('.uz', style: TextStyle(fontFamily: kFont, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: C.green)),
              ]),
            ]),
          ),
          IconCircleButton(Icons.favorite_border,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
          const SizedBox(width: 10),
          Stack(children: [
            IconCircleButton(Icons.notifications_none_rounded, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Уведомления о скидках появятся здесь', style: TextStyle(fontFamily: kFont, color: C.text)),
                backgroundColor: C.card, duration: Duration(seconds: 2)));
            }),
            Positioned(right: 11, top: 11, child: Container(width: 8, height: 8,
                decoration: BoxDecoration(color: C.red, shape: BoxShape.circle, border: Border.all(color: C.bg, width: 1.5)))),
          ]),
          const SizedBox(width: 10),
          PressScale(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(width: 44, height: 44,
              decoration: const BoxDecoration(color: C.avatar, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: C.text, size: 22)),
          ),
        ]),
      );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Skeleton(double.infinity, 118, r: R.plate),
          SizedBox(height: 10),
          Skeleton(90, 16),
          SizedBox(height: 8),
          Skeleton(140, 12),
          SizedBox(height: 8),
          Skeleton(110, 12),
        ]),
      );
}

class _HotBanner extends StatefulWidget {
  final void Function(Deal) onOpenDeal;
  const _HotBanner({required this.onOpenDeal});
  @override
  State<_HotBanner> createState() => _HotBannerState();
}

class _HotBannerState extends State<_HotBanner> {
  final controller = PageController();
  int page = 0;
  Duration left = Duration.zero;
  Timer? tick, auto;

  Duration _untilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return midnight.difference(now);
  }

  @override
  void initState() {
    super.initState();
    left = _untilMidnight();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => left = _untilMidnight());
    });
    auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !controller.hasClients) return;
      final count = DealsStore.I.topDeals(4).length + 1;
      controller.animateToPage((page + 1) % count, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() { tick?.cancel(); auto?.cancel(); controller.dispose(); super.dispose(); }
  String two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final deals = DealsStore.I.topDeals(4);
    final count = deals.length + 1; // 0 — брендовый слайд
    return Column(children: [
      SizedBox(
        height: 160,
        child: PageView.builder(
          controller: controller,
          onPageChanged: (i) => setState(() => page = i),
          itemCount: count,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: i == 0 ? _brandedSlide() : _dealSlide(deals[i - 1]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      CarouselDots(count: count, active: page),
      const SizedBox(height: 20),
    ]);
  }

  Widget _brandedSlide() {
    final h = two(left.inHours), m = two(left.inMinutes % 60), s = two(left.inSeconds % 60);
    return ClipRRect(
      borderRadius: BorderRadius.circular(R.banner),
      child: Container(
        color: C.yellow,
        child: Stack(children: [
          Positioned(right: -30, bottom: -40, child: Container(width: 160, height: 160,
            decoration: const BoxDecoration(color: C.yellowDeco, shape: BoxShape.circle))),
          const Positioned(right: 20, top: 0, bottom: 0, child: Center(child: Text('−50%',
            style: TextStyle(fontFamily: kFont, fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: -3, color: C.onAccent)))),
          Positioned(left: 16, top: 16, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: C.onAccent, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_fire_department, size: 13, color: C.yellow),
              const SizedBox(width: 5),
              Text('$h:$m:$s', style: const TextStyle(fontFamily: kFont, color: C.text, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ]))),
          const Positioned(left: 16, bottom: 16, right: 110, child: Text('Горящие скидки дня',
            style: TextStyle(fontFamily: kFont, color: C.onAccent, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1))),
        ]),
      ),
    );
  }

  Widget _dealSlide(Deal d) {
    return GestureDetector(
      onTap: () => widget.onOpenDeal(d),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.banner),
        child: Stack(fit: StackFit.expand, children: [
          ImagePlate(deal: d, height: 160, radius: 0),
          // затемнение для читаемости
          Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.centerRight, end: Alignment.centerLeft,
            colors: [Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.82)]))),
          Positioned(left: 16, top: 16, child: DiscountBadge(d.percent ?? 0, fontSize: 18)),
          Positioned(left: 16, right: 16, bottom: 14, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              StoreAvatar(d.store, size: 20),
              const SizedBox(width: 6),
              Text(d.store, style: const TextStyle(fontFamily: kFont, color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: kFont, color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${groupPrice(d.newPrice!)} сум', style: const TextStyle(fontFamily: kFont, color: C.green, fontSize: 19, fontWeight: FontWeight.w800)),
              if (d.oldPrice != null) ...[
                const SizedBox(width: 8),
                Padding(padding: const EdgeInsets.only(bottom: 2), child: Text('${groupPrice(d.oldPrice!)}',
                  style: const TextStyle(fontFamily: kFont, color: Colors.white54, fontSize: 13, decoration: TextDecoration.lineThrough))),
              ],
            ]),
          ])),
        ]),
      ),
    );
  }
}
