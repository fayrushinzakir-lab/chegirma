import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chegirma — чёрная матовая тема.
/// Матовость достигается flat-поверхностями без градиентов,
/// тонкими hairline-границами и слоистыми оттенками почти-чёрного.
class AppColors {
  // Фон и поверхности (матовый чёрный → слегка светлее для слоёв)
  static const bg = Color(0xFF0B0B0D);
  static const surface = Color(0xFF151518);
  static const surfaceHigh = Color(0xFF1E1E22);

  // Текст — через непрозрачность белого для иерархии
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xB3FFFFFF); // 70%
  static const textTertiary = Color(0x66FFFFFF); // 40%

  // Hairline-границы — матовая глубина без теней
  static const border = Color(0x14FFFFFF); // 8%
  static const borderStrong = Color(0x24FFFFFF); // 14%

  // Акцент — красный скидки (используем экономно, только на цене/%)
  static const accent = Color(0xFFFF453A);
  static const accentSoft = Color(0x1AFF453A); // 10%

  // Вторичные смысловые цвета
  static const green = Color(0xFF32D74B);
}

class AppRadius {
  static const card = 20.0;
  static const chip = 14.0;
  static const badge = 10.0;
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      surface: AppColors.surface,
      primary: AppColors.accent,
      secondary: AppColors.accent,
    ),
    splashColor: Colors.white10,
    highlightColor: Colors.white10,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
  );
}

/// Делает системные бары прозрачными/тёмными под матовый фон.
void applySystemChrome() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

/// Формат цены: 125000 → "125 000 сум"
String formatUzs(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count % 3 == 0 && i != 0) buf.write(' ');
  }
  final grouped = buf.toString().split('').reversed.join();
  return '$grouped сум';
}
