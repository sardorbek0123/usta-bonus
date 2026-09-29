import 'models.dart';

/// Ilova va backend o'rtasidagi shartnoma.
///
/// Hozir [LocalBackend] ishlatiladi (ma'lumotlar telefonda saqlanadi).
/// Backend tayyor bo'lgach, shu interfeysni HTTP orqali bajaradigan
/// `HttpApiRepository` yoziladi va `main.dart` da almashtiriladi.
/// Metodlar TZ'dagi API ro'yxatiga mos:
///
/// | Metod                | Endpoint                     |
/// |----------------------|------------------------------|
/// | sendOtp              | POST /auth/otp/send          |
/// | verifyOtp            | POST /auth/otp/verify        |
/// | register             | PUT  /me                     |
/// | checkCode            | POST /qr/check               |
/// | createSubmission     | POST /submissions (+uploads) |
/// | getSubmissions       | GET  /submissions            |
/// | getPointsHistory     | GET  /points/history         |
/// | getShopItems         | GET  /shop/items             |
/// | createOrder          | POST /orders                 |
/// | getNotifications     | GET  /notifications          |
abstract class ApiRepository {
  // Sessiya
  /// Saqlangan sessiya bo'lsa, foydalanuvchini qaytaradi.
  Future<AppUser?> restoreSession();
  Future<String?> getSavedLanguage();
  Future<void> saveLanguage(String code);

  // Avtorizatsiya
  Future<void> sendOtp(String phone);

  /// Kod to'g'ri bo'lsa: ro'yxatdan o'tgan foydalanuvchini, yangi raqam
  /// bo'lsa `null` qaytaradi (ro'yxatdan o'tish kerak).
  /// Kod noto'g'ri bo'lsa [ApiException].
  Future<AppUser?> verifyOtp(String phone, String code);
  Future<AppUser> register(String phone, ProfileInput input);
  Future<AppUser> updateProfile(ProfileInput input);
  Future<void> logout();
  Future<void> deleteAccount();

  // Spravochniklar
  List<Region> get regions;
  List<ProductType> get productTypes;
  List<PromoBanner> get banners;
  List<FaqItem> get faq;
  List<ShopCategory> get shopCategories;
  List<PickupPoint> get pickupPoints;
  List<ShopItem> get shopCatalog;

  /// Demo kodlar (faqat demo rejim uchun).
  List<String> get demoCodes;

  // QR va arizalar
  Future<CodeCheckResult> checkCode(String code);
  Future<SubmissionResult> createSubmission(SubmissionInput input);
  Future<List<Submission>> getSubmissions();

  // Ballar
  Future<PointsSummary> getPointsSummary();
  Future<List<PointTx>> getPointsHistory();

  // Do'kon
  Future<List<ShopItemView>> getShopItems();
  Future<Order> createOrder(OrderInput input);
  Future<List<Order>> getOrders();
  Future<Order> cancelOrder(String orderId);

  // Bildirishnomalar
  Future<List<AppNotification>> getNotifications();
  Future<void> markNotificationsRead();
}
