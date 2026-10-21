import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'models.dart';
import 'theme.dart';

/// Нажатие → уменьшение до 0.97.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScale({super.key, required this.child, this.onTap});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  double s = 1;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => s = 0.97),
        onTapCancel: () => setState(() => s = 1),
        onTapUp: (_) => setState(() => s = 1),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: s, duration: const Duration(milliseconds: 110), curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

class DiscountBadge extends StatelessWidget {
  final int percent;
  final double fontSize;
  const DiscountBadge(this.percent, {super.key, this.fontSize = 13});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.55, vertical: fontSize * 0.3),
        decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(R.badge)),
        child: Text('−$percent%',
            style: TextStyle(
                fontFamily: kFont, color: Colors.white, fontSize: fontSize,
                fontWeight: FontWeight.w800, height: 1)),
      );
}

/// Цена: число жирно + «сум» мельче и серым.
class PriceText extends StatelessWidget {
  final int value;
  final double size;
  const PriceText(this.value, {super.key, this.size = 17});
  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(children: [
          TextSpan(
              text: groupPrice(value),
              style: TextStyle(fontFamily: kFont, fontSize: size, fontWeight: FontWeight.w800, color: C.text)),
          TextSpan(
              text: ' сум',
              style: TextStyle(fontFamily: kFont, fontSize: size * 0.6, fontWeight: FontWeight.w700, color: C.textDim)),
        ]),
      );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const PrimaryButton(this.label, {super.key, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          height: 54, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.green, borderRadius: BorderRadius.circular(R.button),
            boxShadow: [BoxShadow(color: C.green.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, color: C.onAccent, size: 20, weight: 700, fill: 1), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontFamily: kFont, color: C.onAccent, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ]),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const SecondaryButton(this.label, {super.key, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          height: 54, alignment: Alignment.center,
          decoration: BoxDecoration(color: C.raised2, borderRadius: BorderRadius.circular(R.button),
              border: Border.all(color: C.borderPanel)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, color: C.text, size: 20, weight: 600), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontFamily: kFont, color: C.text, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? bg;
  final double size;
  const IconCircleButton(this.icon, {super.key, this.onTap, this.iconColor, this.bg, this.size = 44});
  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(color: bg ?? C.card, shape: BoxShape.circle,
              border: Border.all(color: C.border)),
          child: Icon(icon, color: iconColor ?? C.text, size: size * 0.5),
        ),
      );
}

class SearchBarField extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final bool showFilter;
  const SearchBarField({super.key, this.hint = 'Масло, цемент, iPhone…', this.onTap, this.showFilter = true});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: PressScale(
            onTap: onTap,
            child: Container(
              height: 54, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.search),
                  border: Border.all(color: C.border)),
              child: Row(children: [
                Container(width: 30, height: 30, alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.raised2, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Symbols.search, color: C.text, size: 18, weight: 600)),
                const SizedBox(width: 10),
                Expanded(child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: kFont, color: C.textDim, fontSize: 15))),
              ]),
            ),
          ),
        ),
        if (showFilter) ...[
          const SizedBox(width: 10),
          PressScale(
            onTap: onTap,
            child: Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(R.search)),
              child: const Icon(Symbols.tune, color: C.onAccent, size: 22, weight: 600),
            ),
          ),
        ],
      ]);
}

class ChipFilter extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ChipFilter(this.label, {super.key, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? C.text : C.card,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: active ? C.text : C.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: kFont, color: active ? C.onAccent : C.textDim,
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );
}

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppToggle({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 52, height: 32, padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(color: value ? C.green : C.inactive, borderRadius: BorderRadius.circular(16)),
          child: Container(width: 26, height: 26, decoration: const BoxDecoration(color: C.text, shape: BoxShape.circle)),
        ),
      );
}

class DealProgress extends StatelessWidget {
  final double value;
  const DealProgress(this.value, {super.key});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1), minHeight: 6,
          backgroundColor: C.borderPanel, valueColor: const AlwaysStoppedAnimation(C.green)),
      );
}

class SavingsPill extends StatelessWidget {
  final int amount;
  const SavingsPill(this.amount, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: C.saveBg, borderRadius: BorderRadius.circular(10)),
        child: Text('Экономия ${groupPrice(amount)}',
            style: const TextStyle(fontFamily: kFont, color: C.saveText, fontSize: 13, fontWeight: FontWeight.w700)),
      );
}

