import 'package:flutter_test/flutter_test.dart';
import 'package:usta_bonus/core/format.dart';
import 'package:usta_bonus/core/i18n.dart';
import 'package:usta_bonus/core/qr_parser.dart';

void main() {
  group('QrParser', () {
    test('toza kod', () {
      expect(QrParser.extractCode('gpyn166n'), 'gpyn166n');
    });

    test('katta harf va bo\'shliqlar normallashtiriladi', () {
      expect(QrParser.extractCode('  3T3rytcx '), '3t3rytcx');
    });

    test('havola ichidagi kod', () {
      expect(QrParser.extractCode('https://example.uz/c/gpyn166n'), 'gpyn166n');
      expect(QrParser.extractCode('https://example.uz/check?code=gpyn166n'), 'gpyn166n');
    });

    test('noto\'g\'ri format', () {
      expect(QrParser.extractCode('abc'), isNull);
      expect(QrParser.extractCode(''), isNull);
    });
  });

  group('Kirill transliteratsiyasi', () {
    test('asosiy qoidalar', () {
      expect(toCyrillic("O'rnating"), 'Ўрнатинг');
      expect(toCyrillic("yo'q"), 'йўқ');
      expect(toCyrillic("Ma'lumot"), 'Маълумот');
      expect(toCyrillic('Eslatma'), 'Эслатма');
    });

    test('himoyalangan so\'zlar o\'zgarmaydi', () {
      expect(toCyrillic('QR-kod'), 'QR-код');
      expect(toCyrillic('{phone} raqami'), '{phone} рақами');
    });
  });

  group('Format', () {
    test('raqamlar', () {
      expect(formatNumber(1160), '1 160');
      expect(formatNumber(20), '20');
    });

    test('ruscha ko\'plik', () {
      expect(formatPoints(AppLang.ru, 1), '1 балл');
      expect(formatPoints(AppLang.ru, 22), '22 балла');
      expect(formatPoints(AppLang.ru, 40), '40 баллов');
    });

    test('telefon', () {
      expect(formatPhone('901234567'), '+998 90 123 45 67');
    });
  });
}
