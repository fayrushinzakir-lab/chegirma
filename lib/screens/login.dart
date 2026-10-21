import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth.dart';
import '../theme.dart';
import '../ui_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool waiting = false;
  String? error;
  Timer? poller;

  @override
  void dispose() { poller?.cancel(); super.dispose(); }

  Future<void> _login() async {
    setState(() { error = null; });
    if (!AppAuth.I.configured) {
      setState(() => error = 'Вход скоро подключим — бэкенд в процессе развёртывания.');
      return;
    }
    setState(() => waiting = true);
    final s = await AppAuth.I.start();
    if (s == null) {
      setState(() { waiting = false; error = 'Не удалось начать вход. Попробуйте позже.'; });
      return;
    }
    final uri = Uri.parse(s.botUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    // поллинг статуса
    poller = Timer.periodic(const Duration(seconds: 2), (t) async {
      final ok = await AppAuth.I.poll(s.nonce);
      if (ok && mounted) { t.cancel(); Navigator.of(context).pop(true); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft,
              child: IconCircleButton(Symbols.arrow_back, onTap: () => Navigator.of(context).pop())),
            const Spacer(),
            Container(width: 88, height: 88,
              decoration: BoxDecoration(color: const Color(0xFF229ED9).withValues(alpha: 0.16), shape: BoxShape.circle),
              child: const Icon(Icons.telegram, color: Color(0xFF229ED9), size: 46)),
            const SizedBox(height: 24),
            const Text('Вход через Telegram', textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kFont, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text('Быстрый вход по номеру телефона — бесплатно, без SMS. Откроется бот, нажмите «Поделиться номером».',
                textAlign: TextAlign.center, style: TextStyle(fontFamily: kFont, fontSize: 15, color: C.textDim, height: 1.5)),
            const SizedBox(height: 32),
            if (waiting) ...[
              const CircularProgressIndicator(color: C.green),
              const SizedBox(height: 16),
              const Text('Ожидаем подтверждение в Telegram…', style: TextStyle(fontFamily: kFont, color: C.textDim, fontSize: 14)),
            ] else
              PrimaryButton('Войти через Telegram', icon: Icons.telegram, onTap: _login),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: kFont, color: C.warn, fontSize: 13)),
            ],
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }
}