class TintedPlate extends StatelessWidget {
  final Tint tint;
  final IconData icon;
  final double size, radius;
  const TintedPlate({super.key, required this.tint, required this.icon, this.size = 52, this.radius = 14});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: tintBg(tint), borderRadius: BorderRadius.circular(radius)),
        child: Icon(icon, color: tintIc(tint), size: size * 0.46),
      );
}

/// Круглый аватар-буква магазина.
class StoreAvatar extends StatelessWidget {
  final String name;
  final double size;
  const StoreAvatar(this.name, {super.key, this.size = 20});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size, alignment: Alignment.center,
        decoration: const BoxDecoration(color: C.avatar, shape: BoxShape.circle),
        child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: TextStyle(fontFamily: kFont, fontSize: size * 0.5, fontWeight: FontWeight.w800, color: C.text)),
      );
}

/// Плашка срока «2 дня» (красная при малом сроке).
class ValidityPill extends StatelessWidget {
  final int days;
  const ValidityPill(this.days, {super.key});
  @override
  Widget build(BuildContext context) {
    final soon = days <= 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: C.bg.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Symbols.schedule, size: 12, color: soon ? C.warn : C.textDim),
        const SizedBox(width: 4),
        Text(days <= 0 ? 'сегодня' : '$days дн.',
            style: TextStyle(fontFamily: kFont, fontSize: 11, fontWeight: FontWeight.w700, color: soon ? C.warn : C.text)),
      ]),
    );
  }
}

/// Сердце с «пульсом» при заливке.
class HeartButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;
  const HeartButton({super.key, required this.value, required this.onChanged, this.size = 34});
  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final Animation<double> scale =
      TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () { widget.onChanged(!widget.value); if (!widget.value) c.forward(from: 0); },
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(color: C.bg.withValues(alpha: 0.55), shape: BoxShape.circle),
          child: ScaleTransition(
            scale: scale,
            child: Icon(widget.value ? Symbols.favorite : Symbols.favorite_border,
                color: widget.value ? C.red : C.text, size: widget.size * 0.5),
          ),
        ),
      );
}

class Skeleton extends StatefulWidget {
  final double w, h, r;
  const Skeleton(this.w, this.h, {super.key, this.r = 12});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.4, end: 0.85).animate(c),
        child: Container(width: widget.w, height: widget.h,
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(widget.r))),
      );
}

/// Точки карусели (активная — вытянутая).
class CarouselDots extends StatelessWidget {
  final int count, active;
  const CarouselDots({super.key, required this.count, required this.active});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final on = i == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 18 : 6, height: 6,
            decoration: BoxDecoration(color: on ? C.text : C.inactive, borderRadius: BorderRadius.circular(3)),
          );
        }),
      );
}

/// Мини-график истории цены. Текущий столбец зелёный.
class PriceHistoryChart extends StatelessWidget {
  final List<int> data;
  const PriceHistoryChart(this.data, {super.key});
  static const months = ['Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт'];
  @override
  Widget build(BuildContext context) {
    final maxV = data.reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 96,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(data.length, (i) {
        final last = i == data.length - 1;
        return Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Container(
              height: 20 + (data[i] / maxV) * 54,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(color: last ? C.green : C.raised2, borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(height: 6),
            Text(months[i % 6],
                style: TextStyle(fontFamily: kFont, fontSize: 10,
                    color: last ? C.green : C.textDim, fontWeight: last ? FontWeight.w700 : FontWeight.w400)),
          ]),
        );
      })),
    );
  }
}

/// Реальное фото товара с фолбэком на тонированную иконку.
class ImagePlate extends StatelessWidget {
  final Deal deal;
  final double height;
  final double radius;
  const ImagePlate({super.key, required this.deal, required this.height, this.radius = R.plate});
  @override
  Widget build(BuildContext context) {
    final cat = catOf(deal.category);
    final fallback = Container(
      color: tintBg(cat.tint),
      child: Icon(cat.icon, color: tintIc(cat.tint), size: height * 0.38),
    );
    final child = deal.imageUrl.isEmpty
        ? fallback
        : Image.network(
            deal.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity, height: height,
            errorBuilder: (_, __, ___) => fallback,
            loadingBuilder: (_, w, p) => p == null ? w : Container(color: tintBg(cat.tint)),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: double.infinity, height: height, child: child),
    );
  }
}

