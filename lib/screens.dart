import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// ─────────────────────────── Главная лента ───────────────────────────
class HomeScreen extends StatefulWidget {
  final List<Deal> deals;
  final void Function(Deal) onToggleFavorite;
  const HomeScreen({super.key, required this.deals, required this.onToggleFavorite});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Sort { discount, fresh, near }

class _HomeScreenState extends State<HomeScreen> {
  _Sort sort = _Sort.discount;

  List<Deal> get sorted {
    final list = [...widget.deals];
    switch (sort) {
      case _Sort.discount:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      case _Sort.fresh:
        list.sort((a, b) => b.id.compareTo(a.id));
      case _Sort.near:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Chegirma',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('UZ',
                            style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      const Text('Ташкент',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Лучшие скидки сегодня',
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 14)),
                  const SizedBox(height: 16),
                  // Поиск
                  MatteCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    color: AppColors.surface,
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                        SizedBox(width: 10),
                        Text('Цемент, масло, iPhone…',
                            style: TextStyle(
                                color: AppColors.textTertiary, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Чипы сортировки
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SortChip('По скидке',
                      selected: sort == _Sort.discount,
                      onTap: () => setState(() => sort = _Sort.discount)),
                  const SizedBox(width: 8),
                  SortChip('Новые',
                      selected: sort == _Sort.fresh,
                      onTap: () => setState(() => sort = _Sort.fresh)),
                  const SizedBox(width: 8),
                  SortChip('Рядом',
                      selected: sort == _Sort.near,
                      onTap: () => setState(() => sort = _Sort.near)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final deal = sorted[i];
                return DealCard(
                  deal: deal,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DealDetailScreen(
                      deal: deal,
                      onToggleFavorite: widget.onToggleFavorite,
                    ),
                  )),
                  onFavorite: () =>
                      setState(() => widget.onToggleFavorite(deal)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────── Категории ───────────────────────────
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text('Категории',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = categories[i];
                  return MatteCard(
                    onTap: () {},
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.tint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(c.icon, color: c.tint, size: 22),
                        ),
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.2)),
                      ],
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────── Избранное ───────────────────────────
class FavoritesScreen extends StatelessWidget {
  final List<Deal> deals;
  final void Function(Deal) onToggleFavorite;
  const FavoritesScreen(
      {super.key, required this.deals, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final favs = deals.where((d) => d.favorite).toList();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Избранное',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
          ),
          Expanded(
            child: favs.isEmpty
                ? const _EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Пока пусто',
                    subtitle:
                        'Нажимайте ♥ на скидках — они появятся здесь, чтобы не потерять.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final deal = favs[i];
                      return StatefulBuilder(
                        builder: (context, setLocal) => DealCard(
                          deal: deal,
                          onTap: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => DealDetailScreen(
                              deal: deal,
                              onToggleFavorite: onToggleFavorite,
                            ),
                          )),
                          onFavorite: () =>
                              setLocal(() => onToggleFavorite(deal)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────── Профиль ───────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Профиль',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 16),
          MatteCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Гость',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Войти по номеру телефона',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsGroup(
            items: [
              ('Язык', 'Русский', Icons.language_outlined),
              ('Город', 'Ташкент', Icons.location_city_outlined),
              ('Интересующие категории', '6 выбрано', Icons.tune_outlined),
            ],
          ),
          const SizedBox(height: 10),
          const _SettingsGroup(
            items: [
              ('Тема', 'Чёрная матовая', Icons.dark_mode_outlined),
              ('Уведомления', 'Включены', Icons.notifications_outlined),
            ],
          ),
          const SizedBox(height: 10),
          const _SettingsGroup(
            items: [
              ('Кабинет партнёра', '', Icons.storefront_outlined),
              ('О приложении', 'v0.1 · прототип', Icons.info_outline),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<(String, String, IconData)> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return MatteCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.border, indent: 52),
            ListTile(
              leading: Icon(items[i].$3, color: AppColors.textSecondary, size: 22),
              title: Text(items[i].$1,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(items[i].$2,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary, size: 20),
                ],
              ),
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textTertiary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────── Карточка скидки ───────────────────────────
class DealDetailScreen extends StatefulWidget {
  final Deal deal;
  final void Function(Deal) onToggleFavorite;
  const DealDetailScreen(
      {super.key, required this.deal, required this.onToggleFavorite});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final d = widget.deal;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        setState(() => widget.onToggleFavorite(d)),
                    icon: Icon(
                      d.favorite ? Icons.favorite : Icons.favorite_border,
                      color: d.favorite
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Крупное «фото» + бейдж
                  Stack(
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: DealImage(deal: d, size: 110),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: DiscountBadge(d.discountPercent, large: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(d.store,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2)),
                  const SizedBox(height: 6),
                  Text(d.title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 20),
                  // Цены
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(formatUzs(d.newPrice),
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8)),
                      const SizedBox(width: 12),
                      Text(formatUzs(d.oldPrice),
                          style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 17,
                              decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Экономия ${formatUzs(d.oldPrice - d.newPrice)}',
                      style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  _InfoRow(
                      icon: Icons.schedule,
                      label: 'Срок действия',
                      value: d.daysLeft <= 0
                          ? 'Заканчивается сегодня'
                          : 'Ещё ${d.daysLeft} дн.'),
                  _InfoRow(
                      icon: Icons.place_outlined,
                      label: 'Адрес',
                      value: '${d.city}, ${d.address}'),
                  _InfoRow(
                      icon: Icons.near_me_outlined,
                      label: 'Расстояние',
                      value: '${d.distanceKm.toStringAsFixed(1)} км от вас'),
                  const SizedBox(height: 24),
                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.chip)),
                          ),
                          icon: const Icon(Icons.directions, size: 20),
                          label: const Text('Маршрут',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SquareButton(
                        icon: Icons.telegram,
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _SquareButton(
                        icon: Icons.open_in_new,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text('$label:  ',
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 14)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}
