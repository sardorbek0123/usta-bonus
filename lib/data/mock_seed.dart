import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import 'models.dart';

/// Backend tayyor bo'lguncha ishlatiladigan demo ma'lumotlar.
///
/// DIQQAT: kodlar, mahsulotlar, ball miqdorlari va sovg'alar SOXTA.
/// Haqiqiy kodlar bazasi (Excel) backend'ga import qilinadi va ilovaga
/// hech qachon kiritilmaydi.
class MockSeed {
  MockSeed._();

  static const regions = <Region>[
    Region('andijon', LocalizedText('Andijon', 'Андижанская обл.')),
    Region('buxoro', LocalizedText('Buxoro', 'Бухарская обл.')),
    Region('fargona', LocalizedText("Farg'ona", 'Ферганская обл.')),
    Region('jizzax', LocalizedText('Jizzax', 'Джизакская обл.')),
    Region('xorazm', LocalizedText('Xorazm', 'Хорезмская обл.')),
    Region('namangan', LocalizedText('Namangan', 'Наманганская обл.')),
    Region('navoiy', LocalizedText('Navoiy', 'Навоийская обл.')),
    Region('qashqadaryo', LocalizedText('Qashqadaryo', 'Кашкадарьинская обл.')),
    Region('samarqand', LocalizedText('Samarqand', 'Самаркандская обл.')),
    Region('sirdaryo', LocalizedText('Sirdaryo', 'Сырдарьинская обл.')),
    Region('surxondaryo', LocalizedText('Surxondaryo', 'Сурхандарьинская обл.')),
    Region('toshkent_vil', LocalizedText('Toshkent viloyati', 'Ташкентская обл.')),
    Region('toshkent_sh', LocalizedText('Toshkent shahri', 'г. Ташкент')),
    Region('qoraqalpogiston',
        LocalizedText("Qoraqalpog'iston", 'Республика Каракалпакстан')),
  ];

  static const productTypes = <ProductType>[
    ProductType(
      id: 'tip22_300',
      name: LocalizedText('Thermo Tech TIP-22, 300 mm', 'Thermo Tech TIP-22, 300 мм'),
      points: 20,
    ),
    ProductType(
      id: 'tip22_500',
      name: LocalizedText('Thermo Tech TIP-22, 500 mm', 'Thermo Tech TIP-22, 500 мм'),
      points: 40,
    ),
    ProductType(
      id: 'tip22_600',
      name: LocalizedText('Thermo Tech TIP-22, 600 mm', 'Thermo Tech TIP-22, 600 мм'),
      points: 60,
    ),
  ];

  /// Yangi, ishlatilmagan demo kodlar. Mahsulot turi indeks bo'yicha
  /// navbatma-navbat beriladi (20 / 40 / 60 ball).
  static const validCodes = <String>[
    'x3ymtd0p', 'st25ofvt', 'ov8da0yp', 'v83bezjg', 'pftg6gab', 'n55l0281',
    'la4ym3x1', 'j9lbi8hb', 'jf77yyyh', 'jc9d5eoc', 't2f6fduu', 'hg1hew1z',
    '52vxdsy8', 'couho5m0', 't7tk6t26', 'an85157n', 'g0s34ghk', 'otm695q2',
    '67lf3qk2', '4upjag5f', '1tbzfrow', 'ljifdmaw', 'j40kcxr6', 'j0wi876p',
    '8spsc37i', 'j44b7pig', 'vtkrt3yq', '1xvruf1s', 'ir1edfdc', 'feake1tp',
    '9044j47h', 'jh6w8ucv', 'uvp6j8i8', 'ctj7kkuh', 'kpgz44f1', '08vpe7vv',
    'u6z8vs2j', 'zw8otzb7', 'l5teocuh', 'p04zu94b', '326h0wum', 'wltxvk7i',
    'kuagq3ti', 'ln7xqd8d', '577m76rj', 'thybe2oc', 's8n75jm1', 'p28j5fn2',
    '5rx98cln', '8dhtp4yp', 'rrlnv8p8', 'wlu0rvt4', 'qwms79bf', 'jo8wl48p',
    'bedxd4oy', 'ecjn8igk', '8loqdcrz',
  ];

  /// Brak deb belgilangan kodlar.
  static const blockedCodes = <String>['6bw87y0i', 'vi09eae0', 'm742fxvh'];

  /// Demo usta Telegram orqali avval yuborgan kodlar (ishlatilgan).
  static const demoUsedCodes = <String>[
    'lbst7lio', '2jp76zmv', 'zq3m7ydd', 'u8k2p4ra', 'h3n7q1zd', 'w5c9t2mb',
    'e2r6y8ul', 'b9f4k7xs',
  ];

