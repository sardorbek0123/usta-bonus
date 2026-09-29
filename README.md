# Usta Bonus — mobil ilova (demo)

Ustalar uchun bonus ilovasi: radiator o'rnatiladi, stikerdagi QR-kod skanerlanadi, ball avtomatik tushadi va ballarga sovg'a olinadi.

**Holati:** backend hali yo'q. Barcha ma'lumotlar telefon xotirasida saqlanadi (`LocalBackend`), lekin biznes qoidalari backend'dagidek ishlaydi: bitta kod bir marta, ball jurnali, qoldiq, rate limit.

## Ishga tushirish

Flutter **3.35 yoki yangiroq** kerak (API'lar 3.47 bo'yicha tekshirilgan).

```bash
# 1. Android va iOS papkalarini yaratish (lib/ ichidagi fayllarga tegmaydi)
flutter create . --org uz.ustabonus --project-name usta_bonus --platforms android,ios

# 2. Paketlar
flutter pub get

# 3. Ruxsatlarni avtomatik qo'shish (pastdagi qo'lda qilinadigan ish shu)
python3 tool/setup_platforms.py

# 4. Ishga tushirish
flutter run
```

### APK'ni GitHub'da avtomatik build qilish

Kompyuterda Android SDK bo'lmasa: loyihani GitHub'dagi repoga push qiling. `.github/workflows/build-apk.yml` har bir push'da APK build qiladi (taxminan 10 daqiqa). Tayyor fayl: **Actions → oxirgi run → Artifacts → usta-bonus-apk**. Telefonlarning ko'pchiligiga `app-arm64-v8a-release.apk` mos keladi.

Testlar: `flutter test`. Kod tahlili: `flutter analyze`.

> Kod Flutter SDK'siz muhitda yozilgan: paket API'lari manba kodi bo'yicha tekshirilgan, sintaksis parser bilan tekshirilgan, lekin kompilyatsiya qilinmagan. Birinchi `flutter analyze` kichik ogohlantirishlar chiqarsa, ularni tuzatish oson.

### Android ruxsatlari

`android/app/src/main/AndroidManifest.xml` ichida, `<application>` tegidan oldin:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS ruxsatlari

`ios/Runner/Info.plist` ichida, `<dict>` ga:

```xml
<key>NSCameraUsageDescription</key>
<string>Stikerdagi QR-kodni skanerlash va o'rnatilgan radiatorni suratga olish uchun</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>O'rnatilgan radiator fotosini galereyadan tanlash uchun</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>O'rnatish manzilini aniqlash uchun</string>
```

Apple bu matnlarni tekshiradi: nega ruxsat kerakligi aniq yozilishi shart.

## Demo rejimda kirish

- **Telefon:** istalgan 9 xonali raqam. Yangi raqam bo'lsa, ro'yxatdan o'tish ochiladi.
- **SMS kod:** 6 ta bir xil raqam: `111111`, `222222` va hokazo. SMS yuborilmaydi.
- **Demo usta:** `90 000 00 00`. Telegram'dan "ko'chirilgan" tarixi bor: 8 ta ariza, 1 ta rad etilgan (foto yo'q), 1 ta berilgan sovg'a.

`lib/core/config.dart` dagi `demoMode = false` qilinsa, demo yozuvlari va soxta SMS kod o'chadi.

## Demo QR kodlar

`docs/demo_qr_codes.png` ni ekranda oching yoki chop eting va ilovadan skanerlang. Kodlarni qo'lda ham kiritish mumkin (Profil → Yordam bo'limida ro'yxati bor).

| Kod | Natija |
|---|---|
| `x3ymtd0p`, `v83bezjg`, `la4ym3x1` | +20 ball |
| `st25ofvt`, `pftg6gab`, `j9lbi8hb` | +40 ball |
| `ov8da0yp`, `n55l0281`, `jf77yyyh` | +60 ball |
| `lbst7lio` | Avval ishlatilgan (demo ustada "siz yuborgansiz" chiqadi) |
| `6bw87y0i` | Brak (bloklangan) |
| `zz99zz99` | Bazada topilmadi |

