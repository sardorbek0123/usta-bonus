import 'package:flutter/widgets.dart';

/// Ilova tillari. O'zbek kirill matnlari lotin matnidan avtomatik
/// transliteratsiya qilinadi, shuning uchun alohida tarjima shart emas.
enum AppLang {
  uzLatn('uz', "O'zbekcha", 'Lotin'),
  uzCyrl('uz_cyrl', 'Ўзбекча', 'Кирилл'),
  ru('ru', 'Русский', '');

  const AppLang(this.code, this.label, this.subLabel);
  final String code;
  final String label;
  final String subLabel;

  static AppLang fromCode(String? code) {
    for (final l in AppLang.values) {
      if (l.code == code) return l;
    }
    return AppLang.uzLatn;
  }
}

/// Ikki tilli matn: o'zbekcha (lotin) va ruscha.
class LocalizedText {
  const LocalizedText(this.uz, this.ru);
  final String uz;
  final String ru;

  String of(AppLang lang) {
    switch (lang) {
      case AppLang.uzLatn:
        return uz;
      case AppLang.uzCyrl:
        return toCyrillic(uz);
      case AppLang.ru:
        return ru;
    }
  }

  Map<String, dynamic> toJson() => {'uz': uz, 'ru': ru};

  factory LocalizedText.fromJson(Map<String, dynamic> j) =>
      LocalizedText(j['uz'] as String? ?? '', j['ru'] as String? ?? '');
}

/// Joriy tilni widget daraxtiga uzatadi.
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});

  final AppLang lang;

  static AppLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ??
      AppLang.uzLatn;

  @override
  bool updateShouldNotify(LangScope oldWidget) => oldWidget.lang != lang;
}

extension TrContext on BuildContext {
  AppLang get lang => LangScope.of(this);

  /// Kalit bo'yicha tarjima. `{name}` kabi joylar [args] bilan to'ldiriladi.
  String tr(String key, [Map<String, Object?> args = const {}]) =>
      translate(lang, key, args);

  String loc(LocalizedText text) => text.of(lang);
}

String translate(AppLang lang, String key,
    [Map<String, Object?> args = const {}]) {
  final entry = kStrings[key];
  var s = entry == null ? key : entry.of(lang);
  args.forEach((k, v) => s = s.replaceAll('{$k}', '${v ?? ''}'));
  return s;
}

// ---------------------------------------------------------------------------
// Lotin -> kirill transliteratsiyasi (o'zbek tili)
// ---------------------------------------------------------------------------

/// Transliteratsiya qilinmaydigan bo'laklar: brendlar, placeholderlar,
/// telefon raqamlar, havolalar.
final RegExp _protected = RegExp(
  r"\{\w+\}|QR|SMS|GPS|Telegram|Thermo Tech|TIP-\d+|Play Market|App Store|Usta Bonus|@\w+|\+998[\d ]+|https?://\S+|\b(?=[a-z]*\d)[a-z0-9]{8}\b",
);

const _apostrophes = {"'", 'ʻ', '‘', '’', 'ʼ', '`'};

const Map<String, String> _single = {
  'a': 'а', 'b': 'б', 'c': 'ц', 'd': 'д', 'e': 'е', 'f': 'ф', 'g': 'г',
  'h': 'ҳ', 'i': 'и', 'j': 'ж', 'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н',
  'o': 'о', 'p': 'п', 'q': 'қ', 'r': 'р', 's': 'с', 't': 'т', 'u': 'у',
  'v': 'в', 'w': 'в', 'x': 'х', 'y': 'й', 'z': 'з',
};

const Map<String, String> _double = {
  'sh': 'ш', 'ch': 'ч', 'ya': 'я', 'yu': 'ю', 'yo': 'ё', 'ye': 'е',
};

bool _isLetter(String ch) => RegExp(r'[A-Za-zА-Яа-яЎўҚқҒғҲҳЁё]').hasMatch(ch);

