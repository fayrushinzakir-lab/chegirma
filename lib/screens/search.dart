import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../persist.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'deal_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ctrl = TextEditingController();
  String q = '';
  String? cat;
  List<String> recent = Persist.getList('recent');
  static const suggestions = ['iPhone', 'Цемент', 'Диван', 'Куртка', 'Телевизор', 'Масло', 'Кроссовки', 'Холодильник'];

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  void _saveRecent(String query) {
    final s = query.trim();
    if (s.length < 2) return;
    recent.removeWhere((x) => x.toLowerCase() == s.toLowerCase());
    recent.insert(0, s);
    if (recent.length > 8) recent = recent.sublist(0, 8);
    Persist.set('recent', recent);
  }

  List<Deal> get results {
    var list = q.trim().isEmpty ? <Deal>[] : DealsStore.I.search(q);
    if (cat != null) list = list.where((d) => d.category == cat).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final res = results;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              IconCircleButton(Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 10),
              Expanded(child: Container(
                height: 50, padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.search), border: Border.all(color: C.border)),
                child: Row(children: [
                  const Icon(Icons.search, color: C.textDim, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: ctrl, autofocus: true,
                    style: const TextStyle(fontFamily: kFont, color: C.text, fontSize: 15),
                    cursorColor: C.green,
                    decoration: const InputDecoration(
                      isCollapsed: true, border: InputBorder.none,
                      hintText: 'Масло, цемент, iPhone…',
                      hintStyle: TextStyle(fontFamily: kFont, color: C.textDim, fontSize: 15)),
                    onChanged: (v) => setState(() => q = v),
                  )),
                  if (q.isNotEmpty) GestureDetector(
                    onTap: () => setState(() { q = ''; ctrl.clear(); }),
                    child: const Icon(Icons.close, color: C.textDim, size: 20)),
                ]),
              )),
            ]),
          ),
          if (q.trim().isEmpty)
            Expanded(child: _suggestionsView())
          else ...[
            SizedBox(height: 38, child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChipFilter('Все', active: cat == null, onTap: () => setState(() => cat = null)),
                for (final c in categories.where((c) => c.id != 'other')) ...[
                  const SizedBox(width: 8),
                  ChipFilter(c.name, active: cat == c.id, onTap: () => setState(() => cat = c.id)),
                ],
              ],
            )),
            const SizedBox(height: 10),
            Expanded(child: res.isEmpty
                ? Center(child: Text('Ничего не найдено по «$q»', style: T.meta))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.58),
                    itemCount: res.length,
                    itemBuilder: (_, i) => DealCard(
                      deal: res[i],
                      onTap: () { _saveRecent(q); Navigator.of(context).push(MaterialPageRoute(builder: (_) => DealDetailScreen(deal: res[i]))); },
                      onFav: () => setState(() => DealsStore.I.toggleFav(res[i])),
                    ),
                  )),
          ],
        ]),
      ),
    );
  }

  Widget _suggestionsView() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          if (recent.isNotEmpty) ...[
            Row(children: [
              Text('Недавние', style: T.meta.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(onTap: () { setState(() => recent = []); Persist.set('recent', <String>[]); },
                child: Text('Очистить', style: T.meta.copyWith(color: C.green, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final s in recent) _chip(s, Icons.history)]),
            const SizedBox(height: 24),
          ],
          Text('Популярные запросы', style: T.meta.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final s in suggestions) _chip(s, Icons.trending_up)]),
        ],
      );

  Widget _chip(String s, IconData icon) => PressScale(
        onTap: () => setState(() { q = s; ctrl.text = s; ctrl.selection = TextSelection.collapsed(offset: s.length); }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: C.textDim),
            const SizedBox(width: 6),
            Text(s, style: const TextStyle(fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
