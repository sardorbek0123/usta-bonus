import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/qr_parser.dart';
import 'api_repository.dart';
import 'mock_seed.dart';
import 'models.dart';

/// Backend tayyor bo'lguncha ishlaydigan "server".
///
/// Barcha biznes qoidalari (bir martalik kod, ball jurnali, qoldiq,
/// rate limit) shu yerda, backend'dagi kabi bajariladi. Ma'lumotlar
/// SharedPreferences'da bitta JSON sifatida saqlanadi.
class LocalBackend implements ApiRepository {
  LocalBackend._(this._prefs);

  static const _dbKey = 'usta_bonus_db_v1';
  static const _sessionKey = 'session_phone';
  static const _langKey = 'lang';

  final SharedPreferences _prefs;
  late _Db _db;
  String? _sessionPhone;
  int _idCounter = 0;

  /// Kod -> mahsulot turi.
  final Map<String, String> _codeIndex = {};

  static Future<LocalBackend> create() async {
    final prefs = await SharedPreferences.getInstance();
    final backend = LocalBackend._(prefs);
    backend._buildCodeIndex();
    backend._load();
    return backend;
  }

  // -------------------------------------------------------------------------
  // Saqlash
  // -------------------------------------------------------------------------

  void _buildCodeIndex() {
    for (var i = 0; i < MockSeed.validCodes.length; i++) {
      _codeIndex[MockSeed.validCodes[i]] = MockSeed.productTypeForIndex(i);
    }
    for (var i = 0; i < MockSeed.demoUsedCodes.length; i++) {
      _codeIndex[MockSeed.demoUsedCodes[i]] = MockSeed.productTypeForIndex(i);
    }
    for (final c in MockSeed.blockedCodes) {
      _codeIndex[c] = MockSeed.productTypes.first.id;
    }
  }

  void _load() {
    final raw = _prefs.getString(_dbKey);
    if (raw != null) {
      try {
        _db = _Db.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return;
      } catch (_) {
        // Buzilgan ma'lumot: qaytadan yaratamiz.
      }
    }
    _db = _Db.empty();
    _seedDemoUser();
    _save();
  }

  void _save() => _prefs.setString(_dbKey, jsonEncode(_db.toJson()));

