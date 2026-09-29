import 'package:flutter/material.dart';

import '../core/i18n.dart';

// ---------------------------------------------------------------------------
// Foydalanuvchi
// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.regionId,
    required this.city,
    required this.experienceYears,
    required this.createdAt,
    this.source = 'app',
  });

  /// 9 xonali raqam, +998 siz: 901234567
  final String phone;
  final String firstName;
  final String lastName;
  final String regionId;
  final String city;
  final int experienceYears;
  final DateTime createdAt;

  /// `app` yoki `telegram_import`
  final String source;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return (a + b).toUpperCase();
  }

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? regionId,
    String? city,
    int? experienceYears,
  }) =>
      AppUser(
        phone: phone,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        regionId: regionId ?? this.regionId,
        city: city ?? this.city,
        experienceYears: experienceYears ?? this.experienceYears,
        createdAt: createdAt,
        source: source,
      );

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'regionId': regionId,
        'city': city,
        'experienceYears': experienceYears,
        'createdAt': createdAt.toIso8601String(),
        'source': source,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        phone: j['phone'] as String,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        regionId: j['regionId'] as String,
        city: j['city'] as String,
        experienceYears: j['experienceYears'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        source: j['source'] as String? ?? 'app',
      );
}

class Region {
  const Region(this.id, this.name);
  final String id;
  final LocalizedText name;
}

/// Ro'yxatdan o'tish / profilni tahrirlash formasi ma'lumotlari.
class ProfileInput {
  const ProfileInput({
    required this.firstName,
    required this.lastName,
    required this.regionId,
    required this.city,
    required this.experienceYears,
  });

  final String firstName;
  final String lastName;
  final String regionId;
  final String city;
  final int experienceYears;
}

// ---------------------------------------------------------------------------
// Mahsulot va QR kod
// ---------------------------------------------------------------------------

class ProductType {
  const ProductType({
    required this.id,
    required this.name,
    required this.points,
  });

  final String id;
  final LocalizedText name;

  /// Shu mahsulot o'rnatilganda beriladigan ball.
  final int points;
}

enum CodeCheckStatus { valid, notFound, used, blocked, invalidFormat, rateLimited }

class CodeCheckResult {
  const CodeCheckResult({
    required this.code,
    required this.status,
    this.product,
    this.usedByYouAt,
  });

  final String code;
  final CodeCheckStatus status;
  final ProductType? product;

  /// Kod shu foydalanuvchi tomonidan ishlatilgan bo'lsa, sanasi.
  final DateTime? usedByYouAt;

  bool get isValid => status == CodeCheckStatus.valid;
}

// ---------------------------------------------------------------------------
// Ariza
// ---------------------------------------------------------------------------

enum SubmissionStatus { pending, approved, rejected }

class Submission {
  const Submission({
    required this.id,
    required this.code,
    required this.productTypeId,
    required this.points,
    required this.status,
    required this.createdAt,
    this.photoPaths = const [],
    this.address = '',
    this.lat,
    this.lng,
    this.clientPhone = '',
    this.comment = '',
    this.rejectReason,
    this.reviewedAt,
    this.source = 'app',
  });

  final String id;
  final String code;
  final String productTypeId;
  final int points;
  final SubmissionStatus status;
  final DateTime createdAt;
  final List<String> photoPaths;
  final String address;
  final double? lat;
  final double? lng;
  final String clientPhone;
  final String comment;
  final LocalizedText? rejectReason;
  final DateTime? reviewedAt;

  /// `app` yoki `telegram`
  final String source;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'productTypeId': productTypeId,
        'points': points,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'photoPaths': photoPaths,
        'address': address,
        'lat': lat,
        'lng': lng,
        'clientPhone': clientPhone,
        'comment': comment,
        'rejectReason': rejectReason?.toJson(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'source': source,
      };

