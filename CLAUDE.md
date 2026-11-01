# Usta Bonus — loyiha konteksti

Bu fayl claude.ai chatidagi rejalashtirish suhbatidan yig'ilgan. Har bir yangi sessiya shundan boshlaydi.
Foydalanuvchi bilan **o'zbek tilida** (lotin) gaplashiladi.

## Nima qilinyapti

Radiator o'rnatuvchi ustalar uchun bonus (loyalty) ilovasi. Analog: Akfa Comfort (Play Market: `uz.akfa.comfort`).
Mijoz: Thermo Tech radiatorlari (stikerda "Сантехниклар учун", Telegram @TT_REWARDS). Hozir jarayon Telegram + Excel orqali qo'lda yuritiladi.

Jarayon: usta radiator o'rnatadi → stikerdagi QR-kodni skanerlaydi → foto + manzil yuboradi → kod bazada bor va ishlatilmagan bo'lsa, **ball avtomatik tushadi** (moderator yo'q, faqat shubhali holatlar tekshiriladi) → ballarga ichki do'kondan sovg'a oladi.

TZ (texnik topshiriq) Claude Docs'da: https://claude.ai/code/artifact/b43dd443-ff87-4dfd-b1e9-dfbf04da3e8c

## Holat

- ✅ **Mobil ilova (Flutter)** — shu repoda, 18 ekran, backend'siz ishlaydi (`lib/data/local_backend.dart`). Demo: istalgan raqam, SMS kod = 6 ta bir xil raqam (111111). Demo usta: 90 000 00 00.
- ✅ **CI**: `.github/workflows/build-apk.yml` har push'da APK build qiladi va GitHub Release'ga chiqaradi (`releases/latest`).
- ⏳ **Backend** — hali yo'q. Keyingi qadam.
- ⏳ **Admin panel** — hali yo'q.
- ⏳ **Excel bazasini import** — skript yozilmagan.
- ⏳ **iOS** — Mac'da simulyator orqali test qilinadi; iPhone yo'q, TestFlight uchun Apple Developer akkaunt keyin ochiladi.

## Kelishilgan stack

| Qism | Tanlov |
|---|---|
| Mobil | Flutter, Riverpod 3, mobile_scanner, image_picker, geolocator |
| Backend | **NestJS** (TypeScript) + **Prisma** |
| DB | **PostgreSQL** (O'zbekistondagi VPS'da — shaxsiy ma'lumotlar lokalizatsiyasi talabi; Neon emas) |
| Admin | **Vue 3 + Vite + PrimeVue (Sakai shabloni)** — foydalanuvchi Vue'ni yaxshi biladi |
| Fayllar | MinIO (S3-mos) |
| SMS | `SmsProvider` interfeysi: **Eskiz** (~95 so'm) va **TextUp** (150–160 so'm) — `.env` bilan tanlanadi |
| Push | Firebase Cloud Messaging |
| Deploy | Docker Compose |

Rejalangan tuzilma: `mobile/` (hozirgi Flutter kodi), `backend/`, `admin/`, `docker-compose.yml`.

## Muhim qoidalar (o'zgartirilmaydi)

- **Kod bir martalik**: `UPDATE qr_codes SET status='used' WHERE code=? AND status='available'` — atomar, parallel so'rovda faqat bittasi o'tadi.
- **Ball faqat jurnal (ledger) orqali**: `point_transactions` (+kirim / −chiqim). Balans jurnaldan hisoblanadi, ball faqat serverda beriladi.
- Kodlar **kichik harfga** normallashtiriladi (Excel'da 532 ta kod bosh harf bilan qolib ketgan).
- Noto'g'ri kod: 1 soatda 10 urinishdan keyin rate limit.
- Ikki auth: mobil — telefon + OTP (JWT access/refresh), admin — login/parol + rollar.
- Mobil ilovadagi `lib/data/api_repository.dart` = backend shartnomasi. Endpointlar shunga mos yoziladi, keyin `HttpApiRepository` qo'shiladi.

## Excel bazasi (`Operator_uchun_Yangi_76.xlsx`)

Fayl **repoga qo'yilmaydi** (mijozning haqiqiy kodlari va ustalar telefonlari; repo public bo'lishi mumkin). Kerak bo'lganda sessiyaga alohida yuklanadi.

| Sheet | Mazmuni | Bazaga |
|---|---|---|
| `uuid_codes` | 559 007 ta chop etilgan kod (8 belgi; 3 tasi g'alati: 9/46 belgi) | `qr_codes` |
| `prixod`, `prixod 2` | sotuvga jo'natilgan kodlar + sana (2025-07…10); ~4 200 tasi bazada yo'q | `qr_codes.shipped_at` |
| `operator uchun` | 57 885 ta ro'yxatdan o'tgan o'rnatish, 2 113 usta (9 xonali telefon), viloyat, shahar (198 xil yozuv), rasm bor/yo'q, `Ball miqdori` (20/40/60), `Sovg'a berilgan ballar` | `users`, `submissions`, `point_transactions` |
| `list` | 14 viloyat | `regions` |
| `отчет стикеров`, `Otchyot`, `Jami ballar otchyoti`, `pivot` | hisobotlar | ko'chirilmaydi, SQL bilan hisoblanadi |

Tekshirish: import oxirida jami ball **871 800** ga teng bo'lishi kerak. 293 ta bo'sh qator, 3 ta telefonda turli ismlar.

**Mijozdan javob kutilayotgan savollar:**
1. "Sovg'a berilgan ballar" = sovg'aga allaqachon sarflangan ballarmi? (taxmin: ha → +kirim va −chiqim)
2. 20/40/60 ball nimaga bog'liq (radiator o'lchami?) — Excel'da kod ↔ mahsulot bog'lanishi yo'q.
3. Rasm yo'q (12 296 ta) arizalar: rad etilganmi yoki qayta yuklash imkoni beriladimi?
4. Brak stikerlar (8 385 ta) ro'yxati bormi?
5. Stikerdagi QR ichida nima bor (toza kod yoki URL)? — `lib/core/qr_parser.dart` ikkalasini ham qo'llaydi.

## Biznes ma'lumotlari

- Taxminiy narx: 40–80 mln so'm (real ~50–60 mln), qo'llab-quvvatlash oyiga 3–5 mln.
- Muddat: ~7 hafta (tayyorgarlik → backend+admin → mobil → test va reliz).
- Play Market: shaxsiy akkauntda 12 tester × 14 kun yopiq test majburiy.

## Ishlash tartibi

- `flutter analyze` va `flutter test` toza bo'lishi kerak; CI shularni tekshiradi.
- Kodni o'zgartirgach push → CI APK chiqaradi.
- Commit xabarlari o'zbekcha, qisqa.
