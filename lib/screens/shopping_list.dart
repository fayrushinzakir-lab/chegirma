import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool notify = true;
  final waiting = ['Кофе Jacobs 190 г', 'Подгузники Huggies 4', 'Шуруповёрт', 'Рис лазер 5 кг'];

  @override
  Widget build(BuildContext context) {
    final found = DealsStore.I.all.where((d) => d.hasDiscount).take(3).toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          const Text('Мой список', style: T.screenTitle),
          const SizedBox(height: 6),
          const Text('Добавьте товары — мы сообщим, когда на них появится скидка',
              style: TextStyle(fontFamily: kFont, fontSize: 13, color: C.textDim, height: 1.35)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Container(
              height: 52, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.search), border: Border.all(color: C.border)),
              child: const Text('Добавить товар…', style: TextStyle(fontFamily: kFont, color: C.textDim, fontSize: 15)),
            )),
            const SizedBox(width: 10),
            PressScale(onTap: () {}, child: Container(width: 52, height: 52,
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(R.search)),
              child: const Icon(Icons.add, color: C.onAccent, size: 26))),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
            child: Row(children: [
              const Icon(Icons.notifications_active_outlined, size: 20, color: C.green),
              const SizedBox(width: 12),
              const Expanded(child: Text('Уведомления о скидках', style: TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600))),
              AppToggle(value: notify, onChanged: (v) => setState(() => notify = v)),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('Скидка найдена', style: T.section),
          ]),
          const SizedBox(height: 12),
          if (found.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Загружаем предложения…', style: T.meta))
          else
            ...found.map(_foundRow),
          const SizedBox(height: 24),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.inactive, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('Ждём скидку', style: T.section),
          ]),
          const SizedBox(height: 12),
          ...waiting.map(_waitingRow),
        ],
      ),
    );
  }

  Widget _foundRow(Deal d) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
        child: Row(children: [
          SizedBox(width: 48, height: 48, child: ImagePlate(deal: d, height: 48, radius: 12)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.productName),
            const SizedBox(height: 4),
            Text(d.store, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.meta),
            const SizedBox(height: 6),
            PriceText(d.newPrice!, size: 15),
          ])),
          const SizedBox(width: 8),
          if (d.percent != null) DiscountBadge(d.percent!),
        ]),
      );

  Widget _waitingRow(String name) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: C.raised2, shape: BoxShape.circle),
            child: const Icon(Icons.schedule, size: 20, color: C.textDim)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            const Text('Следим в 14 магазинах', style: T.meta),
          ])),
          const Icon(Icons.close, size: 18, color: C.textDim),
        ]),
      );
}
