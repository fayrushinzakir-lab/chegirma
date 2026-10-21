import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home.dart';
import 'screens/catalog.dart';
import 'screens/map.dart';
import 'screens/shopping_list.dart';
import 'screens/onboarding.dart';

void main() {
  applySystemChrome();
  runApp(const ChegirmaApp());
}

class ChegirmaApp extends StatelessWidget {
  const ChegirmaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Chegirma',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Root(),
      );
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool onboarded = false;
  @override
  Widget build(BuildContext context) => onboarded
      ? const HomeShell()
      : OnboardingScreen(onDone: () => setState(() => onboarded = true));
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [HomeScreen(), CatalogScreen(), MapScreen(), ShoppingListScreen()];
  static const tabs = [
    (Icons.home_outlined, Icons.home, 'Главная'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Каталог'),
    (Icons.map_outlined, Icons.map, 'Карта'),
    (Icons.list_alt_outlined, Icons.list_alt, 'Список'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
          ),
        ),
        // затухание контента в фон над меню
        Positioned(left: 0, right: 0, bottom: 0, height: 120, child: IgnorePointer(
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [C.bg.withValues(alpha: 0), C.bg]))))),
        // плавающее меню
        Positioned(left: 16, right: 16, bottom: 22, child: _menu()),
      ]),
    );
  }

  Widget _menu() => Container(
        height: 68,
        decoration: BoxDecoration(
          color: C.panel,
          borderRadius: BorderRadius.circular(R.menu),
          border: Border.all(color: C.borderPanel),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Row(children: List.generate(tabs.length, (i) {
          final active = index == i;
          final (ic, icA, label) = tabs[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => index = i),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(active ? icA : ic, size: 24, color: active ? C.green : C.textDim),
                const SizedBox(height: 4),
                Text(label, style: T.navLabel.copyWith(color: active ? C.green : C.textDim)),
              ]),
            ),
          );
        })),
      );
}