  factory Submission.fromJson(Map<String, dynamic> j) => Submission(
        id: j['id'] as String,
        code: j['code'] as String,
        productTypeId: j['productTypeId'] as String,
        points: j['points'] as int,
        status: SubmissionStatus.values.byName(j['status'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        photoPaths: (j['photoPaths'] as List? ?? const []).cast<String>(),
        address: j['address'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        clientPhone: j['clientPhone'] as String? ?? '',
        comment: j['comment'] as String? ?? '',
        rejectReason: j['rejectReason'] == null
            ? null
            : LocalizedText.fromJson(
                (j['rejectReason'] as Map).cast<String, dynamic>()),
        reviewedAt: j['reviewedAt'] == null
            ? null
            : DateTime.parse(j['reviewedAt'] as String),
        source: j['source'] as String? ?? 'app',
      );
}

class SubmissionInput {
  const SubmissionInput({
    required this.code,
    required this.photoPaths,
    required this.address,
    this.lat,
    this.lng,
    this.clientPhone = '',
    this.comment = '',
  });

  final String code;
  final List<String> photoPaths;
  final String address;
  final double? lat;
  final double? lng;
  final String clientPhone;
  final String comment;
}

class SubmissionResult {
  const SubmissionResult({required this.submission, required this.newBalance});
  final Submission submission;
  final int newBalance;
}

// ---------------------------------------------------------------------------
// Ballar jurnali
// ---------------------------------------------------------------------------

enum PointTxType { earn, redeem, refund, imported, adjust }

class PointTx {
  const PointTx({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.refId,
    this.note = '',
  });

  final String id;

  /// Kirim musbat, chiqim manfiy.
  final int amount;
  final PointTxType type;
  final DateTime createdAt;

  /// Bog'liq ariza kodi yoki buyurtma raqami.
  final String? refId;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'refId': refId,
        'note': note,
      };

  factory PointTx.fromJson(Map<String, dynamic> j) => PointTx(
        id: j['id'] as String,
        amount: j['amount'] as int,
        type: PointTxType.values.byName(j['type'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        refId: j['refId'] as String?,
        note: j['note'] as String? ?? '',
      );
}

class PointsSummary {
  const PointsSummary({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.installsCount,
    required this.monthInstalls,
    required this.monthEarned,
  });

  final int balance;
  final int totalEarned;
  final int totalSpent;
  final int installsCount;
  final int monthInstalls;
  final int monthEarned;
}

// ---------------------------------------------------------------------------
// Do'kon va buyurtmalar
// ---------------------------------------------------------------------------

class ShopCategory {
  const ShopCategory(this.id, this.name);
  final String id;
  final LocalizedText name;
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });

  final String id;
  final String categoryId;
  final LocalizedText name;
  final LocalizedText description;

  /// Narx ballarda.
  final int price;

  /// Rasm o'rniga vaqtincha ikonka. Backend'dan rasm URL keladi.
  final IconData icon;
  final Color color;
}

/// Katalog elementi + joriy qoldiq.
class ShopItemView {
  const ShopItemView(this.item, this.stock);
  final ShopItem item;
  final int stock;
}

class PickupPoint {
  const PickupPoint(this.id, this.name);
  final String id;
  final LocalizedText name;
}

enum DeliveryType { courier, pickup }

enum OrderStatus { accepted, shipping, delivered, cancelled }

class Order {
  const Order({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.points,
    required this.deliveryType,
    required this.address,
    required this.contactPhone,
    required this.status,
    required this.createdAt,
    this.pickupPointId,
    this.updatedAt,
  });

  final String id;
  final String itemId;
  final int quantity;

  /// Jami sarflangan ball.
  final int points;
  final DeliveryType deliveryType;
  final String address;
  final String? pickupPointId;
  final String contactPhone;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order copyWith({OrderStatus? status, DateTime? updatedAt}) => Order(
        id: id,
        itemId: itemId,
        quantity: quantity,
        points: points,
        deliveryType: deliveryType,
        address: address,
        pickupPointId: pickupPointId,
        contactPhone: contactPhone,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'quantity': quantity,
        'points': points,
        'deliveryType': deliveryType.name,
        'address': address,
        'pickupPointId': pickupPointId,
        'contactPhone': contactPhone,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        itemId: j['itemId'] as String,
        quantity: j['quantity'] as int,
        points: j['points'] as int,
        deliveryType: DeliveryType.values.byName(j['deliveryType'] as String),
        address: j['address'] as String? ?? '',
        pickupPointId: j['pickupPointId'] as String?,
        contactPhone: j['contactPhone'] as String? ?? '',
        status: OrderStatus.values.byName(j['status'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: j['updatedAt'] == null
            ? null
            : DateTime.parse(j['updatedAt'] as String),
      );
}

class OrderInput {
  const OrderInput({
    required this.itemId,
    required this.quantity,
    required this.deliveryType,
    required this.address,
    required this.contactPhone,
    this.pickupPointId,
  });

  final String itemId;
  final int quantity;
  final DeliveryType deliveryType;
  final String address;
  final String? pickupPointId;
  final String contactPhone;
}

// ---------------------------------------------------------------------------
// Bildirishnomalar va kontent
// ---------------------------------------------------------------------------

enum NotificationKind { points, order, promo, system }

/// Matn tarjima kalitlari bilan saqlanadi, shuning uchun til almashtirilsa
/// eski bildirishnomalar ham yangi tilda ko'rinadi.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    this.args = const {},
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> args;
  final DateTime createdAt;
  final bool read;

  AppNotification markRead() => AppNotification(
        id: id,
        kind: kind,
        titleKey: titleKey,
        bodyKey: bodyKey,
        args: args,
        createdAt: createdAt,
        read: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'titleKey': titleKey,
        'bodyKey': bodyKey,
        'args': args,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        kind: NotificationKind.values.byName(j['kind'] as String),
        titleKey: j['titleKey'] as String,
        bodyKey: j['bodyKey'] as String,
        args: (j['args'] as Map? ?? const {}).cast<String, String>(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        read: j['read'] as bool? ?? false,
      );
}

class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText subtitle;
  final IconData icon;
  final List<Color> colors;
}

class FaqItem {
  const FaqItem(this.question, this.answer);
  final LocalizedText question;
  final LocalizedText answer;
}

/// Backend qaytaradigan biznes xatolari.
class ApiException implements Exception {
  const ApiException(this.messageKey, [this.args = const {}]);

  /// `kStrings` dagi tarjima kaliti.
  final String messageKey;
  final Map<String, Object?> args;

  @override
  String toString() => 'ApiException($messageKey)';
}