  Future<void> _latency([int ms = 350]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${_idCounter++}';

  String get _phone {
    final p = _sessionPhone;
    if (p == null) throw const ApiException('error_generic');
    return p;
  }

  List<Submission> _subs(String phone) =>
      _db.submissions.putIfAbsent(phone, () => []);
  List<PointTx> _ledger(String phone) => _db.ledger.putIfAbsent(phone, () => []);
  List<Order> _orders(String phone) => _db.orders.putIfAbsent(phone, () => []);
  List<AppNotification> _notifs(String phone) =>
      _db.notifications.putIfAbsent(phone, () => []);

  int _balance(String phone) =>
      _ledger(phone).fold(0, (sum, tx) => sum + tx.amount);

  void _notify(
    String phone,
    NotificationKind kind,
    String titleKey,
    String bodyKey, [
    Map<String, String> args = const {},
    DateTime? at,
  ]) {
    _notifs(phone).add(AppNotification(
      id: _newId(),
      kind: kind,
      titleKey: titleKey,
      bodyKey: bodyKey,
      args: args,
      createdAt: at ?? DateTime.now(),
    ));
  }

  // -------------------------------------------------------------------------
  // Demo usta: Telegram'dan ko'chirilgan tarix bilan
  // -------------------------------------------------------------------------

  void _seedDemoUser() {
    const phone = MockSeed.demoPhone;
    _db.users[phone] = AppUser(
      phone: phone,
      firstName: 'Demo',
      lastName: 'Usta',
      regionId: 'fargona',
      city: "Farg'ona",
      experienceYears: 10,
      createdAt: DateTime(2025, 7, 3),
      source: 'telegram_import',
    );

    var total = 0;
    for (var i = 0; i < MockSeed.demoUsedCodes.length; i++) {
      final code = MockSeed.demoUsedCodes[i];
      final type = MockSeed.productTypes[i % MockSeed.productTypes.length];
      final at = DateTime(2025, 7 + i, 5 + i * 2, 10 + i, 15);
      total += type.points;
      _db.usedCodes[code] = _UsedCode(phone, at);
      _subs(phone).add(Submission(
        id: _newId(),
        code: code,
        productTypeId: type.id,
        points: type.points,
        status: SubmissionStatus.approved,
        createdAt: at,
        reviewedAt: at,
        address: "Farg'ona sh.",
        source: 'telegram',
      ));
    }

    _subs(phone).add(Submission(
      id: _newId(),
      code: MockSeed.demoRejectedCode,
      productTypeId: MockSeed.productTypes.first.id,
      points: 0,
      status: SubmissionStatus.rejected,
      createdAt: DateTime(2026, 3, 12, 16, 40),
      reviewedAt: DateTime(2026, 3, 12, 16, 40),
      rejectReason: MockSeed.noPhotoReason,
      source: 'telegram',
    ));

    final importAt = DateTime(2026, 7, 1, 9);
    _ledger(phone).add(PointTx(
      id: _newId(),
      amount: total,
      type: PointTxType.imported,
      createdAt: importAt,
    ));
    _notify(phone, NotificationKind.system, 'n_import_title', 'n_import_body',
        {'points': '$total'}, importAt);

    // Avval berilgan sovg'a
    final orderAt = DateTime(2026, 8, 15, 11, 30);
    const orderId = '1001';
    const price = 300;
    _orders(phone).add(Order(
      id: orderId,
      itemId: 'thermos',
      quantity: 1,
      points: price,
      deliveryType: DeliveryType.pickup,
      pickupPointId: 'fergana',
      address: '',
      contactPhone: phone,
      status: OrderStatus.delivered,
      createdAt: orderAt,
      updatedAt: orderAt.add(const Duration(days: 3)),
    ));
    _ledger(phone).add(PointTx(
      id: _newId(),
      amount: -price,
      type: PointTxType.redeem,
      createdAt: orderAt,
      refId: orderId,
    ));
    _db.orderSeq = 1001;
  }

  // -------------------------------------------------------------------------
  // Sessiya va til
  // -------------------------------------------------------------------------

  @override
  Future<AppUser?> restoreSession() async {
    final phone = _prefs.getString(_sessionKey);
    if (phone == null) return null;
    final user = _db.users[phone];
    if (user == null) {
      await _prefs.remove(_sessionKey);
      return null;
    }
    _sessionPhone = phone;
    return user;
  }

  @override
  Future<String?> getSavedLanguage() async => _prefs.getString(_langKey);

  @override
  Future<void> saveLanguage(String code) => _prefs.setString(_langKey, code);

  // -------------------------------------------------------------------------
  // Avtorizatsiya
  // -------------------------------------------------------------------------

  @override
  Future<void> sendOtp(String phone) async {
    await _latency(600);
    if (!RegExp(r'^\d{9}$').hasMatch(phone)) {
      throw const ApiException('phone_invalid');
    }
    // Demo: SMS yuborilmaydi. Backend'da Eskiz orqali yuboriladi.
  }

  @override
  Future<AppUser?> verifyOtp(String phone, String code) async {
    await _latency(500);
    final ok = AppConfig.demoMode &&
        RegExp(r'^\d{6}$').hasMatch(code) &&
        code.split('').every((c) => c == code[0]);
    if (!ok) throw const ApiException('otp_invalid');

    _sessionPhone = phone;
    final user = _db.users[phone];
    if (user != null) await _prefs.setString(_sessionKey, phone);
    return user;
  }

  @override
  Future<AppUser> register(String phone, ProfileInput input) async {
    await _latency();
    final user = AppUser(
      phone: phone,
      firstName: input.firstName.trim(),
      lastName: input.lastName.trim(),
      regionId: input.regionId,
      city: input.city.trim(),
      experienceYears: input.experienceYears,
      createdAt: DateTime.now(),
    );
    _db.users[phone] = user;
    _sessionPhone = phone;
    _notify(phone, NotificationKind.system, 'n_welcome_title', 'n_welcome_body');
    _save();
    await _prefs.setString(_sessionKey, phone);
    return user;
  }

  @override
  Future<AppUser> updateProfile(ProfileInput input) async {
    await _latency();
    final current = _db.users[_phone];
    if (current == null) throw const ApiException('error_generic');
    final updated = current.copyWith(
      firstName: input.firstName.trim(),
      lastName: input.lastName.trim(),
      regionId: input.regionId,
      city: input.city.trim(),
      experienceYears: input.experienceYears,
    );
    _db.users[_phone] = updated;
    _save();
    return updated;
  }

  @override
  Future<void> logout() async {
    _sessionPhone = null;
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<void> deleteAccount() async {
    await _latency();
    final phone = _phone;
    _db.users.remove(phone);
    _db.submissions.remove(phone);
    _db.ledger.remove(phone);
    _db.orders.remove(phone);
    _db.notifications.remove(phone);
    _db.failedChecks.remove(phone);
    // Ishlatilgan kodlar qayta ishlatilmasligi uchun o'chirilmaydi.
    _save();
    await logout();
  }

  // -------------------------------------------------------------------------
  // Spravochniklar
  // -------------------------------------------------------------------------

  @override
  List<Region> get regions => MockSeed.regions;

  @override
  List<ProductType> get productTypes => MockSeed.productTypes;

  @override
  List<PromoBanner> get banners => MockSeed.banners;

  @override
  List<FaqItem> get faq => MockSeed.faq;

  @override
  List<ShopCategory> get shopCategories => MockSeed.shopCategories;

  @override
  List<PickupPoint> get pickupPoints => MockSeed.pickupPoints;

  @override
  List<ShopItem> get shopCatalog => MockSeed.shopItems;

  @override
  List<String> get demoCodes => MockSeed.validCodes
      .where((c) => !_db.usedCodes.containsKey(c))
      .take(12)
      .toList();

  ProductType _product(String id) =>
      MockSeed.productTypes.firstWhere((p) => p.id == id);

  // -------------------------------------------------------------------------
  // QR kod va arizalar
  // -------------------------------------------------------------------------

  bool _isRateLimited(String phone) {
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final list = _db.failedChecks.putIfAbsent(phone, () => []);
    list.removeWhere((t) => t.isBefore(hourAgo));
    return list.length >= AppConfig.maxFailedCodeChecksPerHour;
  }

  void _registerFailure(String phone) {
    _db.failedChecks.putIfAbsent(phone, () => []).add(DateTime.now());
    _save();
  }

  CodeCheckResult _check(String phone, String rawCode) {
    final code = QrParser.normalize(rawCode);
    if (_isRateLimited(phone)) {
      return CodeCheckResult(code: code, status: CodeCheckStatus.rateLimited);
    }
    if (!QrParser.isValidFormat(code)) {
      _registerFailure(phone);
      return CodeCheckResult(code: code, status: CodeCheckStatus.invalidFormat);
    }
    final productId = _codeIndex[code];
    if (productId == null) {
      _registerFailure(phone);
      return CodeCheckResult(code: code, status: CodeCheckStatus.notFound);
    }
    if (MockSeed.blockedCodes.contains(code)) {
      return CodeCheckResult(code: code, status: CodeCheckStatus.blocked);
    }
    final used = _db.usedCodes[code];
    if (used != null) {
      return CodeCheckResult(
        code: code,
        status: CodeCheckStatus.used,
        usedByYouAt: used.phone == phone ? used.at : null,
      );
    }
    return CodeCheckResult(
      code: code,
      status: CodeCheckStatus.valid,
      product: _product(productId),
    );
  }

  @override
  Future<CodeCheckResult> checkCode(String code) async {
    await _latency(500);
    return _check(_phone, code);
  }

  @override
  Future<SubmissionResult> createSubmission(SubmissionInput input) async {
    await _latency(900);
    final phone = _phone;

    // Server kodni qayta tekshiradi: ikki kishi bir vaqtda yuborsa ham
    // faqat bittasi o'tadi.
    final check = _check(phone, input.code);
    if (!check.isValid) {
      throw ApiException(switch (check.status) {
        CodeCheckStatus.used => 'code_used',
        CodeCheckStatus.blocked => 'code_blocked',
        CodeCheckStatus.rateLimited => 'too_many_attempts',
        CodeCheckStatus.invalidFormat => 'code_invalid_format',
        _ => 'code_not_found',
      });
    }
    if (input.photoPaths.length < AppConfig.minPhotos) {
      throw const ApiException('photos_required');
    }

    final id = _newId();
    final photos = await _storePhotos(id, input.photoPaths);
    final product = check.product!;
    final now = DateTime.now();

    final submission = Submission(
      id: id,
      code: check.code,
      productTypeId: product.id,
      points: product.points,
      status: SubmissionStatus.approved,
      createdAt: now,
      reviewedAt: now,
      photoPaths: photos,
      address: input.address.trim(),
      lat: input.lat,
      lng: input.lng,
      clientPhone: input.clientPhone.trim(),
      comment: input.comment.trim(),
    );

    _db.usedCodes[check.code] = _UsedCode(phone, now);
    _subs(phone).add(submission);
    _ledger(phone).add(PointTx(
      id: _newId(),
      amount: product.points,
      type: PointTxType.earn,
      createdAt: now,
      refId: check.code,
    ));
    _notify(phone, NotificationKind.points, 'n_points_title', 'n_points_body',
        {'points': '${product.points}', 'code': check.code});
    _save();

    return SubmissionResult(submission: submission, newBalance: _balance(phone));
  }

  /// "Yuklash": fotolar ilova papkasiga ko'chiriladi.
  Future<List<String>> _storePhotos(String id, List<String> paths) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/photos');
    if (!target.existsSync()) target.createSync(recursive: true);
    final result = <String>[];
    for (var i = 0; i < paths.length; i++) {
      final src = File(paths[i]);
      if (!src.existsSync()) continue;
      final dest = '${target.path}/${id}_$i.jpg';
      await src.copy(dest);
      result.add(dest);
    }
    return result;
  }

  @override
  Future<List<Submission>> getSubmissions() async {
    await _latency(250);
    final list = [..._subs(_phone)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // -------------------------------------------------------------------------
  // Ballar
  // -------------------------------------------------------------------------

  @override
  Future<PointsSummary> getPointsSummary() async {
    await _latency(200);
    final phone = _phone;
    final ledger = _ledger(phone);
    final approved =
        _subs(phone).where((s) => s.status == SubmissionStatus.approved);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final month = approved.where((s) => !s.createdAt.isBefore(monthStart));

    return PointsSummary(
      balance: _balance(phone),
      totalEarned: ledger
          .where((t) =>
              t.type == PointTxType.earn || t.type == PointTxType.imported)
          .fold(0, (s, t) => s + t.amount),
      totalSpent: ledger
          .where((t) => t.type == PointTxType.redeem)
          .fold(0, (s, t) => s - t.amount),
      installsCount: approved.length,
      monthInstalls: month.length,
      monthEarned: month.fold(0, (s, x) => s + x.points),
    );
  }

  @override
  Future<List<PointTx>> getPointsHistory() async {
    await _latency(250);
    final list = [..._ledger(_phone)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // -------------------------------------------------------------------------
  // Do'kon
  // -------------------------------------------------------------------------

  int _stock(String itemId) =>
      _db.stock[itemId] ?? MockSeed.initialStock[itemId] ?? 0;

  @override
  Future<List<ShopItemView>> getShopItems() async {
    await _latency(250);
    return [
      for (final item in MockSeed.shopItems) ShopItemView(item, _stock(item.id)),
    ];
  }

  @override
  Future<Order> createOrder(OrderInput input) async {
    await _latency(800);
    final phone = _phone;
    final item = MockSeed.shopItems.firstWhere((i) => i.id == input.itemId);
    final total = item.price * input.quantity;

    if (_stock(item.id) < input.quantity) {
      throw const ApiException('out_of_stock_error');
    }
    if (_balance(phone) < total) {
      throw const ApiException('insufficient_points');
    }

    _db.orderSeq += 1;
    final now = DateTime.now();
    final order = Order(
      id: '${_db.orderSeq}',
      itemId: item.id,
      quantity: input.quantity,
      points: total,
      deliveryType: input.deliveryType,
      address: input.address.trim(),
      pickupPointId: input.pickupPointId,
      contactPhone: input.contactPhone,
      status: OrderStatus.accepted,
      createdAt: now,
    );

    _db.stock[item.id] = _stock(item.id) - input.quantity;
    _orders(phone).add(order);
    _ledger(phone).add(PointTx(
      id: _newId(),
      amount: -total,
      type: PointTxType.redeem,
      createdAt: now,
      refId: order.id,
    ));
    _notify(phone, NotificationKind.order, 'n_order_title', 'n_order_created',
        {'id': order.id});
    _save();
    return order;
  }

  /// Demo: buyurtma holati vaqt o'tishi bilan o'zgaradi
  /// (30 soniyadan keyin "yo'lda", 2 daqiqadan keyin "topshirildi").
  /// Real tizimda holatni admin panel o'zgartiradi.
  void _advanceOrders(String phone) {
    final list = _orders(phone);
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      final o = list[i];
      if (o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.delivered) {
        continue;
      }
      final age = now.difference(o.createdAt);
      OrderStatus? next;
      if (age >= const Duration(minutes: 2)) {
        next = OrderStatus.delivered;
      } else if (age >= const Duration(seconds: 30) &&
          o.status == OrderStatus.accepted) {
        next = OrderStatus.shipping;
      }
      if (next != null && next != o.status) {
        list[i] = o.copyWith(status: next, updatedAt: now);
        _notify(
          phone,
          NotificationKind.order,
          'n_order_title',
          next == OrderStatus.delivered ? 'n_order_delivered' : 'n_order_shipping',
          {'id': o.id},
        );
        changed = true;
      }
    }
    if (changed) _save();
  }

  @override
  Future<List<Order>> getOrders() async {
    await _latency(250);
    _advanceOrders(_phone);
    final list = [..._orders(_phone)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    await _latency(600);
    final phone = _phone;
    _advanceOrders(phone);
    final list = _orders(phone);
    final index = list.indexWhere((o) => o.id == orderId);
    if (index < 0 || list[index].status != OrderStatus.accepted) {
      throw const ApiException('error_generic');
    }
    final order = list[index];
    final cancelled =
        order.copyWith(status: OrderStatus.cancelled, updatedAt: DateTime.now());
    list[index] = cancelled;
    _db.stock[order.itemId] = _stock(order.itemId) + order.quantity;
    _ledger(phone).add(PointTx(
      id: _newId(),
      amount: order.points,
      type: PointTxType.refund,
      createdAt: DateTime.now(),
      refId: order.id,
    ));
    _notify(phone, NotificationKind.order, 'n_order_title', 'n_order_cancelled',
        {'id': order.id, 'points': '${order.points}'});
    _save();
    return cancelled;
  }

  // -------------------------------------------------------------------------
  // Bildirishnomalar
  // -------------------------------------------------------------------------

  @override
  Future<List<AppNotification>> getNotifications() async {
    await _latency(200);
    _advanceOrders(_phone);
    final list = [..._notifs(_phone)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> markNotificationsRead() async {
    final list = _notifs(_phone);
    for (var i = 0; i < list.length; i++) {
      if (!list[i].read) list[i] = list[i].markRead();
    }
    _save();
  }
}

// ---------------------------------------------------------------------------
// Ichki saqlash formati
// ---------------------------------------------------------------------------

class _UsedCode {
  const _UsedCode(this.phone, this.at);
  final String phone;
  final DateTime at;

  Map<String, dynamic> toJson() => {'phone': phone, 'at': at.toIso8601String()};

  factory _UsedCode.fromJson(Map<String, dynamic> j) =>
      _UsedCode(j['phone'] as String, DateTime.parse(j['at'] as String));
}

class _Db {
  _Db({
    required this.users,
    required this.usedCodes,
    required this.submissions,
    required this.ledger,
    required this.orders,
    required this.notifications,
    required this.stock,
    required this.failedChecks,
    required this.orderSeq,
  });

  factory _Db.empty() => _Db(
        users: {},
        usedCodes: {},
        submissions: {},
        ledger: {},
        orders: {},
        notifications: {},
        stock: {},
        failedChecks: {},
        orderSeq: 1000,
      );

  final Map<String, AppUser> users;
  final Map<String, _UsedCode> usedCodes;
  final Map<String, List<Submission>> submissions;
  final Map<String, List<PointTx>> ledger;
  final Map<String, List<Order>> orders;
  final Map<String, List<AppNotification>> notifications;
  final Map<String, int> stock;
  final Map<String, List<DateTime>> failedChecks;
  int orderSeq;

  static Map<String, List<T>> _lists<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) {
    final map = (raw as Map? ?? const {}).cast<String, dynamic>();
    return map.map((k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => parse((e as Map).cast<String, dynamic>()))
              .toList(),
        ));
  }

  static Map<String, dynamic> _listsToJson<T>(
    Map<String, List<T>> m,
    Map<String, dynamic> Function(T) toJson,
  ) =>
      m.map((k, v) => MapEntry(k, v.map(toJson).toList()));

  factory _Db.fromJson(Map<String, dynamic> j) => _Db(
        users: (j['users'] as Map? ?? const {}).cast<String, dynamic>().map(
            (k, v) => MapEntry(
                k, AppUser.fromJson((v as Map).cast<String, dynamic>()))),
        usedCodes: (j['usedCodes'] as Map? ?? const {})
            .cast<String, dynamic>()
            .map((k, v) => MapEntry(
                k, _UsedCode.fromJson((v as Map).cast<String, dynamic>()))),
        submissions: _lists(j['submissions'], Submission.fromJson),
        ledger: _lists(j['ledger'], PointTx.fromJson),
        orders: _lists(j['orders'], Order.fromJson),
        notifications: _lists(j['notifications'], AppNotification.fromJson),
        stock: Map<String, int>.from(j['stock'] as Map? ?? const {}),
        failedChecks: (j['failedChecks'] as Map? ?? const {})
            .cast<String, dynamic>()
            .map((k, v) => MapEntry(
                k,
                (v as List)
                    .map((e) => DateTime.parse(e as String))
                    .toList())),
        orderSeq: j['orderSeq'] as int? ?? 1000,
      );

  Map<String, dynamic> toJson() => {
        'users': users.map((k, v) => MapEntry(k, v.toJson())),
        'usedCodes': usedCodes.map((k, v) => MapEntry(k, v.toJson())),
        'submissions': _listsToJson<Submission>(submissions, (s) => s.toJson()),
        'ledger': _listsToJson<PointTx>(ledger, (t) => t.toJson()),
        'orders': _listsToJson<Order>(orders, (o) => o.toJson()),
        'notifications':
            _listsToJson<AppNotification>(notifications, (n) => n.toJson()),
        'stock': stock,
        'failedChecks': failedChecks.map(
            (k, v) => MapEntry(k, v.map((d) => d.toIso8601String()).toList())),
        'orderSeq': orderSeq,
      };
}
