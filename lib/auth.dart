import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Вход через Telegram-бота. URL бэкенда (Deno Deploy) задаётся после деплоя.
/// Можно переопределить при сборке: --dart-define=AUTH_URL=https://...
const kAuthBaseUrl = String.fromEnvironment('AUTH_URL', defaultValue: '');

class AppAuth extends ChangeNotifier {
  AppAuth._();
  static final AppAuth I = AppAuth._();

  String? token;
  String? phone;
  String? name;
  bool get isLoggedIn => token != null;
  bool get configured => kAuthBaseUrl.isNotEmpty;

  /// Старт входа → (nonce, ссылка на бота).
  Future<({String nonce, String botUrl})?> start() async {
    if (!configured) return null;
    try {
      final r = await http.post(Uri.parse('$kAuthBaseUrl/auth/start')).timeout(const Duration(seconds: 15));
      final d = json.decode(r.body) as Map<String, dynamic>;
      return (nonce: d['nonce'] as String, botUrl: d['botUrl'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Проверка статуса входа. true — вошли.
  Future<bool> poll(String nonce) async {
    if (!configured) return false;
    try {
      final r = await http.get(Uri.parse('$kAuthBaseUrl/auth/status?nonce=$nonce')).timeout(const Duration(seconds: 12));
      final d = json.decode(r.body) as Map<String, dynamic>;
      if (d['status'] == 'authorized') {
        token = d['token'] as String?;
        phone = d['phone'] as String?;
        name = d['name'] as String?;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void logout() {
    token = null; phone = null; name = null;
    notifyListeners();
  }
}
