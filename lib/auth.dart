import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'persist.dart';

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

  void restore() {
    token = Persist.get<String>('authToken');
    phone = Persist.get<String>('authPhone');
    name = Persist.get<String>('authName');
  }

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
        Persist.set('authToken', token);
        Persist.set('authPhone', phone);
        Persist.set('authName', name);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void logout() {
    token = null; phone = null; name = null;
    Persist.set('authToken', null);
    Persist.set('authPhone', null);
    Persist.set('authName', null);
    notifyListeners();
  }
}
