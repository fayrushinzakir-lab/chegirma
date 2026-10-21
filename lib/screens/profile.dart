import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../auth.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int lang = 2;
  bool notifDeals = true, notifHot = true;
  static const langs = ["O‘zbekcha", "Ўзбекча", "Русский"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(children: [
              IconCircleButton(Symbols.arrow_back, onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              const Text('Профиль', style: T.screenTitle),
            ]),
            const SizedBox(height: 20),
            PressScale(
              onTap: _openLogin,
              child: Row(children: [
                Container(width: 64, height: 64,
                  decoration: const BoxDecoration(color: C.avatar, shape: BoxShape.circle),
                  child: Icon(AppAuth.I.isLoggedIn ? Symbols.verified_user : Symbols.person_outline, size: 30,
                      color: AppAuth.I.isLoggedIn ? C.green : C.text)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AppAuth.I.isLoggedIn ? (AppAuth.I.name?.isNotEmpty == true ? AppAuth.I.name! : 'Вы вошли')
                        : 'Гость',
                      style: const TextStyle(fontFamily: kFont, fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  if (AppAuth.I.isLoggedIn)
                    Text(AppAuth.I.phone ?? '', style: const TextStyle(fontFamily: kFont, fontSize: 13, color: C.textDim, fontWeight: FontWeight.w600))
                  else
                    Row(children: const [
                      Text('Войти через Telegram', style: TextStyle(fontFamily: kFont, fontSize: 13, color: C.green, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Symbols.chevron_right, size: 16, color: C.green),
                    ]),
                ])),
                if (AppAuth.I.isLoggedIn)
                  GestureDetector(onTap: () { AppAuth.I.logout(); setState(() {}); },
                    child: const Icon(Symbols.logout, size: 20, color: C.textDim)),
              ]),
            ),
            const SizedBox(height: 24),
            _label('Город'),
            _tile(Symbols.location_city, DealsStore.I.selectedCity ?? 'Все города Узбекистана',
                onTap: _citySheet, trailing: const Icon(Symbols.chevron_right, color: C.textDim)),
            const SizedBox(height: 20),
            _label('Язык'),
            Row(children: List.generate(langs.length, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < langs.length - 1 ? 8 : 0),
                child: PressScale(
                  onTap: () => setState(() => lang = i),
                  child: Container(
                    height: 46, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: lang == i ? C.text : C.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: lang == i ? C.text : C.border)),
                    child: Text(langs[i], style: TextStyle(fontFamily: kFont, fontSize: 13,
                        fontWeight: FontWeight.w700, color: lang == i ? C.onAccent : C.textDim)),
                  ),
                ),
              ),
            ))),
            const SizedBox(height: 20),
            _label('Любимые категории'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in categories.take(6))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: C.border)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(c.icon, size: 15, color: tintIc(c.tint)),
                    const SizedBox(width: 6),
                    Text(c.name, style: const TextStyle(fontFamily: kFont, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ]),
            const SizedBox(height: 20),
            _label('Уведомления'),
            Container(
              decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card),
                  border: Border.all(color: C.border)),
              child: Column(children: [
                _switchRow('Скидки на мои товары', notifDeals, (v) => setState(() => notifDeals = v)),
                const Divider(height: 1, color: C.border, indent: 16, endIndent: 16),
                _switchRow('Горящие скидки рядом', notifHot, (v) => setState(() => notifHot = v)),
              ]),
            ),
            const SizedBox(height: 24),
            Center(child: Text('chegirmalar.uz · v0.3',
                style: T.meta.copyWith(fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t, style: T.meta.copyWith(fontWeight: FontWeight.w700, fontSize: 13)));

  Widget _tile(IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) => PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card),
              border: Border.all(color: C.border)),
          child: Row(children: [
            Icon(icon, size: 20, color: C.textDim),
            const SizedBox(width: 12),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600))),
            if (trailing != null) trailing,
          ]),
        ),
      );

  void _citySheet() {
    final store = DealsStore.I;
    showModalBottomSheet(
      context: context, backgroundColor: C.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: C.raised2, borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(alignment: Alignment.centerLeft, child: Text('Выберите город', style: T.section))),
        Flexible(child: ListView(shrinkWrap: true, children: [
          for (final c in <String?>[null, ...store.cities])
            ListTile(
              onTap: () { store.setCity(c); Navigator.pop(context); setState(() {}); },
              leading: Icon(store.selectedCity == c ? Symbols.radio_button_checked : Symbols.radio_button_unchecked,
                  color: store.selectedCity == c ? C.green : C.textDim, size: 22),
              title: Text(c ?? 'Все города Узбекистана',
                  style: TextStyle(fontFamily: kFont, fontSize: 15, color: store.selectedCity == c ? C.text : C.textDim,
                      fontWeight: store.selectedCity == c ? FontWeight.w700 : FontWeight.w500)),
            ),
        ])),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _openLogin() async {
    if (AppAuth.I.isLoggedIn) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (mounted) setState(() {});
  }

  Widget _switchRow(String title, bool v, ValueChanged<bool> onCh) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600))),
          AppToggle(value: v, onChanged: onCh),
        ]),
      );
}
