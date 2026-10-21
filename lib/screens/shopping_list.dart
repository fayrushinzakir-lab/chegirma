import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ctrl = TextEditingController();
  bool notify = true;

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  void _add() {
    final q = ctrl.text.trim();
    if (q.isEmpty) return;
    DealsStore.I.addWatch(q);
    ctrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = DealsStore.I;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = store.watchlist;
          final found = <(String, Deal)>[];
          final waiting = <String>[];
          for (final q in items) {
            final m = store.bestMatch(q);
            if (m != null) { found.add((q, m)); } else { waiting.add(q); }
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
            children: [
              const Text('Мой список', style: T.screenTitle),
              const SizedBox(height: 6),
              const Text('Добавьте товары — мы сообщим, когда на них появится скидка',
                  style: TextStyle(fontFamily: kFont, fontSize: 13, color: C.textDim, height: 1.35)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Container(
                  height: 52, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.search), border: Border.all(color: C.border)),
                  child: TextField(
                    controller: ctrl,
                    style: const TextStyle(fontFamily: kFont, color: C.text, fontSize: 15),
                    cursorColor: C.green,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none,
                      hintText: 'Добавить товар…', hintStyle: TextStyle(fontFamily: kFont, color: C.textDim, fontSize: 15)),
                  ),
                )),
                const SizedBox(width: 10),
                PressScale(onTap: _add, child: Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(R.search)),
                  child: const Icon(Symbols.add, color: C.onAccent, size: 26))),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
                child: Row(children: [
                  const Icon(Symbols.notifications_active, size: 20, color: C.green),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Уведомления о скидках', style: TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600))),
                  AppToggle(value: notify, onChanged: (v) => setState(() => notify = v)),
                ]),
              ),
              if (found.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Скидка найдена · ${found.length}', style: T.section),
                ]),
                const SizedBox(height: 12),
                ...found.map((e) => _foundRow(e.$1, e.$2)),
              ],
              if (waiting.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.inactive, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Ждём скидку · ${waiting.length}', style: T.section),
                ]),
                const SizedBox(height: 12),
                ...waiting.map(_waitingRow),
              ],
              if (items.isEmpty) Padding(padding: const EdgeInsets.only(top: 40),
                child: Center(child: Text('Список пуст — добавьте первый товар', style: T.meta))),
            ],
          );
        },
      ),
    );
  }

  Widget _foundRow(String query, Deal d) => PressScale(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealDetailScreen(deal: d))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
          child: Row(children: [
            SizedBox(width: 48, height: 48, child: ImagePlate(deal: d, height: 48, radius: 12)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('«$query»', style: T.meta.copyWith(color: C.green, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.productName),
              const SizedBox(height: 4),
              PriceText(d.newPrice!, size: 15),
            ])),
            const SizedBox(width: 8),
            Column(children: [
              if (d.percent != null) DiscountBadge(d.percent!),
              const SizedBox(height: 6),
              GestureDetector(onTap: () => DealsStore.I.removeWatch(query),
                child: const Icon(Symbols.close, size: 18, color: C.textDim)),
            ]),
          ]),
        ),
      );

  Widget _waitingRow(String name) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: C.border)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: C.raised2, shape: BoxShape.circle),
            child: const Icon(Symbols.schedule, size: 20, color: C.textDim)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            const Text('Следим за ценой', style: T.meta),
          ])),
          GestureDetector(onTap: () => DealsStore.I.removeWatch(name),
            child: const Icon(Symbols.close, size: 18, color: C.textDim)),
        ]),
      );
}
