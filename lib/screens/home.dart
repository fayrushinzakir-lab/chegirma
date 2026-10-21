import 'dart:async';
import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';
import 'deals_list.dart';
import 'profile.dart';

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
    DealsStore.I.load();
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
                  sliver: SliverToBoxAdapter(child: SearchBarField(onTap: () {})),
                ),
                const SliverToBoxAdapter(child: _HotBanner()),
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
                      Padding(padding: const EdgeInsets.only(top: 4),
                        child: Text('Все', style: T.section.copyWith(color: C.green, fontSize: 14))),
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
                          onFav: () => setState(() => deals[i].favorite = !deals[i].favorite),
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

  Widget _eventsSection() {
    final events = [...promoEvents]..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text('События и акции', style: T.section),
      ),
      SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final e = events[i];
            return EventCard(event: e, onTap: () {
              final store = DealsStore.I;
              final deals = e.categoryFilter != null
                  ? store.byCategory(e.categoryFilter)
                  : store.byCategory(null).where((d) => (d.percent ?? 0) >= 20).toList();
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
                onTap: () {},
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.place_outlined, size: 15, color: C.textDim),
                  SizedBox(width: 4),
                  Text('Ташкент, Юнусабад', style: TextStyle(fontFamily: kFont, fontSize: 13, color: C.textDim, fontWeight: FontWeight.w600)),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: C.textDim),
                ]),
              ),
              const SizedBox(height: 4),
              Row(children: const [
                Text('chegirmalar', style: T.logo),
                Text('.uz', style: TextStyle(fontFamily: kFont, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: C.green)),
              ]),
            ]),
          ),
          Stack(children: [
            const IconCircleButton(Icons.notifications_none_rounded),
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
  const _HotBanner();
  @override
  State<_HotBanner> createState() => _HotBannerState();
}

class _HotBannerState extends State<_HotBanner> {
  final controller = PageController();
  int page = 0;
  Duration left = const Duration(hours: 5, minutes: 23, seconds: 10);
  Timer? tick, auto;
  static const slides = [('Горящие скидки дня', 50), ('Техника недели', 35), ('Стройка со скидкой', 40)];

  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => left = left.inSeconds > 0 ? left - const Duration(seconds: 1) : Duration.zero);
    });
    auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !controller.hasClients) return;
      controller.animateToPage((page + 1) % slides.length, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() { tick?.cancel(); auto?.cancel(); controller.dispose(); super.dispose(); }
  String two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = two(left.inHours), m = two(left.inMinutes % 60), s = two(left.inSeconds % 60);
    return Column(children: [
      SizedBox(
        height: 150,
        child: PageView.builder(
          controller: controller,
          onPageChanged: (i) => setState(() => page = i),
          itemCount: slides.length,
          itemBuilder: (_, i) {
            final (title, pct) = slides[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.banner),
                child: Container(
                  color: C.yellow,
                  child: Stack(children: [
                    Positioned(right: -30, bottom: -40, child: Container(width: 150, height: 150,
                      decoration: const BoxDecoration(color: C.yellowDeco, shape: BoxShape.circle))),
                    Positioned(right: 18, top: 0, bottom: 0, child: Center(child: Text('−$pct%',
                      style: const TextStyle(fontFamily: kFont, fontSize: 64, fontWeight: FontWeight.w800, letterSpacing: -3, color: C.onAccent)))),
                    if (i == 0) Positioned(left: 16, top: 16, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: C.onAccent, borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.schedule, size: 13, color: C.yellow),
                        const SizedBox(width: 5),
                        Text('$h:$m:$s', style: const TextStyle(fontFamily: kFont, color: C.text, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ]))),
                    Positioned(left: 16, bottom: 16, right: 110, child: Text(title,
                      style: const TextStyle(fontFamily: kFont, color: C.onAccent, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1))),
                    Positioned(right: 16, bottom: 16, child: Container(width: 44, height: 44,
                      decoration: const BoxDecoration(color: C.onAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward, color: C.yellow, size: 22))),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      CarouselDots(count: slides.length, active: page),
      const SizedBox(height: 20),
    ]);
  }
}
