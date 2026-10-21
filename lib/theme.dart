import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chegirma — премиальная чёрная матовая тема (макет v2).
/// Без глянца, без градиентов, без эмодзи. Зелёный бренд, жёлтый «горящие»,
/// красный бейдж скидки. Шрифт Manrope.
class C {
  // Фоны
  static const bg = Color(0xFF0E0E10);       // основной
  static const mapBg = Color(0xFF121215);    // фон карты
  static const card = Color(0xFF161619);     // карточки, поля, кнопки
  static const panel = Color(0xFF1A1A1D);    // панели, плавающее меню
  static const raised2 = Color(0xFF26262A);  // вторичные элементы/кнопки
  static const avatar = Color(0xFF2A2A2F);
  static const inactive = Color(0xFF3A3A40);

  // Границы
  static const border = Color(0xFF222226);   // граница карточек
  static const borderPanel = Color(0xFF2C2C30);

  // Текст
  static const text = Color(0xFFF2F2F0);
  static const textDim = Color(0xFF9A9AA0);
  static const onAccent = Color(0xFF0E0E10);

  // Акценты
  static const green = Color(0xFF3DDC84);
  static const greenPressed = Color(0xFF2BB86C);
  static const yellow = Color(0xFFFFD84D);
  static const yellowDeco = Color(0xFFF5C800);
  static const red = Color(0xFFFF4D3D);       // бейдж скидки
  static const warn = Color(0xFFFF6B5E);      // «осталось мало»
  static const saveBg = Color(0xFF16301F);
  static const saveText = Color(0xFF3DDC84);
  static const userDot = Color(0xFF7CC4FF);

  // Тонированные плитки (фон / иконка)
  static const tFoodBg = Color(0xFF1E2A1B);
  static const tFoodIc = Color(0xFFA8D58A);
  static const tBuildBg = Color(0xFF2E2418);
  static const tBuildIc = Color(0xFFE3B27A);
  static const tTechBg = Color(0xFF1A2433);
  static const tTechIc = Color(0xFF8FB6E8);
  static const tSoftBg = Color(0xFF2E1A26);
  static const tSoftIc = Color(0xFFE59AC4);
}

class R {
  static const card = 20.0;
  static const plate = 15.0;
  static const search = 16.0;
  static const banner = 24.0;
  static const sheet = 24.0;
  static const badge = 8.0;
  static const button = 16.0;
  static const menu = 34.0;
}

const kFont = 'Manrope';

class T {
  static const logo = TextStyle(
      fontFamily: kFont, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: C.text);
  static const screenTitle = TextStyle(
      fontFamily: kFont, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: C.text, height: 1.1);
  static const section = TextStyle(
      fontFamily: kFont, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: C.text);
  static const productName = TextStyle(
      fontFamily: kFont, fontSize: 14, fontWeight: FontWeight.w700, color: C.text, height: 1.2);
  static const priceCard = TextStyle(
      fontFamily: kFont, fontSize: 17, fontWeight: FontWeight.w800, color: C.text);
  static const oldPrice = TextStyle(
      fontFamily: kFont, fontSize: 13, color: C.textDim, decoration: TextDecoration.lineThrough);
  static const meta = TextStyle(fontFamily: kFont, fontSize: 12, color: C.textDim);
  static const navLabel = TextStyle(fontFamily: kFont, fontSize: 11, fontWeight: FontWeight.w600);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark, surface: C.card, primary: C.green,
      secondary: C.yellow, onPrimary: C.onAccent),
    splashColor: Colors.white10,
    highlightColor: Colors.transparent,
    // Единый вес линейных иконок (Material Symbols) — чуть крепче, премиальнее.
    iconTheme: const IconThemeData(weight: 500, grade: 0, opticalSize: 24, color: C.text),
    textTheme: base.textTheme.apply(fontFamily: kFont, bodyColor: C.text, displayColor: C.text),
  );
}

void applySystemChrome() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
}

String groupPrice(int value) {
  final s = value.toString();
  final out = StringBuffer();
  int c = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    out.write(s[i]);
    if (++c % 3 == 0 && i != 0) out.write(' ');
  }
  return out.toString().split('').reversed.join();
}
