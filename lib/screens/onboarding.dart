import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../ui_kit.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pc = PageController();
  int page = 0;
  int lang = 2;
  String city = 'Ташкент';
  static const langs = ["O‘zbekcha", "Ўзбекча", "Русский"];
  static const cities = ['Ташкент', 'Самарканд', 'Бухара', 'Андижан', 'Наманган', 'Фергана', 'Карши', 'Нукус'];

  static const pages = [
    ('Все скидки Узбекистана\nв одном месте', 'Мы сами находим акции в магазинах — от продуктов до стройматериалов — и сообщаем, когда цена падает.'),
    ('Скидки рядом с вами', 'Смотрите выгодные предложения на карте — рядом с домом и работой.'),
    ('Сообщим о снижении цены', 'Добавьте товар в список — пришлём уведомление, как только появится скидка.'),
  ];

  @override
  void dispose() { pc.dispose(); super.dispose(); }

  void _finish() {
    DealsStore.I.setCity(city == 'Ташкент' ? null : city); // Ташкент = по умолчанию показываем всё
    widget.onDone();
  }

  void _pickCity() {
    showModalBottomSheet(
      context: context, backgroundColor: C.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.raised2, borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('Выберите город', style: T.section))),
        Flexible(child: ListView(shrinkWrap: true, children: [
          for (final c in cities)
            ListTile(
              onTap: () { setState(() => city = c); Navigator.pop(context); },
              leading: Icon(city == c ? Icons.radio_button_checked : Icons.radio_button_off, color: city == c ? C.green : C.textDim, size: 22),
              title: Text(c, style: TextStyle(fontFamily: kFont, fontSize: 15, color: city == c ? C.text : C.textDim, fontWeight: city == c ? FontWeight.w700 : FontWeight.w500)),
            ),
        ])),
        const SizedBox(height: 8),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            // шапка: логотип + Пропустить
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(children: [
                Row(children: const [
                  Text('chegirma', style: TextStyle(fontFamily: kFont, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
                  SizedBox(width: 6),
                  Padding(padding: EdgeInsets.only(bottom: 3), child: CircleAvatar(radius: 4, backgroundColor: C.green)),
                ]),
                const Spacer(),
                GestureDetector(onTap: _finish,
                  child: const Text('Пропустить', style: TextStyle(fontFamily: kFont, color: C.textDim, fontSize: 15, fontWeight: FontWeight.w600))),
              ]),
            ),
            // свайпаемая зона: герой + заголовок + подзаголовок
            Expanded(
              child: PageView.builder(
                controller: pc,
                onPageChanged: (i) => setState(() => page = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => Column(children: [
                  const Spacer(flex: 2),
                  SizedBox(height: 260, child: i == 0 ? const _DiscountHero() : _IconHero(i)),
                  const Spacer(flex: 1),
                  Text(pages[i].$1, textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: kFont, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.1)),
                  const SizedBox(height: 14),
                  Text(pages[i].$2, textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: kFont, fontSize: 15, color: C.textDim, height: 1.5)),
                  const Spacer(flex: 2),
                ]),
              ),
            ),
            CarouselDots(count: pages.length, active: page),
            const SizedBox(height: 20),
            // язык
            Align(alignment: Alignment.centerLeft,
              child: Text('Язык приложения', style: T.meta.copyWith(fontWeight: FontWeight.w700))),
            const SizedBox(height: 8),
            Row(children: [
              for (int i = 0; i < langs.length; i++)
                Expanded(child: Padding(
                  padding: EdgeInsets.only(right: i < langs.length - 1 ? 8 : 0),
                  child: PressScale(onTap: () => setState(() => lang = i), child: Container(
                    height: 48, alignment: Alignment.center,
                    decoration: BoxDecoration(color: lang == i ? C.text : C.card, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: lang == i ? C.text : C.border)),
                    child: Text(langs[i], style: TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w700,
                        color: lang == i ? C.onAccent : C.textDim)))),
                )),
            ]),
            const SizedBox(height: 10),
            // город
            PressScale(onTap: _pickCity, child: Container(
              height: 54, padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
              child: Row(children: [
                const Icon(Icons.place_outlined, size: 18, color: C.textDim),
                const SizedBox(width: 8),
                Text(city, style: const TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                const Text('Изменить', style: TextStyle(fontFamily: kFont, fontSize: 14, color: C.green, fontWeight: FontWeight.w700)),
              ]),
            )),
            const SizedBox(height: 14),
            PrimaryButton('Начать', icon: Icons.arrow_forward, onTap: _finish),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

/// Иконочный «герой» для 2-го и 3-го экранов.
class _IconHero extends StatelessWidget {
  final int page;
  const _IconHero(this.page);
  @override
  Widget build(BuildContext context) {
    final icon = page == 1 ? Icons.near_me_outlined : Icons.notifications_active_outlined;
    return Center(child: Container(
      width: 140, height: 140,
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(36), border: Border.all(color: C.border)),
      child: Icon(icon, size: 64, color: C.green),
    ));
  }
}

/// Богатый «герой» первого экрана: плавающие карточки магазинов + жёлтая −50%.
class _DiscountHero extends StatelessWidget {
  const _DiscountHero();
  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      // Korzinka −23% (слева)
      Positioned(left: 8, top: 70, child: Transform.rotate(angle: -0.12, child: _storeCard('K', 'Korzinka', '−23%', C.green))),
      // Стройбаза −15% (справа сверху)
      Positioned(right: 4, top: 20, child: Transform.rotate(angle: 0.08, child: _storeCard('С', 'Стройбаза', '−15%', C.tBuildIc))),
      // Большая жёлтая −50%
      Positioned(top: 90, child: _bigYellow()),
    ]);
  }

  Widget _storeCard(String letter, String name, String pct, Color pctColor) => Container(
        width: 170, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 24, height: 24, alignment: Alignment.center,
              decoration: const BoxDecoration(color: C.avatar, shape: BoxShape.circle),
              child: Text(letter, style: const TextStyle(fontFamily: kFont, fontSize: 12, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontFamily: kFont, fontSize: 13, color: C.textDim, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(pct, style: TextStyle(fontFamily: kFont, fontSize: 30, fontWeight: FontWeight.w800, color: pctColor, letterSpacing: -1)),
        ]),
      );

  Widget _bigYellow() => SizedBox(
        width: 220, height: 150,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 220, height: 150, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: C.yellow, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: C.yellow.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: C.onAccent, borderRadius: BorderRadius.circular(20)),
                child: const Text('Сегодня', style: TextStyle(fontFamily: kFont, color: C.text, fontSize: 12, fontWeight: FontWeight.w800))),
              const Spacer(),
              const Text('−50%', style: TextStyle(fontFamily: kFont, color: C.onAccent, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1)),
            ]),
          ),
          Positioned(right: -18, bottom: 28, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Text('Цена снизилась', style: TextStyle(fontFamily: kFont, color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          )),
        ]),
      );
}
