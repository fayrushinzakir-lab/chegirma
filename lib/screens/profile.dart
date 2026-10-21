import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_kit.dart';

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
              IconCircleButton(Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              const Text('Профиль', style: T.screenTitle),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 64, height: 64,
                decoration: const BoxDecoration(color: C.avatar, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, size: 30, color: C.text)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Гость', style: TextStyle(fontFamily: kFont, fontSize: 19, fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text('Войти через Telegram', style: TextStyle(fontFamily: kFont, fontSize: 13, color: C.green, fontWeight: FontWeight.w600)),
              ]),
            ]),
            const SizedBox(height: 24),
            _label('Город'),
            _tile(Icons.location_city_outlined, 'Ташкент, Юнусабад', trailing: const Icon(Icons.chevron_right, color: C.textDim)),
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
            Center(child: Text('Chegirma · v0.2 · прототип',
                style: T.meta.copyWith(fontSize: 11))),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t, style: T.meta.copyWith(fontWeight: FontWeight.w700, fontSize: 13)));

  Widget _tile(IconData icon, String title, {Widget? trailing}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.card),
            border: Border.all(color: C.border)),
        child: Row(children: [
          Icon(icon, size: 20, color: C.textDim),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600))),
          if (trailing != null) trailing,
        ]),
      );

  Widget _switchRow(String title, bool v, ValueChanged<bool> onCh) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontFamily: kFont, fontSize: 15, fontWeight: FontWeight.w600))),
          AppToggle(value: v, onChanged: onCh),
        ]),
      );
}