bool _isUpper(String ch) => ch != ch.toLowerCase() && ch == ch.toUpperCase();

String _applyCase(String source, String mapped) =>
    _isUpper(source) ? mapped.toUpperCase() : mapped;

String toCyrillic(String input) {
  final out = StringBuffer();
  var last = 0;
  for (final m in _protected.allMatches(input)) {
    out.write(_translit(input.substring(last, m.start)));
    out.write(m.group(0));
    last = m.end;
  }
  out.write(_translit(input.substring(last)));
  return out.toString();
}

String _translit(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final ch = s[i];
    final lower = ch.toLowerCase();
    final next = i + 1 < s.length ? s[i + 1] : '';
    final prev = i > 0 ? s[i - 1] : '';

    // o' -> ў, g' -> ғ
    if ((lower == 'o' || lower == 'g') && _apostrophes.contains(next)) {
      out.write(_applyCase(ch, lower == 'o' ? 'ў' : 'ғ'));
      i += 2;
      continue;
    }

    // sh, ch, ya, yu, yo, ye
    if (next.isNotEmpty) {
      final pair = lower + next.toLowerCase();
      final mapped = _double[pair];
      // "yo'l" -> "йўл": y + o' bo'lsa, "yo" juftligi emas.
      final afterPair = i + 2 < s.length ? s[i + 2] : '';
      final isYoWithApostrophe =
          pair == 'yo' && _apostrophes.contains(afterPair);
      if (mapped != null && !isYoWithApostrophe) {
        out.write(_applyCase(ch, mapped));
        i += 2;
        continue;
      }
    }

    // Tutuq belgisi -> ъ
    if (_apostrophes.contains(ch)) {
      out.write(_isLetter(prev) && next.isNotEmpty && _isLetter(next) ? 'ъ' : ch);
      i++;
      continue;
    }

    // So'z boshidagi e -> э
    if (lower == 'e' && (prev.isEmpty || !_isLetter(prev))) {
      out.write(_applyCase(ch, 'э'));
      i++;
      continue;
    }

    final mapped = _single[lower];
    out.write(mapped == null ? ch : _applyCase(ch, mapped));
    i++;
  }
  return out.toString();
}

// ---------------------------------------------------------------------------
// Matnlar
// ---------------------------------------------------------------------------

