/// Ilova bo'yicha umumiy sozlamalar.
///
/// Backend tayyor bo'lgach, [useLocalBackend] false qilinadi va
/// `lib/data/` ichiga HTTP repository qo'shiladi.
class AppConfig {
  AppConfig._();

  /// Ishchi nom. Brend tasdiqlangach almashtiriladi.
  static const appName = 'Usta Bonus';

  /// Hozircha barcha ma'lumotlar telefon xotirasida saqlanadi.
  static const useLocalBackend = true;

  /// Demo rejim: SMS yuborilmaydi, 6 ta bir xil raqam (111111, 222222 ...)
  /// kiritilsa kirish mumkin. Ekranlarda test uchun yordamchi yozuvlar chiqadi.
  static const demoMode = true;

  /// SMS kodni qayta yuborish uchun kutish vaqti.
  static const otpResendSeconds = 60;

  /// Bitta arizaga yuklanadigan foto soni.
  static const minPhotos = 1;
  static const maxPhotos = 3;

  /// Noto'g'ri kod kiritish limiti (1 soat ichida).
  static const maxFailedCodeChecksPerHour = 10;

  /// Qo'llab-quvvatlash kontaktlari (stikerdagi ma'lumotlar, tasdiqlash kerak).
  static const supportPhone = '+998 90 532 88 80';
  static const supportTelegram = '@TT_REWARDS';
}
