import 'i18n.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// 12.03.2026
String formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

/// 12.03.2026, 14:05
String formatDateTime(DateTime d) =>
    '${formatDate(d)}, ${_two(d.hour)}:${_two(d.minute)}';

/// 1234567 -> "1 234 567"
String formatNumber(int n) {
  final negative = n < 0;
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buf.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(' ');
  }
  return negative ? '-$buf' : buf.toString();
}

/// "1 160 ball" / "1 160 баллов" / "1 160 балл" (kirill)
String formatPoints(AppLang lang, int n) {
  final value = formatNumber(n);
  switch (lang) {
    case AppLang.uzLatn:
      return '$value ball';
    case AppLang.uzCyrl:
      return '$value балл';
    case AppLang.ru:
      return '$value ${_ruPlural(n.abs(), 'балл', 'балла', 'баллов')}';
  }
}

/// Faqat so'z: "ball" / "баллов"
String pointsWord(AppLang lang, int n) {
  switch (lang) {
    case AppLang.uzLatn:
      return 'ball';
    case AppLang.uzCyrl:
      return 'балл';
    case AppLang.ru:
      return _ruPlural(n.abs(), 'балл', 'балла', 'баллов');
  }
}

String _ruPlural(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

/// 901234567 -> "+998 90 123 45 67"
String formatPhone(String digits9) {
  final d = digits9.replaceAll(RegExp(r'\D'), '');
  if (d.length != 9) return '+998 $d';
  return '+998 ${d.substring(0, 2)} ${d.substring(2, 5)} '
      '${d.substring(5, 7)} ${d.substring(7, 9)}';
}