const Map<String, LocalizedText> kStrings = {
  // Umumiy
  'ok': LocalizedText('OK', 'OK'),
  'cancel': LocalizedText('Bekor qilish', 'Отмена'),
  'save': LocalizedText('Saqlash', 'Сохранить'),
  'continue': LocalizedText('Davom etish', 'Продолжить'),
  'retry': LocalizedText('Qayta urinish', 'Повторить'),
  'close': LocalizedText('Yopish', 'Закрыть'),
  'yes': LocalizedText('Ha', 'Да'),
  'no': LocalizedText("Yo'q", 'Нет'),
  'see_all': LocalizedText('Hammasi', 'Все'),
  'empty': LocalizedText("Hozircha hech narsa yo'q", 'Пока ничего нет'),
  'required': LocalizedText('Majburiy maydon', 'Обязательное поле'),
  'copied': LocalizedText('Nusxalandi', 'Скопировано'),
  'error_generic': LocalizedText(
      "Xatolik yuz berdi. Qayta urinib ko'ring.",
      'Произошла ошибка. Попробуйте ещё раз.'),
  'demo_badge': LocalizedText('DEMO', 'ДЕМО'),

  // Til va splash
  'choose_language': LocalizedText('Tilni tanlang', 'Выберите язык'),
  'tagline': LocalizedText("O'rnating. Skanerlang. Sovg'a oling.",
      'Устанавливайте. Сканируйте. Получайте подарки.'),

  // Telefon
  'phone_title': LocalizedText('Telefon raqamingiz', 'Ваш номер телефона'),
  'phone_subtitle': LocalizedText(
      'Raqamingizga 6 xonali tasdiqlash kodi yuboriladi',
      'Мы отправим 6-значный код подтверждения на ваш номер'),
  'phone_label': LocalizedText('Telefon raqam', 'Номер телефона'),
  'phone_invalid':
      LocalizedText("Raqamni to'liq kiriting", 'Введите номер полностью'),
  'agree_terms': LocalizedText('Foydalanish shartlariga roziman',
      'Я принимаю условия использования'),
  'read_terms': LocalizedText("Shartlarni o'qish", 'Читать условия'),
  'terms_title': LocalizedText('Foydalanish shartlari', 'Условия использования'),
  'terms_text': LocalizedText(
      "1. Ball faqat original stikerdagi QR-kod uchun beriladi.\n"
          "2. Har bir kod faqat bir marta ball beradi.\n"
          "3. Yuborilgan foto va manzil haqiqiy o'rnatishga tegishli bo'lishi kerak.\n"
          "4. Firibgarlik aniqlansa, ballar bekor qilinadi va akkaunt bloklanadi.\n"
          "5. Shaxsiy ma'lumotlaringiz faqat bonus dasturi uchun ishlatiladi.",
      '1. Баллы начисляются только за QR-код с оригинального стикера.\n'
          '2. Каждый код даёт баллы только один раз.\n'
          '3. Фото и адрес должны относиться к реальной установке.\n'
          '4. При выявлении мошенничества баллы аннулируются, а аккаунт блокируется.\n'
          '5. Ваши персональные данные используются только для бонусной программы.'),
  'get_code': LocalizedText('Kodni olish', 'Получить код'),

  // SMS kod
  'otp_title': LocalizedText('Tasdiqlash kodi', 'Код подтверждения'),
  'otp_subtitle': LocalizedText('{phone} raqamiga 6 xonali kod yuborildi',
      '6-значный код отправлен на номер {phone}'),
  'otp_invalid': LocalizedText("Kod noto'g'ri", 'Неверный код'),
  'otp_resend': LocalizedText('Kodni qayta yuborish', 'Отправить код повторно'),
  'otp_resend_in':
      LocalizedText('Qayta yuborish: {s} s', 'Повторно через {s} с'),
  'otp_demo_hint': LocalizedText(
      'Demo: istalgan 6 ta bir xil raqam, masalan 111111',
      'Демо: любые 6 одинаковых цифр, например 111111'),
  'change_number': LocalizedText("Raqamni o'zgartirish", 'Изменить номер'),
  'code_resent': LocalizedText('Kod qayta yuborildi', 'Код отправлен повторно'),

  // Ro'yxatdan o'tish
  'register_title': LocalizedText("Ro'yxatdan o'tish", 'Регистрация'),
  'register_subtitle': LocalizedText(
      "Bir marta to'ldirasiz, keyin shu ma'lumotlar sovg'a yetkazishda ishlatiladi",
      'Заполняется один раз, данные нужны для доставки подарков'),
  'first_name': LocalizedText('Ism', 'Имя'),
  'last_name': LocalizedText('Familiya', 'Фамилия'),
  'region': LocalizedText('Viloyat', 'Область'),
  'city': LocalizedText('Shahar yoki tuman', 'Город или район'),
  'experience': LocalizedText('Tajriba (yil)', 'Опыт (лет)'),
  'finish_registration':
      LocalizedText("Ro'yxatdan o'tish", 'Зарегистрироваться'),

  // Navigatsiya
  'nav_home': LocalizedText('Bosh sahifa', 'Главная'),
  'nav_submissions': LocalizedText('Arizalar', 'Заявки'),
  'nav_shop': LocalizedText("Do'kon", 'Магазин'),
  'nav_profile': LocalizedText('Profil', 'Профиль'),

  // Bosh sahifa
  'hello': LocalizedText('Salom, {name}!', 'Здравствуйте, {name}!'),
  'your_balance': LocalizedText('Sizning balansingiz', 'Ваш баланс'),
  'points_history': LocalizedText('Ball tarixi', 'История баллов'),
  'scan_cta_title': LocalizedText('QR-kodni skanerlash', 'Сканировать QR-код'),
  'scan_cta_sub': LocalizedText(
      "Radiatorni o'rnatdingizmi? Stikerdagi kodni skanerlang",
      'Установили радиатор? Отсканируйте код на стикере'),
  'this_month': LocalizedText('Bu oy', 'В этом месяце'),
  'installs': LocalizedText("O'rnatishlar", 'Установки'),
  'earned': LocalizedText('Topilgan ball', 'Заработано'),
  'recent_submissions': LocalizedText('Oxirgi arizalar', 'Последние заявки'),
  'no_submissions': LocalizedText(
      "Hali ariza yo'q. Birinchi kodni skanerlang!",
      'Заявок пока нет. Отсканируйте первый код!'),

  // Skaner
  'scan_title': LocalizedText('Kodni skanerlang', 'Отсканируйте код'),
  'scan_hint': LocalizedText("QR-kodni ramka ichiga joylang",
      'Наведите камеру на QR-код'),
  'enter_manually': LocalizedText("Kodni qo'lda kiritish", 'Ввести код вручную'),
  'code_label': LocalizedText('Stikerdagi kod', 'Код со стикера'),
  'code_hint': LocalizedText('masalan, gpyn166n', 'например, gpyn166n'),
  'check': LocalizedText('Tekshirish', 'Проверить'),
  'checking': LocalizedText('Kod tekshirilmoqda...', 'Проверяем код...'),
  'camera_error': LocalizedText(
      "Kamerani ochib bo'lmadi. Kodni qo'lda kiriting.",
      'Не удалось открыть камеру. Введите код вручную.'),
  'code_invalid_format': LocalizedText(
      "Kod 8 ta harf va raqamdan iborat bo'lishi kerak",
      'Код должен состоять из 8 букв и цифр'),
  'code_not_found': LocalizedText('Kod bazada topilmadi', 'Код не найден в базе'),
  'code_not_found_sub': LocalizedText(
      "Kodni to'g'ri kiritganingizni tekshiring. Stiker original bo'lmasligi ham mumkin.",
      'Проверьте правильность кода. Возможно, стикер не оригинальный.'),
  'code_used': LocalizedText('Bu kod avval ishlatilgan',
      'Этот код уже использован'),
  'code_used_sub': LocalizedText('Har bir kod faqat bir marta ball beradi.',
      'Каждый код даёт баллы только один раз.'),
  'code_used_by_you': LocalizedText('Siz bu kodni {date} kuni yuborgansiz.',
      'Вы уже отправляли этот код {date}.'),
  'code_blocked': LocalizedText('Kod bloklangan', 'Код заблокирован'),
  'code_blocked_sub': LocalizedText(
      "Bu stiker brak deb belgilangan. Qo'llab-quvvatlash xizmatiga murojaat qiling.",
      'Этот стикер отмечен как брак. Обратитесь в службу поддержки.'),
  'too_many_attempts': LocalizedText("Juda ko'p noto'g'ri urinish",
      'Слишком много неверных попыток'),
  'too_many_attempts_sub': LocalizedText(
      "Xavfsizlik uchun tekshiruv vaqtincha to'xtatildi. 1 soatdan keyin qayta urinib ko'ring.",
      'Проверка временно заблокирована в целях безопасности. Попробуйте через час.'),
  'scan_again': LocalizedText('Qayta skanerlash', 'Сканировать снова'),

  // Ariza formasi
  'form_title': LocalizedText("O'rnatish haqida", 'Данные об установке'),
  'code_valid': LocalizedText('Kod tasdiqlandi', 'Код подтверждён'),
  'product': LocalizedText('Mahsulot', 'Товар'),
  'you_will_get': LocalizedText('Siz olasiz', 'Вы получите'),
  'photos': LocalizedText("O'rnatilgan radiator fotosi",
      'Фото установленного радиатора'),
  'photos_hint': LocalizedText(
      "{min}–{max} ta foto. Radiator va stiker aniq ko'rinsin.",
      '{min}–{max} фото. Радиатор и стикер должны быть хорошо видны.'),
  'add_photo': LocalizedText("Foto qo'shish", 'Добавить фото'),
  'take_photo': LocalizedText('Kamera orqali', 'Сделать фото'),
  'from_gallery': LocalizedText('Galereyadan', 'Из галереи'),
  'photos_required': LocalizedText("Kamida 1 ta foto qo'shing",
      'Добавьте хотя бы 1 фото'),
  'address': LocalizedText("O'rnatilgan manzil", 'Адрес установки'),
  'address_hint': LocalizedText("Shahar, ko'cha, uy", 'Город, улица, дом'),
  'detect_location':
      LocalizedText('Joylashuvni aniqlash', 'Определить местоположение'),
  'location_detected':
      LocalizedText('Joylashuv aniqlandi', 'Местоположение определено'),
  'location_denied': LocalizedText('Joylashuvga ruxsat berilmadi',
      'Нет доступа к геолокации'),
  'location_off': LocalizedText("Telefonda joylashuv o'chirilgan",
      'Геолокация на телефоне выключена'),
  'client_phone': LocalizedText('Mijoz telefoni (ixtiyoriy)',
      'Телефон клиента (необязательно)'),
  'comment': LocalizedText('Izoh (ixtiyoriy)', 'Комментарий (необязательно)'),
  'submit': LocalizedText('Yuborish', 'Отправить'),

  // Muvaffaqiyat
  'success_title': LocalizedText('Ball hisobingizga tushdi!', 'Баллы зачислены!'),
  'success_sub': LocalizedText('{code} kodi tasdiqlandi', 'Код {code} подтверждён'),
  'new_balance': LocalizedText('Yangi balans', 'Новый баланс'),
  'scan_more': LocalizedText('Yana skanerlash', 'Сканировать ещё'),
  'to_home': LocalizedText('Bosh sahifaga', 'На главную'),

  // Arizalar
  'submissions_title': LocalizedText('Mening arizalarim', 'Мои заявки'),
  'filter_all': LocalizedText('Hammasi', 'Все'),
  'status_approved': LocalizedText('Tasdiqlandi', 'Подтверждена'),
  'status_rejected': LocalizedText('Rad etildi', 'Отклонена'),
  'status_pending': LocalizedText('Tekshirilmoqda', 'На проверке'),
  'submission': LocalizedText('Ariza', 'Заявка'),
  'code': LocalizedText('Kod', 'Код'),
  'date': LocalizedText('Sana', 'Дата'),
  'coordinates': LocalizedText('Koordinatalar', 'Координаты'),
  'reject_reason': LocalizedText('Rad etish sababi', 'Причина отказа'),
  'status_history': LocalizedText('Holat tarixi', 'История статусов'),
  'submitted': LocalizedText('Yuborildi', 'Отправлена'),
  'source_telegram': LocalizedText("Telegram orqali yuborilgan (ko'chirilgan)",
      'Отправлена через Telegram (перенесено)'),
  'no_photos': LocalizedText("Foto yo'q", 'Нет фото'),
  'submissions_empty': LocalizedText("Bu bo'limda ariza yo'q",
      'В этом разделе нет заявок'),

  // Ballar
  'history_empty': LocalizedText("Ball harakatlari hali yo'q",
      'Операций с баллами пока нет'),
  'tx_earn': LocalizedText("O'rnatish uchun", 'За установку'),
  'tx_redeem': LocalizedText("Sovg'a buyurtmasi", 'Заказ подарка'),
  'tx_refund': LocalizedText('Buyurtma bekor qilindi', 'Заказ отменён'),
  'tx_import': LocalizedText("Telegram'dan ko'chirildi", 'Перенесено из Telegram'),
  'tx_adjust': LocalizedText('Tuzatish', 'Корректировка'),
  'total_earned': LocalizedText("Jami yig'ilgan", 'Всего заработано'),
  'total_spent': LocalizedText('Sarflangan', 'Потрачено'),

  // Do'kon
  'shop_title': LocalizedText("Sovg'alar do'koni", 'Магазин подарков'),
  'in_stock': LocalizedText('Omborda: {n} ta', 'В наличии: {n} шт.'),
  'out_of_stock': LocalizedText('Tugagan', 'Нет в наличии'),
  'get': LocalizedText('Olish', 'Получить'),
  'not_enough': LocalizedText('Yana {n} kerak', 'Не хватает {n}'),
  'description': LocalizedText('Tavsif', 'Описание'),

  // Buyurtma
  'checkout_title':
      LocalizedText('Buyurtmani rasmiylashtirish', 'Оформление заказа'),
  'quantity': LocalizedText('Soni', 'Количество'),
  'delivery': LocalizedText('Olish usuli', 'Способ получения'),
  'delivery_courier':
      LocalizedText('Manzilga yetkazib berish', 'Доставка по адресу'),
  'delivery_pickup': LocalizedText('Olib ketish punkti', 'Пункт выдачи'),
  'pickup_point': LocalizedText('Punktni tanlang', 'Выберите пункт'),
  'delivery_address': LocalizedText('Yetkazish manzili', 'Адрес доставки'),
  'contact_phone': LocalizedText('Aloqa uchun telefon', 'Контактный телефон'),
  'total': LocalizedText('Jami', 'Итого'),
  'balance_after':
      LocalizedText('Buyurtmadan keyingi balans', 'Баланс после заказа'),
  'confirm_order': LocalizedText('Buyurtmani tasdiqlash', 'Подтвердить заказ'),
  'order_created': LocalizedText('Buyurtma qabul qilindi!', 'Заказ принят!'),
  'order_created_sub': LocalizedText(
      "Holatini \"Buyurtmalarim\" bo'limida kuzatishingiz mumkin",
      'Статус можно отслеживать в разделе «Мои заказы»'),
  'my_orders': LocalizedText('Buyurtmalarim', 'Мои заказы'),
  'order_no': LocalizedText('Buyurtma №{id}', 'Заказ №{id}'),
  'order_accepted': LocalizedText('Qabul qilindi', 'Принят'),
  'order_shipping': LocalizedText("Yo'lda", 'В пути'),
  'order_delivered': LocalizedText('Topshirildi', 'Доставлен'),
  'order_cancelled': LocalizedText('Bekor qilindi', 'Отменён'),
  'cancel_order': LocalizedText('Bekor qilish', 'Отменить'),
  'cancel_order_confirm': LocalizedText(
      'Buyurtma bekor qilinsinmi? Ballar hisobingizga qaytariladi.',
      'Отменить заказ? Баллы вернутся на ваш счёт.'),
  'orders_empty': LocalizedText("Hali buyurtma yo'q", 'Заказов пока нет'),
  'go_to_shop': LocalizedText("Do'konga o'tish", 'Перейти в магазин'),
  'insufficient_points':
      LocalizedText("Ballar yetarli emas", 'Недостаточно баллов'),
  'out_of_stock_error':
      LocalizedText("Mahsulot omborda qolmagan", 'Товара нет в наличии'),

  // Profil
  'edit_profile': LocalizedText("Ma'lumotlarni tahrirlash", 'Редактировать профиль'),
  'notifications': LocalizedText('Bildirishnomalar', 'Уведомления'),
  'language': LocalizedText('Til', 'Язык'),
  'help': LocalizedText('Yordam', 'Помощь'),
  'delete_account': LocalizedText("Akkauntni o'chirish", 'Удалить аккаунт'),
  'logout': LocalizedText('Chiqish', 'Выйти'),
  'logout_confirm':
      LocalizedText('Akkauntdan chiqilsinmi?', 'Выйти из аккаунта?'),
  'member_since': LocalizedText('{date} dan beri ishtirokchi', 'Участник с {date}'),
  'stats_installs': LocalizedText("O'rnatishlar", 'Установки'),
  'stats_points': LocalizedText('Jami ball', 'Всего баллов'),
  'profile_saved': LocalizedText("Ma'lumotlar saqlandi", 'Данные сохранены'),
  'version': LocalizedText('Versiya {v}', 'Версия {v}'),

  // Bildirishnomalar
  'notifications_empty':
      LocalizedText("Bildirishnomalar yo'q", 'Уведомлений нет'),
  'n_points_title': LocalizedText('+{points} ball', '+{points} баллов'),
  'n_points_body': LocalizedText('{code} kodi tasdiqlandi, ball hisobingizga tushdi.',
      'Код {code} подтверждён, баллы зачислены.'),
  'n_order_title': LocalizedText('Buyurtma №{id}', 'Заказ №{id}'),
  'n_order_created': LocalizedText('Buyurtmangiz qabul qilindi.', 'Ваш заказ принят.'),
  'n_order_shipping':
      LocalizedText("Buyurtmangiz yo'lga chiqdi.", 'Ваш заказ в пути.'),
  'n_order_delivered':
      LocalizedText('Buyurtmangiz topshirildi.', 'Ваш заказ доставлен.'),
  'n_order_cancelled': LocalizedText(
      'Buyurtma bekor qilindi, {points} ball qaytarildi.',
      'Заказ отменён, {points} баллов возвращено.'),
  'n_welcome_title': LocalizedText('Xush kelibsiz!', 'Добро пожаловать!'),
  'n_welcome_body': LocalizedText(
      "Radiatorni o'rnating, stikerdagi QR-kodni skanerlang va ball yig'ing.",
      'Устанавливайте радиаторы, сканируйте QR-код на стикере и копите баллы.'),
  'n_import_title':
      LocalizedText('Ballaringiz ko\'chirildi', 'Ваши баллы перенесены'),
  'n_import_body': LocalizedText(
      "Telegram orqali yig'ilgan {points} ball ilovaga o'tkazildi.",
      '{points} баллов, накопленных через Telegram, перенесены в приложение.'),

  // Yordam
  'faq': LocalizedText("Ko'p beriladigan savollar", 'Частые вопросы'),
  'contact_us': LocalizedText("Biz bilan bog'lanish", 'Связаться с нами'),
  'support_phone': LocalizedText('Telefon', 'Телефон'),
  'demo_codes': LocalizedText('Demo kodlar (faqat test uchun)',
      'Демо-коды (только для теста)'),
  'demo_codes_sub': LocalizedText(
      "Bosib nusxalang va \"Kodni qo'lda kiritish\" orqali tekshiring. Demo akkaunt: 90 000 00 00.",
      'Нажмите, чтобы скопировать, и проверьте через «Ввести код вручную». Демо-аккаунт: 90 000 00 00.'),

  // Akkauntni o'chirish
  'delete_warning': LocalizedText(
      "Akkaunt o'chirilgach, profilingiz, arizalar tarixi va {points} ball qayta tiklab bo'lmaydigan tarzda o'chiriladi.",
      'После удаления аккаунта профиль, история заявок и {points} баллов будут удалены без возможности восстановления.'),
  'delete_type': LocalizedText(
      "Tasdiqlash uchun {word} so'zini yozing", 'Для подтверждения введите {word}'),
  'delete_word': LocalizedText("O'CHIRISH", 'УДАЛИТЬ'),
  'account_deleted': LocalizedText("Akkaunt o'chirildi", 'Аккаунт удалён'),
};