Jami 57 ta yangi kod bor (`lib/data/mock_seed.dart`). 1 soatda 10 ta noto'g'ri kod kiritilsa, tekshirish vaqtincha bloklanadi.

Buyurtma holati demo uchun o'z-o'zidan o'zgaradi: 30 soniyadan keyin "Yo'lda", 2 daqiqadan keyin "Topshirildi". Real tizimda holatni admin panel o'zgartiradi.

## Ekranlar (TZ bo'yicha 18 ta)

| № | Ekran | Fayl |
|---|---|---|
| 1 | Splash + til tanlash (o'zbek lotin/kirill, rus) | `features/auth/language_screen.dart` |
| 2 | Telefon raqam + shartlarga rozilik | `features/auth/phone_screen.dart` |
| 3 | 6 xonali SMS kod, qayta yuborish taymeri | `features/auth/otp_screen.dart` |
| 4 | Ro'yxatdan o'tish | `features/auth/register_screen.dart` |
| 5 | Bosh sahifa: balans, bannerlar, oylik statistika, oxirgi arizalar | `features/home/home_screen.dart` |
| 6 | QR skaner: chiroq, qo'lda kiritish, natija oynasi | `features/scan/scan_screen.dart` |
| 7 | Ariza: 1–3 foto, manzil, GPS, mijoz telefoni, izoh | `features/scan/submission_form_screen.dart` |
| — | Muvaffaqiyat ekrani (+ball, yangi balans) | `features/scan/submission_success_screen.dart` |
| 8 | Arizalar ro'yxati, filtr | `features/submissions/submissions_screen.dart` |
| 9 | Ariza tafsiloti, holat tarixi, rad etish sababi | `features/submissions/submission_detail_screen.dart` |
| 10 | Ball tarixi (jurnal) | `features/points/points_history_screen.dart` |
| 11 | Sovg'alar katalogi, kategoriyalar | `features/shop/shop_screen.dart` |
| 12 | Sovg'a sahifasi | `features/shop/shop_item_screen.dart` |
| 13 | Buyurtma: soni, olib ketish punkti yoki yetkazish | `features/shop/checkout_screen.dart` |
| 14 | Buyurtmalarim, bekor qilish (ball qaytadi) | `features/shop/orders_screen.dart` |
| 15 | Profil va tahrirlash | `features/profile/profile_screen.dart`, `edit_profile_screen.dart` |
| 16 | Bildirishnomalar | `features/profile/notifications_screen.dart` |
| 17 | Yordam: FAQ, kontaktlar | `features/profile/help_screen.dart` |
| 18 | Akkauntni o'chirish (App Store talabi) | `features/profile/delete_account_screen.dart` |

## Backend'ga ulash

1. `lib/data/api_repository.dart` dagi `ApiRepository` interfeysini HTTP orqali bajaradigan `HttpApiRepository` yoziladi. Endpointlar jadvali shu faylda.
2. `lib/main.dart` da `LocalBackend.create()` o'rniga `HttpApiRepository` beriladi.
3. `AppConfig.demoMode = false`.

Ekranlar faqat `ApiRepository` bilan ishlaydi, shuning uchun ularni o'zgartirish shart emas.

**Backend bilan birga qo'shiladi:** Eskiz orqali haqiqiy SMS, FCM push, fotolarni serverga yuklash, internet yo'qligida qoralama saqlash, haqiqiy kodlar bazasi (Excel importi), shubhali arizalarni moderator tekshiruvi, admin panel.

## Tuzilma

```
lib/
  main.dart, app.dart          ishga tushirish, til va sahifa tanlash
  core/                        sozlamalar, tarjimalar, format, tema, QR parser
  data/
    models.dart                ma'lumot modellari
    api_repository.dart        backend shartnomasi
    local_backend.dart         vaqtinchalik lokal "server"
    mock_seed.dart             demo kodlar, mahsulotlar, sovg'alar
  state/providers.dart         Riverpod: sessiya va ma'lumotlar
  widgets/                     umumiy komponentlar
  features/                    ekranlar
```

Tarjimalar `lib/core/i18n.dart` da. O'zbek kirill matni lotinchadan avtomatik transliteratsiya qilinadi, shuning uchun yangi matn faqat o'zbek (lotin) va rus tilida yoziladi.
