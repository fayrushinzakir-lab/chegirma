import 'package:flutter/material.dart';
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
  int city = 0;
  static const langs = ["O‘zbekcha", "Ўзбекча", "Русский"];
  static const cities = ['Ташкент', 'Самарканд', 'Бухара', 'Андижан', 'Наманган', 'Фергана'];

  static const intro = [
    (Icons.bolt_outlined, 'Все скидки в одном месте', 'Приложение само находит акции из магазинов, Telegram-каналов и сайтов по всему Узбекистану.'),
    (Icons.near_me_outlined, 'Скидки рядом с вами', 'Смотрите выгодные предложения на карте — рядом с домом и работой.'),
    (Icons.notifications_active_outlined, 'Сообщим о снижении цены', 'Добавьте товар в список — пришлём уведомление, как только появится скидка.'),
  ];

  @override
  void dispose() { pc.dispose(); super.dispose(); }

  void _next() {
    if (page < 3) {
      pc.animateToPage(page + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
            child: page < 3 ? TextButton(onPressed: widget.onDone,
                child: const Text('Пропустить', style: TextStyle(fontFamily: kFont, color: C.textDim, fontWeight: FontWeight.w600)))
              : const SizedBox(height: 48))),
          Expanded(child: PageView(
            controller: pc,
            onPageChanged: (i) => setState(() => page = i),
            children: [
              ...intro.map((e) => _introPage(e.$1, e.$2, e.$3)),
              _setupPage(),
            ],
          )),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              CarouselDots(count: 4, active: page),
              const SizedBox(height: 20),
              PrimaryButton(page < 3 ? 'Далее' : 'Начать', onTap: _next),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _introPage(IconData icon, String title, String sub) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 120, height: 120,
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(32),
                border: Border.all(color: C.border)),
            child: Icon(icon, size: 56, color: C.green)),
          const SizedBox(height: 32),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kFont, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Text(sub, textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kFont, fontSize: 15, color: C.textDim, height: 1.5)),
        ]),
      );

  Widget _setupPage() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 8),
          const Text('Почти готово', style: TextStyle(fontFamily: kFont, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Выберите язык и город', style: TextStyle(fontFamily: kFont, fontSize: 15, color: C.textDim)),
          const SizedBox(height: 24),
          Text('Язык', style: T.meta.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: [
            for (int i = 0; i < langs.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < langs.length - 1 ? 8 : 0),
                  child: _pill(langs[i], lang == i, () => setState(() => lang = i), height: 48),
                ),
              ),
          ]),
          const SizedBox(height: 24),
          Text('Город', style: T.meta.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < cities.length; i++)
              _pill(cities[i], city == i, () => setState(() => city = i), green: true),
          ]),
        ],
      );

  Widget _pill(String label, bool active, VoidCallback onTap,
      {double height = 44, bool green = false}) {
    final activeColor = green ? C.green : C.text;
    return PressScale(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? activeColor : C.card,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: active ? activeColor : C.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? C.onAccent : (green ? C.text : C.textDim))),
      ),
    );
  }
}
