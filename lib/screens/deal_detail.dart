import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';

class DealDetailScreen extends StatefulWidget {
  final Deal deal;
  const DealDetailScreen({super.key, required this.deal});
  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  Future<void> _openSource() async {
    if (widget.deal.url.isEmpty) return;
    final uri = Uri.tryParse(widget.deal.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call() async {
    if (widget.deal.phone.isEmpty) return;
    await launchUrl(Uri.parse('tel:${widget.deal.phone}'));
  }

  Future<void> _share() async {
    final d = widget.deal;
    final pct = d.percent != null ? ' −${d.percent}%' : '';
    final text = '🔥$pct ${d.title}\n${groupPrice(d.newPrice!)} сум · ${d.store}'
        '${d.url.isNotEmpty ? '\n${d.url}' : ''}\n\nНайдено в chegirmalar.uz';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deal;
    final cat = catOf(d.category);
    final days = d.daysLeft;
    final progress = days == null ? null : 1 - (days / 14).clamp(0.0, 1.0);
    final soon = days != null && days <= 2;

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        // Верхняя зона 320px — реальное фото
        Positioned(top: 0, left: 0, right: 0, height: 340,
          child: d.imageUrl.isEmpty
              ? Container(color: tintBg(cat.tint), child: Center(child: Icon(cat.icon, color: tintIc(cat.tint), size: 120)))
              : Image.network(d.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: tintBg(cat.tint),
                      child: Center(child: Icon(cat.icon, color: tintIc(cat.tint), size: 120))),
                  loadingBuilder: (_, w, p) => p == null ? w : Container(color: tintBg(cat.tint)))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              IconCircleButton(Icons.arrow_back, bg: C.bg.withValues(alpha: 0.6), onTap: () => Navigator.of(context).pop()),
              const Spacer(),
              IconCircleButton(Icons.ios_share, bg: C.bg.withValues(alpha: 0.6), onTap: _share),
              const SizedBox(width: 10),
              Container(decoration: BoxDecoration(color: C.bg.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: HeartButton(value: d.favorite, size: 44, onChanged: (_) => setState(() => DealsStore.I.toggleFav(d)))),
            ]),
          ),
        ),
        if (d.percent != null) Positioned(left: 20, top: 280, child: DiscountBadge(d.percent!, fontSize: 22)),
        Padding(
          padding: const EdgeInsets.only(top: 320),
          child: Container(
            decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
            child: Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.raised2, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 18),
                    Row(children: [
                      StoreAvatar(d.store, size: 22),
                      const SizedBox(width: 8),
                      Flexible(child: Text(d.store, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: T.meta.copyWith(fontWeight: FontWeight.w700, fontSize: 13))),
                      if (d.city.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.place_outlined, size: 14, color: C.textDim),
                        const SizedBox(width: 2),
                        Text(d.city, style: T.meta),
                      ],
                    ]),
                    const SizedBox(height: 10),
                    Text(d.title, style: const TextStyle(fontFamily: kFont, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2)),
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      PriceText(d.newPrice!, size: 32),
                      if (d.oldPrice != null) ...[
                        const SizedBox(width: 10),
                        Padding(padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${groupPrice(d.oldPrice!)} сум', style: T.oldPrice.copyWith(fontSize: 14))),
                      ],
                    ]),
                    if (d.savings != null) ...[
                      const SizedBox(height: 12),
                      SavingsPill(d.savings!),
                    ],
                    if (days != null && progress != null) ...[
                      const SizedBox(height: 24),
                      _block(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Flexible(child: Text(d.endDateText != null ? 'Акция до ${d.endDateText}' : 'Срок акции',
                              style: const TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w700))),
                          Text(days <= 0 ? 'заканчивается' : 'осталось $days дней',
                              style: TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w700, color: soon ? C.warn : C.textDim)),
                        ]),
                        const SizedBox(height: 12),
                        DealProgress(progress),
                      ])),
                    ],
                    const SizedBox(height: 12),
                    _block(child: Column(children: [
                      if (d.address.isNotEmpty) ...[
                        _infoRow(Icons.place_outlined, 'Адрес', '${d.city}${d.address.isNotEmpty ? ', ${d.address}' : ''}'),
                        const SizedBox(height: 14),
                      ],
                      if (d.seller.isNotEmpty) ...[
                        _infoRow(Icons.storefront_outlined, 'Продавец', d.seller),
                        const SizedBox(height: 14),
                      ],
                      if (d.phone.isNotEmpty) ...[
                        _infoRow(Icons.call_outlined, 'Телефон', d.phone),
                        const SizedBox(height: 14),
                      ],
                      _infoRow(Icons.link, 'Источник', d.source == 'olx' ? 'OLX.uz' : d.source),
                    ])),
                    ..._similar(d),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(color: C.bg, border: Border(top: BorderSide(color: C.border))),
                child: d.phone.isNotEmpty
                    ? Row(children: [
                        Expanded(flex: 3, child: PrimaryButton('Позвонить', icon: Icons.call, onTap: _call)),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: SecondaryButton('Открыть', icon: Icons.open_in_new, onTap: _openSource)),
                      ])
                    : Row(children: [
                        Expanded(flex: 3, child: PrimaryButton('Открыть', icon: Icons.open_in_new, onTap: _openSource)),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: SecondaryButton('В список', icon: Icons.add, onTap: () {
                          DealsStore.I.addWatch(d.title);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Добавлено в список покупок', style: TextStyle(fontFamily: kFont, color: C.text)),
                            backgroundColor: C.card, duration: Duration(seconds: 1)));
                        })),
                      ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  List<Widget> _similar(Deal d) {
    final list = DealsStore.I.byCategory(d.category).where((x) => x.id != d.id).take(10).toList();
    if (list.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      const Text('Похожие скидки', style: T.section),
      const SizedBox(height: 12),
      SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _SimilarCard(deal: list[i]),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _block({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
        child: child,
      );

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
        Icon(icon, size: 20, color: C.textDim),
        const SizedBox(width: 12),
        Text(label, style: T.meta),
        const SizedBox(width: 10),
        Expanded(child: Text(value, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w600, color: C.text))),
      ]);
}

/// Компактная карточка для раздела «Похожие скидки».
class _SimilarCard extends StatelessWidget {
  final Deal deal;
  const _SimilarCard({required this.deal});
  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DealDetailScreen(deal: deal))),
      child: SizedBox(
        width: 130,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ImagePlate(deal: deal, height: 110, radius: 14),
            if (deal.percent != null) Positioned(left: 6, top: 6, child: DiscountBadge(deal.percent!, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          PriceText(deal.newPrice!, size: 15),
          const SizedBox(height: 2),
          Text(deal.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.meta.copyWith(color: C.text, height: 1.2)),
        ]),
      ),
    );
  }
}
