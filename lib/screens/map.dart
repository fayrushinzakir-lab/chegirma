import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int? selected;
  int chip = 0;
  static const chips = ['Все · 2 км', 'Продукты', 'Стройка', 'Техника'];
  static const offsets = [
    Offset(0.22, 0.30), Offset(0.62, 0.24), Offset(0.44, 0.46), Offset(0.74, 0.52), Offset(0.30, 0.60),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deals = DealsStore.I.all.where((d) => d.hasDiscount).take(offsets.length).toList();
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _MapPainter())),
      Positioned(
        left: size.width * 0.5 - 11, top: size.height * 0.44 - 11,
        child: Container(width: 22, height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.userDot.withValues(alpha: 0.25)),
          child: Center(child: Container(width: 12, height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: C.userDot, border: Border.all(color: C.bg, width: 2)))))),
      for (int i = 0; i < deals.length; i++)
        Positioned(
          left: size.width * offsets[i].dx, top: size.height * offsets[i].dy,
          child: MapMarker(store: deals[i].store, percent: deals[i].percent ?? 0, selected: selected == i,
              onTap: () => setState(() => selected = i)),
        ),
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(children: [
          Row(children: [
            IconCircleButton(Icons.arrow_back, bg: C.panel, onTap: () {}),
            const SizedBox(width: 10),
            const Expanded(child: SearchBarField(hint: 'Скидки рядом', showFilter: false)),
          ]),
          const SizedBox(height: 12),
          SizedBox(height: 38, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChipFilter(chips[i], active: chip == i, onTap: () => setState(() => chip = i)),
          )),
        ]),
      )),
      if (selected != null && selected! < deals.length) _selectedCard(deals[selected!]),
    ]);
  }

  Widget _selectedCard(Deal d) => Positioned(
      left: 20, right: 20, bottom: 110,
      child: PressScale(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealDetailScreen(deal: d))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.panel, borderRadius: BorderRadius.circular(R.card),
              border: Border.all(color: C.borderPanel),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(children: [
            Stack(children: [
              SizedBox(width: 62, height: 62, child: ImagePlate(deal: d, height: 62, radius: 14)),
              if (d.percent != null) Positioned(left: 4, top: 4, child: DiscountBadge(d.percent!, fontSize: 11)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.store, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w700, color: C.textDim)),
              const SizedBox(height: 2),
              Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.productName),
              const SizedBox(height: 6),
              PriceText(d.newPrice!, size: 16),
            ])),
            const SizedBox(width: 8),
            Container(width: 48, height: 48,
              decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
              child: const Icon(Icons.near_me, color: C.onAccent, size: 22)),
          ]),
        ),
      ));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = C.mapBg);
    final park = Paint()..color = const Color(0xFF16231A);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.05, s.height * 0.5, s.width * 0.3, s.height * 0.18), const Radius.circular(20)), park);
    canvas.drawCircle(Offset(s.width * 0.8, s.height * 0.72), s.width * 0.16, park);
    final river = Paint()..color = const Color(0xFF14202E)..style = PaintingStyle.stroke..strokeWidth = 26..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(s.width * 0.1, 0)
      ..cubicTo(s.width * 0.35, s.height * 0.25, s.width * 0.15, s.height * 0.5, s.width * 0.45, s.height * 0.8)
      ..lineTo(s.width * 0.6, s.height);
    canvas.drawPath(path, river);
    final road = Paint()..color = const Color(0xFF26262B)..strokeWidth = 7..strokeCap = StrokeCap.round;
    for (double y = 0.15; y < 1; y += 0.22) {
      canvas.drawLine(Offset(0, s.height * y), Offset(s.width, s.height * (y + 0.05)), road);
    }
    for (double x = 0.2; x < 1; x += 0.25) {
      canvas.drawLine(Offset(s.width * x, 0), Offset(s.width * (x - 0.05), s.height), road);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