/// Карточка товара (сетка 2 колонки).
class DealCard extends StatelessWidget {
  final Deal deal;
  final VoidCallback onTap;
  final VoidCallback onFav;
  const DealCard({super.key, required this.deal, required this.onTap, required this.onFav});
  @override
  Widget build(BuildContext context) {
    final days = deal.daysLeft;
    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card),
            border: Border.all(color: C.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Stack(children: [
                ImagePlate(deal: deal, height: 140),
                if (deal.percent != null) Positioned(left: 8, top: 8, child: DiscountBadge(deal.percent!)),
                Positioned(right: 6, top: 6, child: HeartButton(value: deal.favorite, size: 32, onChanged: (_) => onFav())),
                if (days != null) Positioned(left: 8, bottom: 8, child: ValidityPill(days)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  PriceText(deal.newPrice!),
                  if (deal.oldPrice != null) ...[
                    const SizedBox(width: 6),
                    Flexible(child: Text('${groupPrice(deal.oldPrice!)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.oldPrice)),
                  ],
                ]),
                const SizedBox(height: 3),
                if (deal.savings != null)
                  Text('выгода ${groupPrice(deal.savings!)}',
                      style: const TextStyle(fontFamily: kFont, fontSize: 11, fontWeight: FontWeight.w700, color: C.saveText))
                else
                  const SizedBox(height: 14),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: Text(deal.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.productName),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  StoreAvatar(deal.store, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(deal.store, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: T.meta.copyWith(fontWeight: FontWeight.w600))),
                  if (deal.city.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(deal.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.meta),
                  ],
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка событийной акции (Чёрная пятница, 8 Марта…).
class EventCard extends StatelessWidget {
  final PromoEvent event;
  final int dealsCount;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap, this.dealsCount = 0});
  @override
  Widget build(BuildContext context) {
    final c = event.color;
    return PressScale(
      onTap: onTap,
      child: Container(
        width: 280, height: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(R.card),
          border: Border.all(color: c.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [c.withValues(alpha: 0.14), C.card, C.card]),
        ),
        child: Stack(children: [
          Positioned(right: -24, top: -24, child: Container(width: 90, height: 90,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.10)))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                child: Icon(event.icon, color: c, size: 24)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Symbols.schedule, size: 12, color: c),
                  const SizedBox(width: 4),
                  Text(event.whenText, style: TextStyle(fontFamily: kFont, fontSize: 12, fontWeight: FontWeight.w800, color: c)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: kFont, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 3),
            Expanded(child: Text(event.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.meta.copyWith(height: 1.3))),
            Row(children: [
              Text(dealsCount > 0 ? 'Смотреть $dealsCount скидок' : 'Смотреть скидки',
                  style: TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w800, color: c)),
              const SizedBox(width: 4),
              Icon(Symbols.arrow_forward, size: 15, color: c),
            ]),
          ]),
        ]),
      ),
    );
  }
}

/// Метка магазина на карте.
class MapMarker extends StatelessWidget {
  final String store;
  final int percent;
  final bool selected;
  final VoidCallback onTap;
  const MapMarker({super.key, required this.store, required this.percent, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.15 : 1,
          duration: const Duration(milliseconds: 180),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              height: 36, padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: selected ? C.green : C.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? Colors.white : C.borderPanel, width: selected ? 2 : 1),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                StoreAvatar(store, size: 26),
                const SizedBox(width: 4),
                Text('−$percent%',
                    style: TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w800,
                        color: selected ? C.onAccent : C.red)),
                const SizedBox(width: 5),
              ]),
            ),
            // «хвостик» пина
            Transform.translate(
              offset: const Offset(0, -3),
              child: Transform.rotate(angle: 0.785, child: Container(width: 8, height: 8,
                decoration: BoxDecoration(color: selected ? C.green : C.panel,
                  border: Border(right: BorderSide(color: selected ? Colors.white : C.borderPanel, width: selected ? 2 : 1),
                                 bottom: BorderSide(color: selected ? Colors.white : C.borderPanel, width: selected ? 2 : 1))))),
            ),
          ]),
        ),
      );
}