  /// Demo ustaning rasm yubormagani uchun rad etilgan kodi.
  static const demoRejectedCode = 'k7d2m9qa';

  static const demoPhone = '900000000';

  static String productTypeForIndex(int i) =>
      productTypes[i % productTypes.length].id;

  static const shopCategories = <ShopCategory>[
    ShopCategory('tools', LocalizedText('Asboblar', 'Инструменты')),
    ShopCategory('clothes', LocalizedText('Kiyim', 'Одежда')),
    ShopCategory('other', LocalizedText('Boshqa', 'Другое')),
  ];

  static const shopItems = <ShopItem>[
    ShopItem(
      id: 'drill',
      categoryId: 'tools',
      name: LocalizedText('Akkumulyatorli drel-shurupovert',
          'Аккумуляторная дрель-шуруповёрт'),
      description: LocalizedText(
          "18 V, 2 ta akkumulyator, zaryadlovchi va keys bilan. Montaj ishlari uchun qulay.",
          '18 В, 2 аккумулятора, зарядное устройство и кейс. Удобна для монтажа.'),
      price: 3000,
      icon: Icons.build_rounded,
      color: Color(0xFF1565C0),
    ),
    ShopItem(
      id: 'toolset',
      categoryId: 'tools',
      name: LocalizedText("Santexnika asboblari to'plami",
          'Набор сантехнических инструментов'),
      description: LocalizedText(
          "Kalitlar, qisqichlar, lenta va o'lchov asboblari. 42 ta buyum, keysda.",
          'Ключи, клещи, лента и измерительные инструменты. 42 предмета в кейсе.'),
      price: 2500,
      icon: Icons.handyman_rounded,
      color: Color(0xFF6A1B9A),
    ),
    ShopItem(
      id: 'pipe_wrench',
      categoryId: 'tools',
      name: LocalizedText('Quvur kaliti 18"', 'Трубный ключ 18"'),
      description: LocalizedText(
          "Mustahkam po'latdan, 2 dyuymgacha quvurlar uchun.",
          'Из прочной стали, для труб до 2 дюймов.'),
      price: 800,
      icon: Icons.plumbing_rounded,
      color: Color(0xFF455A64),
    ),
    ShopItem(
      id: 'jacket',
      categoryId: 'clothes',
      name: LocalizedText('Brendli ish kurtkasi', 'Фирменная рабочая куртка'),
      description: LocalizedText(
          "Suv o'tkazmaydigan, cho'ntaklari ko'p. O'lchamni buyurtmadan keyin operator aniqlaydi.",
          'Водоотталкивающая, много карманов. Размер уточнит оператор после заказа.'),
      price: 1200,
      icon: Icons.checkroom_rounded,
      color: AppColors.brand,
    ),
    ShopItem(
      id: 'cap',
      categoryId: 'clothes',
      name: LocalizedText('Brendli kepka', 'Фирменная кепка'),
      description: LocalizedText("Paxta, o'lchami sozlanadi.",
          'Хлопок, регулируемый размер.'),
      price: 300,
      icon: Icons.face_retouching_natural_rounded,
      color: Color(0xFFAD1457),
    ),
    ShopItem(
      id: 'thermos',
      categoryId: 'other',
      name: LocalizedText('Termos 1 l', 'Термос 1 л'),
      description: LocalizedText(
          "Issiqni 24 soatgacha saqlaydi. Obyektda choy uchun.",
          'Держит тепло до 24 часов. Для чая на объекте.'),
      price: 300,
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF00838F),
    ),
    ShopItem(
      id: 'powerbank',
      categoryId: 'other',
      name: LocalizedText('Powerbank 20 000 mAh', 'Powerbank 20 000 мА·ч'),
      description: LocalizedText(
          "Telefonni 4–5 marta to'liq zaryadlaydi.",
          'Полностью заряжает телефон 4–5 раз.'),
      price: 900,
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFF2E7D32),
    ),
    ShopItem(
      id: 'backpack',
      categoryId: 'other',
      name: LocalizedText('Asboblar uchun ryukzak', 'Рюкзак для инструментов'),
      description: LocalizedText(
          "Qattiq tagli, 30 dan ortiq cho'ntak.",
          'Жёсткое дно, более 30 карманов.'),
      price: 1500,
      icon: Icons.backpack_rounded,
      color: Color(0xFFEF6C00),
    ),
  ];

  static const initialStock = <String, int>{
    'drill': 5,
    'toolset': 8,
    'pipe_wrench': 20,
    'jacket': 15,
    'cap': 40,
    'thermos': 30,
    'powerbank': 12,
    'backpack': 0,
  };

  static const pickupPoints = <PickupPoint>[
    PickupPoint('tashkent', LocalizedText('Toshkent — markaziy ombor', 'Ташкент — центральный склад')),
    PickupPoint('fergana', LocalizedText("Farg'ona — diler do'koni", 'Фергана — магазин дилера')),
    PickupPoint('samarkand', LocalizedText("Samarqand — diler do'koni", 'Самарканд — магазин дилера')),
  ];

  static const banners = <PromoBanner>[
    PromoBanner(
      id: 'how',
      title: LocalizedText("Har bir o'rnatish — ball", 'Каждая установка — баллы'),
      subtitle: LocalizedText("Stikerdagi QR-kodni skanerlang va darhol ball oling",
          'Сканируйте QR-код на стикере и сразу получайте баллы'),
      icon: Icons.qr_code_2_rounded,
      colors: [AppColors.brand, AppColors.brandDark],
    ),
    PromoBanner(
      id: 'shop',
      title: LocalizedText("Sovg'alar do'koni", 'Магазин подарков'),
      subtitle: LocalizedText("Drel, asboblar to'plami, kurtka va boshqalar",
          'Дрель, набор инструментов, куртка и другое'),
      icon: Icons.card_giftcard_rounded,
      colors: [Color(0xFF263238), Color(0xFF455A64)],
    ),
    PromoBanner(
      id: 'original',
      title: LocalizedText('Faqat original stikerlar', 'Только оригинальные стикеры'),
      subtitle: LocalizedText('Har bir kod faqat bir marta ball beradi',
          'Каждый код даёт баллы только один раз'),
      icon: Icons.verified_rounded,
      colors: [Color(0xFF1E8E3E), Color(0xFF136C2E)],
    ),
  ];

  static const faq = <FaqItem>[
    FaqItem(
      LocalizedText('Ball qanday olinadi?', 'Как получить баллы?'),
      LocalizedText(
          "Radiatorni o'rnating, stikerdagi QR-kodni skanerlang va o'rnatilgan radiator fotosini yuboring. Kod to'g'ri bo'lsa, ball darhol hisobingizga tushadi.",
          'Установите радиатор, отсканируйте QR-код на стикере и отправьте фото установки. Если код верный, баллы сразу зачисляются на счёт.'),
    ),
    FaqItem(
      LocalizedText('Nega kodim "topilmadi" deb chiqdi?', 'Почему код «не найден»?'),
      LocalizedText(
          "Kod 8 ta harf va raqamdan iborat. To'g'ri kiritganingizni tekshiring. QR shikastlangan bo'lsa, kodni qo'lda kiriting. Muammo davom etsa, biz bilan bog'laning.",
          'Код состоит из 8 букв и цифр. Проверьте правильность ввода. Если QR повреждён, введите код вручную. Если проблема не решилась, свяжитесь с нами.'),
    ),
    FaqItem(
      LocalizedText("Bitta kodni ikki marta yuborsam bo'ladimi?",
          'Можно ли отправить один код дважды?'),
      LocalizedText(
          "Yo'q. Har bir kod faqat bir marta ball beradi. Kodni kim birinchi yuborsa, ball o'shanga tushadi.",
          'Нет. Каждый код даёт баллы только один раз — тому, кто отправил его первым.'),
    ),
    FaqItem(
      LocalizedText("Telegram orqali yig'ilgan ballarim nima bo'ladi?",
          'Что будет с баллами, накопленными через Telegram?'),
      LocalizedText(
          "Barcha ballaringiz ilovaga ko'chiriladi. Telegram'da ishlatgan telefon raqamingiz bilan kiring.",
          'Все баллы переносятся в приложение. Войдите с тем же номером телефона, что и в Telegram.'),
    ),
    FaqItem(
      LocalizedText("Sovg'a qachon yetkaziladi?", 'Когда доставят подарок?'),
      LocalizedText(
          "Odatda 3–7 ish kuni ichida. Holatini \"Buyurtmalarim\" bo'limida kuzatasiz.",
          'Обычно в течение 3–7 рабочих дней. Статус можно отслеживать в разделе «Мои заказы».'),
    ),
  ];

  static const LocalizedText noPhotoReason = LocalizedText(
      "O'rnatilgan radiator fotosi yuborilmagan",
      'Не отправлено фото установленного радиатора');
}
