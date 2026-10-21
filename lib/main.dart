import 'package:flutter/material.dart';
import 'models.dart';
import 'screens.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  applySystemChrome();
  runApp(const ChegirmaApp());
}

class ChegirmaApp extends StatelessWidget {
  const ChegirmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chegirma',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootScaffold(),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int index = 0;
  final deals = mockDeals;

  void _toggleFavorite(Deal d) {
    setState(() => d.favorite = !d.favorite);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(deals: deals, onToggleFavorite: _toggleFavorite),
      const CategoriesScreen(),
      MapScreen(deals: deals),
      FavoritesScreen(deals: deals, onToggleFavorite: _toggleFavorite),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.bg,
            indicatorColor: AppColors.accentSoft,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.textPrimary : AppColors.textTertiary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? AppColors.accent : AppColors.textTertiary,
              );
            }),
          ),
          child: NavigationBar(
            height: 64,
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.local_offer_outlined),
                  selectedIcon: Icon(Icons.local_offer),
                  label: 'Лента'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view),
                  label: 'Категории'),
              NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map),
                  label: 'Карта'),
              NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Избранное'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Профиль'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карта — в прототипе матовая заглушка + список «рядом с вами».
/// Настоящая карта (OpenStreetMap/flutter_map) — отдельная фаза.
class MapScreen extends StatelessWidget {
  final List<Deal> deals;
  const MapScreen({super.key, required this.deals});

  @override
  Widget build(BuildContext context) {
    final near = [...deals]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Карта',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.map_outlined,
                      color: AppColors.textTertiary, size: 36),
                  SizedBox(height: 10),
                  Text('Карта магазинов рядом',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('подключается в следующей фазе',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Рядом с вами',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: near.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => MatteCard(
                onTap: () {},
                child: Row(
                  children: [
                    DealImage(deal: near[i], size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(near[i].store,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(near[i].address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('${near[i].distanceKm.toStringAsFixed(1)} км',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
