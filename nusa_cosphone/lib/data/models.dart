import 'package:flutter/material.dart';

/// Days every rental covers for free, counted from the pickup date.
///
/// A booking up to this length costs nothing; anything longer is billed at the
/// owner's own daily rate.
const int kFreeRentalDays = 3;

/// The shortest rental a customer can book.
const int kMinRentalDays = kFreeRentalDays;

/// The longest rental a customer can book, which caps how far ahead the
/// derived end date may reach.
const int kMaxRentalDays = 30;

/// The last day of a rental of [days] days that starts on [start].
DateTime rentalPeriodEnd(DateTime start, int days) {
  final length = days < kMinRentalDays ? kMinRentalDays : days;
  return DateTime(start.year, start.month, start.day).add(
    Duration(days: length - 1),
  );
}

/// The inclusive day count of a period, matching the server's own arithmetic.
int daysBetween(DateTime start, DateTime end) {
  final from = DateTime(start.year, start.month, start.day);
  final to = DateTime(end.year, end.month, end.day);
  final span = to.difference(from).inDays + 1;
  return span < 1 ? 1 : span;
}

/// The days beyond [kFreeRentalDays] that cost the owner's extra rate.
int extraDaysFor(int days) {
  final extra = days - kFreeRentalDays;
  return extra > 0 ? extra : 0;
}

String _stringValue(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

int _intValue(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return _intValue(value) == 1 || value.toString().toLowerCase() == 'true';
}

DateTime _dateValueOrFallback(Object? value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed ?? fallback ?? DateTime.now();
}

DateTime? _nullableDateValue(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Read a string, treating an empty value as absent.
///
/// Laravel sends `null` for an unset nullable string, but a resource that
/// serializes `''` would otherwise surface as a blank field.
String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

/// Read a JSON array of URLs, dropping blanks and anything that is not a string.
List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String? _nestedValue(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value?.toString();
}

enum UserArea { customer, owner, admin }

/// How a customer settles a rental order.
///
/// Mirrors `App\Enums\PaymentMethod` on the Laravel side.
enum PaymentMethod {
  payAtOwner('pay_at_owner'),
  bankTransfer('bank_transfer');

  const PaymentMethod(this.value);

  /// The wire value the API expects.
  final String value;

  static PaymentMethod fromValue(String? value) => PaymentMethod.values
      .firstWhere(
        (method) => method.value == value,
        orElse: () => PaymentMethod.payAtOwner,
      );

  bool get isBankTransfer => this == PaymentMethod.bankTransfer;
  bool get isPayAtOwner => this == PaymentMethod.payAtOwner;
}

/// The bank coordinates a customer transfers to.
///
/// Returned for the costume's owner in the catalog and for the signed-in owner
/// in their own profile. [isComplete] tells the booking screen whether the
/// transfer option can be offered at all.
class BankDetails {
  const BankDetails({
    this.bankName = '',
    this.accountNumber = '',
    this.accountHolder = '',
    this.isComplete = false,
  });

  static const BankDetails empty = BankDetails();

  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final bool isComplete;

  bool get isEmpty => !isComplete && bankName.isEmpty;

  /// The account number formatted in the usual blocks of four digits.
  String get maskedAccountNumber {
    final digits = accountNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return accountNumber;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(
        digits.substring(i, (i + 4).clamp(0, digits.length)),
      );
    }
    return buffer.toString();
  }

  factory BankDetails.fromMap(Map<String, Object?> map) {
    final source = map['data'] is Map
        ? Map<String, Object?>.from(map['data'] as Map)
        : map;
    final bankName = _stringValue(source['bank_name']);
    final accountNumber = _stringValue(source['account_number']);
    final accountHolder = _stringValue(source['account_holder']);
    return BankDetails(
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
      isComplete:
          source.containsKey('is_complete')
          ? _boolValue(source['is_complete'])
          : bankName.isNotEmpty &&
                accountNumber.isNotEmpty &&
                accountHolder.isNotEmpty,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'bank_name': bankName,
    'account_number': accountNumber,
    'account_holder': accountHolder,
    'is_complete': isComplete,
  };
}

/// One page of a Laravel paginated collection.
///
/// Laravel returns `{data, links, meta}`; the previous client only ever read
/// `data` and silently showed the first page of every list. [hasMore] lets a
/// screen fetch the next page explicitly.
class Paginated<T> {
  const Paginated({required this.items, this.currentPage = 1, this.lastPage = 1});

  final List<T> items;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  static Paginated<T> fromJson<T>(
    dynamic payload,
    T Function(Map<String, Object?> item) parse,
  ) {
    final root = payload is Map ? Map<String, Object?>.from(payload) : null;
    final rawItems = root?['data'];
    final meta = root?['meta'] is Map
        ? Map<String, Object?>.from(root!['meta'] as Map)
        : const <String, Object?>{};

    // A bare list means the endpoint is not paginated.
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => parse(Map<String, Object?>.from(item)))
              .toList()
        : const <Never>[];

    return Paginated<T>(
      items: items.cast<T>(),
      currentPage: _intValue(meta['current_page'], 1),
      lastPage: _intValue(meta['last_page'], 1),
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    required this.role,
    required this.isAdmin,
    required this.isCosrentOwner,
    this.password = '',
    this.bankDetails = BankDetails.empty,
    this.hasBankAccount = false,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String username;
  final String role;
  final bool isAdmin;
  final bool isCosrentOwner;
  final String password;

  /// Bank coordinates, only ever populated for the signed-in owner's own
  /// account. The server returns `null` for anyone else.
  final BankDetails bankDetails;
  final bool hasBankAccount;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCustomer => !isAdmin && !isCosrentOwner;
  bool get isOwner => isCosrentOwner || role == 'owner';
  bool get canManageCatalog => isOwner || isAdmin;

  UserArea get area {
    if (isAdmin) return UserArea.admin;
    if (isOwner) return UserArea.owner;
    return UserArea.customer;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    final role = _stringValue(map['role'], 'customer');
    final bankRaw = map['bank_details'];
    final bankDetails = bankRaw is Map
        ? BankDetails.fromMap(Map<String, Object?>.from(bankRaw))
        : BankDetails.empty;
    return AppUser(
      id: _intValue(map['id']),
      name: _stringValue(map['name']),
      email: _stringValue(map['email']),
      username: _stringValue(map['username']),
      role: role,
      isAdmin: _boolValue(map['is_admin'], role == 'admin'),
      isCosrentOwner: _boolValue(map['is_cosrent_owner'], role == 'owner'),
      password: _stringValue(map['password']),
      bankDetails: bankDetails,
      hasBankAccount: map.containsKey('has_bank_account')
          ? _boolValue(map['has_bank_account'])
          : bankDetails.isComplete,
      emailVerifiedAt: _nullableDateValue(map['email_verified_at']),
      createdAt: _nullableDateValue(map['created_at']),
      updatedAt: _nullableDateValue(map['updated_at']),
    );
  }

  Map<String, Object?> toMap({bool includePassword = true}) {
    return <String, Object?>{
      if (id > 0) 'id': id,
      'name': name,
      'email': email,
      'username': username,
      'role': role,
      'is_admin': isAdmin ? 1 : 0,
      'is_cosrent_owner': isCosrentOwner ? 1 : 0,
      if (includePassword) 'password': password,
      'bank_details': bankDetails.toMap(),
      'has_bank_account': hasBankAccount,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? role,
    bool? isAdmin,
    bool? isCosrentOwner,
    String? password,
    BankDetails? bankDetails,
    bool? hasBankAccount,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      isCosrentOwner: isCosrentOwner ?? this.isCosrentOwner,
      password: password ?? this.password,
      bankDetails: bankDetails ?? this.bankDetails,
      hasBankAccount: hasBankAccount ?? this.hasBankAccount,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Costume {
  const Costume({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.size,
    required this.color,
    required this.description,
    required this.price,
    required this.extraPricePerDay,
    required this.isAvailable,
    this.characterName = '',
    this.stock = 1,
    this.isPublished = true,
    this.imageUrl,
    this.coverImageUrl,
    this.imageUrls = const <String>[],
    this.videoUrls = const <String>[],
    this.ownerBank = BankDetails.empty,
    this.ownerName = '',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final int ownerId;
  final String name;
  final String characterName;
  final String category;
  final String size;
  final String color;
  final String description;

  /// The costume's listed rate, kept for reference and for the owner form.
  ///
  /// Billing does not use it: the first [kFreeRentalDays] days are free, so a
  /// booking is charged from [extraPricePerDay] alone.
  final double price;

  /// What the owner charges for each day beyond the free period.
  ///
  /// The server has not shipped `extra_price_per_day` yet, so until that
  /// column lands this falls back to [price] and the app stays usable. Once
  /// the API always sends the key, that fallback stops firing.
  final double extraPricePerDay;
  final int stock;
  final bool isPublished;
  final bool isAvailable;
  final String? imageUrl;

  /// The picture used in list tiles: the explicit cover, or the first gallery
  /// image. The server resolves the fallback; this keeps a card from ever
  /// rendering an empty block.
  final String? coverImageUrl;

  /// Gallery images and clips as absolute URLs.
  final List<String> imageUrls;
  final List<String> videoUrls;

  /// The supplier's bank coordinates, for the booking screen.
  final BankDetails ownerBank;
  final String ownerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  int get imageCount => imageUrls.length;
  int get videoCount => videoUrls.length;
  bool get hasGallery => imageCount > 0 || videoCount > 0;

  /// The days this costume's extra rate applies to in a [days] long rental.
  ///
  /// Zero for a rental of exactly [kFreeRentalDays] days, then one per day
  /// past that.
  int billableDays(int days) => extraDaysFor(days);

  /// What a [days] long rental of [quantity] units costs.
  ///
  /// Mirrors the server's rule: [price] covers the included period and
  /// [extraPricePerDay] is added for each day beyond it. The server still
  /// recomputes the authoritative total.
  double estimateTotal({required int days, int quantity = 1}) =>
      RentalOrder.priceFor(
        basePrice: price,
        extraRate: extraPricePerDay,
        days: days,
        quantity: quantity,
      );

  /// The best single image for this costume, or `null` when it has none.
  String? get primaryImage {
    final cover = coverImageUrl;
    if (cover != null && cover.isNotEmpty) return cover;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    final single = imageUrl;
    if (single != null && single.isNotEmpty) return single;
    return null;
  }

  /// Every image plus every video, in the order the detail screen shows them.
  List<String> get galleryUrls => <String>[...imageUrls, ...videoUrls];

  bool get isArchived => deletedAt != null || !isPublished;

  factory Costume.fromMap(Map<String, Object?> map) {
    final owner = _asMap(map['owner']);
    final stock = map.containsKey('stock') ? _intValue(map['stock'], 1) : 1;
    final published = map.containsKey('is_published')
        ? _boolValue(map['is_published'], true)
        : true;
    final deletedAt = _nullableDateValue(map['deleted_at']);
    final availableFlag = map.containsKey('is_available')
        ? _boolValue(map['is_available'], true)
        : true;
    final imageUrl = map['image_url']?.toString();
    final imageUrls = _stringList(map['image_urls']);
    final cover = _stringValue(map['cover_image_url'], imageUrl ?? '');
    final price = _doubleValue(map['price_per_day']);
    return Costume(
      id: _intValue(map['id']),
      ownerId: _intValue(map['owner_id'], _intValue(owner['id'])),
      name: _stringValue(map['name']),
      characterName: _stringValue(map['character_name']),
      category: _stringValue(map['category']),
      size: _stringValue(map['size']),
      color: _stringValue(map['color']),
      description: _stringValue(map['description']),
      price: price,
      extraPricePerDay: map.containsKey('extra_price_per_day')
          ? _doubleValue(map['extra_price_per_day'])
          : price,
      stock: stock,
      isPublished: published,
      isAvailable: availableFlag && stock > 0 && published && deletedAt == null,
      imageUrl: (imageUrl?.isEmpty ?? true) ? null : imageUrl,
      coverImageUrl: (cover.isEmpty) ? null : cover,
      imageUrls: imageUrls,
      videoUrls: _stringList(map['video_urls']),
      ownerBank: map['owner_bank'] is Map
          ? BankDetails.fromMap(Map<String, Object?>.from(map['owner_bank'] as Map))
          : BankDetails.empty,
      ownerName: _nestedValue(owner, 'name') ?? _stringValue(map['owner_name']),
      createdAt: _nullableDateValue(map['created_at']),
      updatedAt: _nullableDateValue(map['updated_at']),
      deletedAt: deletedAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id > 0) 'id': id,
      'owner_id': ownerId,
      'name': name,
      'character_name': characterName,
      'category': category,
      'size': size,
      'color': color,
      'description': description,
      'price_per_day': price,
      'extra_price_per_day': extraPricePerDay,
      'stock': stock,
      'is_published': isPublished ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
      'image_url': imageUrl,
      'cover_image_url': coverImageUrl,
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'owner_bank': ownerBank.toMap(),
      'owner_name': ownerName,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Costume copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? characterName,
    String? category,
    String? size,
    String? color,
    String? description,
    double? price,
    double? extraPricePerDay,
    int? stock,
    bool? isPublished,
    bool? isAvailable,
    String? imageUrl,
    String? coverImageUrl,
    List<String>? imageUrls,
    List<String>? videoUrls,
    BankDetails? ownerBank,
    String? ownerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Costume(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      characterName: characterName ?? this.characterName,
      category: category ?? this.category,
      size: size ?? this.size,
      color: color ?? this.color,
      description: description ?? this.description,
      price: price ?? this.price,
      extraPricePerDay: extraPricePerDay ?? this.extraPricePerDay,
      stock: stock ?? this.stock,
      isPublished: isPublished ?? this.isPublished,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      ownerBank: ownerBank ?? this.ownerBank,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  List<Color> get artworkColors {
    final normalized = category.toLowerCase();
    if (normalized.contains('fantasy') || normalized.contains('magic')) {
      return const [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFE879F9)];
    }
    if (normalized.contains('heroic') ||
        normalized.contains('hero') ||
        normalized.contains('super')) {
      return const [Color(0xFF334155), Color(0xFF0EA5E9), Color(0xFF67E8F9)];
    }
    if (normalized.contains('modern')) {
      return const [Color(0xFFE11D48), Color(0xFFF97316), Color(0xFFFCD34D)];
    }
    return const [Color(0xFF334155), Color(0xFF4F46E5), Color(0xFF7C3AED)];
  }

  IconData get artworkIcon {
    final normalized = '$category $name $characterName'.toLowerCase();
    if (normalized.contains('fantasy') ||
        normalized.contains('magic') ||
        normalized.contains('witch')) {
      return Icons.auto_awesome;
    }
    if (normalized.contains('hero') || normalized.contains('super')) {
      return Icons.shield;
    }
    if (normalized.contains('school') || normalized.contains('sailor')) {
      return Icons.school;
    }
    if (normalized.contains('sport') || normalized.contains('athletic')) {
      return Icons.directions_run;
    }
    return Icons.checkroom;
  }
}

class RentalOrder {
  const RentalOrder({
    required this.id,
    required this.customerId,
    required this.costumeId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.durationInDays = 0,
    this.pricePerDay = 0,
    this.extraPricePerDay = 0,
    this.extraDays = 0,
    this.includedFeeTotal = 0,
    this.extraFeeTotal = 0,
    this.includedRentalDays = kFreeRentalDays,
    this.isReturnOverdue = false,
    this.issue,
    this.canApprove = false,
    this.canReject = false,
    this.canReturn = false,
    this.canReportLost = false,
    this.canComplete = false,
    this.canReportStain = false,
    this.decidedAt,
    this.approvedAt,
    this.ownerId = 0,
    this.quantity = 1,
    this.notes = '',
    this.customerNote = '',
    this.ownerNote = '',
    this.requestedStartDate,
    this.requestedEndDate,
    this.returnDueDate,
    this.returnedAt,
    this.returnedLate = false,
    this.completedAt,
    this.returnNote = '',
    this.paymentMethod = PaymentMethod.payAtOwner,
    this.paymentCode,
    this.hasPaymentProof = false,
    this.paymentProofFilename,
    this.canViewPaymentProof = false,
    this.ownerBank = BankDetails.empty,
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerEmail,
    this.costumeName,
    this.costumeCategory,
    this.costumeSize,
    this.costumeColor,
    this.costumeCharacterName,
  });

  final int id;
  final int ownerId;
  final int customerId;
  final int costumeId;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? requestedStartDate;
  final DateTime? requestedEndDate;
  final double totalPrice;
  final String status;
  final bool isReturnOverdue;

  /// How many days the order covers, counted from the start date.
  final int durationInDays;

  /// The rate snapshot taken when the order was priced, so a later costume
  /// rate change can never rewrite an already-priced order.
  final double pricePerDay;
  final double extraPricePerDay;

  /// The days beyond [includedRentalDays] that cost the extra rate.
  final int extraDays;

  /// The part of the total covered by the included period, and the part owed
  /// for the extra days.
  final double includedFeeTotal;
  final double extraFeeTotal;

  /// Days this order's base price already covers, as the server priced it.
  final int includedRentalDays;

  final RentalIssue? issue;
  final bool canApprove;
  final bool canReject;
  final bool canReturn;
  final bool canReportLost;
  final bool canComplete;
  final bool canReportStain;
  final DateTime? decidedAt;
  final DateTime? approvedAt;
  final String notes;
  final String customerNote;
  final String ownerNote;
  final DateTime? returnDueDate;
  final DateTime? returnedAt;
  final bool returnedLate;
  final DateTime? completedAt;
  final String returnNote;

  /// How the customer pays: in cash against a code, or by bank transfer.
  final PaymentMethod paymentMethod;

  /// The cash payment code, only issued for a pay-at-owner booking.
  final String? paymentCode;

  /// Whether a transfer receipt was uploaded.
  final bool hasPaymentProof;
  final String? paymentProofFilename;

  /// Whether the signed-in account may download the receipt.
  final bool canViewPaymentProof;

  /// The supplier's bank coordinates, for the transfer instructions.
  final BankDetails ownerBank;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? customerName;
  final String? customerEmail;
  final String? costumeName;
  final String? costumeCategory;
  final String? costumeSize;
  final String? costumeColor;
  final String? costumeCharacterName;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isReturned => status == 'returned';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasIssue => issue != null;
  bool get hasOpenIssue => issue?.isOpen ?? false;
  String get effectiveCustomerNote =>
      customerNote.isNotEmpty ? customerNote : notes;

  bool get isPaidAtOwner => paymentMethod.isPayAtOwner;
  bool get isPaidByTransfer => paymentMethod.isBankTransfer;

  /// The server's pricing rule, mirrored so the client estimate matches the
  /// authoritative total: the base rate covers the included days, and every
  /// day past them adds the extra rate, both scaled by the quantity.
  static double priceFor({
    required double basePrice,
    required double extraRate,
    required int days,
    int quantity = 1,
  }) =>
      (basePrice + extraRate * extraDaysFor(days)) * (quantity < 1 ? 1 : quantity);

  /// Whether the order carries a receipt the signed-in account can open.
  bool get canShowPaymentProof => hasPaymentProof && canViewPaymentProof;

  factory RentalOrder.fromMap(Map<String, Object?> map) {
    final customer = _asMap(map['customer']);
    final owner = _asMap(map['owner']);
    final costume = _asMap(map['costume']);
    final customerNote = _stringValue(map['customer_note']);
    final costumeName =
        _nestedValue(costume, 'name') ?? _nestedValue(map, 'costume_name');
    final status = _stringValue(map['status'], 'pending');
    final requestedStart = _nullableDateValue(map['requested_rental_start']);
    final requestedEnd = _nullableDateValue(map['requested_rental_end']);
    final startValue = map['rental_start'] ?? map['start_date'];
    final endValue = map['rental_end'] ?? map['end_date'];
    final startDate = _dateValueOrFallback(
      startValue,
      fallback: requestedStart,
    );
    final endDate = _dateValueOrFallback(
      endValue,
      fallback: requestedEnd ?? startDate,
    );
    final returnDueDate = _nullableDateValue(
      map['return_due_at'] ?? map['return_due_date'],
    );
    final rawIssue = map['issue'];
    var issueMap = _asMap(rawIssue);
    if (issueMap['data'] is Map) {
      issueMap = _asMap(issueMap['data']);
    } else if (issueMap.containsKey('data')) {
      issueMap = <String, dynamic>{};
    }
    final issue = issueMap.isEmpty ? null : RentalIssue.fromMap(issueMap);
    final hasOpenIssue = issue?.isOpen ?? false;
    final quantity = _intValue(map['quantity'], 1);
    final pricePerDay = _doubleValue(map['price_per_day']);
    final extraPricePerDay = _doubleValue(map['extra_price_per_day']);
    // A trimmed payload carries neither the breakdown nor the length, so both
    // fall back to what can be derived from the dates and the total.
    final durationInDays = map.containsKey('duration_in_days')
        ? _intValue(map['duration_in_days'])
        : daysBetween(startDate, endDate);
    final extraDays = map.containsKey('extra_days')
        ? _intValue(map['extra_days'])
        : extraDaysFor(durationInDays);
    final includedFeeTotal = map.containsKey('included_fee_total')
        ? _doubleValue(map['included_fee_total'])
        : pricePerDay * quantity;
    final extraFeeTotal = map.containsKey('extra_fee_total')
        ? _doubleValue(map['extra_fee_total'])
        : extraPricePerDay * extraDays * quantity;
    final isReturnOverdue = map.containsKey('is_return_overdue')
        ? _boolValue(map['is_return_overdue'])
        : status == 'approved' &&
              returnDueDate != null &&
              DateTime.now().isAfter(returnDueDate);
    final canApprove = map.containsKey('can_approve')
        ? _boolValue(map['can_approve'])
        : status == 'pending';
    final canReject = map.containsKey('can_reject')
        ? _boolValue(map['can_reject'])
        : status == 'pending';
    final rentalFinished = !endDate.isAfter(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    final canReturn =
        (map.containsKey('can_return')
            ? _boolValue(map['can_return'])
            : status == 'approved' && issue == null) &&
        rentalFinished &&
        issue == null;
    final canReportLost =
        (map.containsKey('can_report_lost')
            ? _boolValue(map['can_report_lost'])
            : status == 'approved') &&
        issue == null;
    final canComplete =
        (map.containsKey('can_complete')
            ? _boolValue(map['can_complete'])
            : status == 'returned') &&
        !hasOpenIssue;
    final canReportStain =
        (map.containsKey('can_report_stain')
            ? _boolValue(map['can_report_stain'])
            : status == 'returned') &&
        issue == null;
    final hasPaymentProof = _boolValue(map['has_payment_proof']);
    final proofFilename = _nullableString(map['payment_proof_filename']);
    return RentalOrder(
      id: _intValue(map['id']),
      ownerId: _intValue(
        map['owner_id'],
        _intValue(owner['id'], _intValue(costume['owner_id'])),
      ),
      customerId: _intValue(map['customer_id'], _intValue(customer['id'])),
      costumeId: _intValue(map['costume_id'], _intValue(costume['id'])),
      quantity: quantity,
      startDate: startDate,
      endDate: endDate,
      requestedStartDate: requestedStart,
      requestedEndDate: requestedEnd,
      totalPrice: _doubleValue(map['total_price']),
      status: status,
      durationInDays: durationInDays,
      pricePerDay: pricePerDay,
      extraPricePerDay: extraPricePerDay,
      extraDays: extraDays,
      includedFeeTotal: includedFeeTotal,
      extraFeeTotal: extraFeeTotal,
      includedRentalDays: map.containsKey('included_rental_days')
          ? _intValue(map['included_rental_days'], kFreeRentalDays)
          : kFreeRentalDays,
      isReturnOverdue: isReturnOverdue,
      issue: issue,
      canApprove: canApprove,
      canReject: canReject,
      canReturn: canReturn,
      canReportLost: canReportLost,
      canComplete: canComplete,
      canReportStain: canReportStain,
      decidedAt: _nullableDateValue(map['decided_at']),
      approvedAt: _nullableDateValue(map['approved_at']),
      notes: _stringValue(map['notes'], customerNote),
      customerNote: customerNote,
      ownerNote: _stringValue(map['owner_note']),
      returnDueDate: returnDueDate,
      returnedAt: _nullableDateValue(map['returned_at']),
      returnedLate: _boolValue(map['returned_late']),
      completedAt: _nullableDateValue(map['completed_at']),
      returnNote: _stringValue(map['return_note']),
      paymentMethod: map.containsKey('payment_method')
          ? PaymentMethod.fromValue(map['payment_method']?.toString())
          : PaymentMethod.payAtOwner,
      paymentCode: _nullableString(map['payment_code']),
      hasPaymentProof: hasPaymentProof,
      paymentProofFilename: proofFilename,
      // Without the flag, assume the parties to the order may open it. The
      // server always sends it, so this only covers a trimmed payload.
      canViewPaymentProof: map.containsKey('can_view_payment_proof')
          ? _boolValue(map['can_view_payment_proof'])
          : hasPaymentProof,
      ownerBank: map['owner_bank'] is Map
          ? BankDetails.fromMap(Map<String, Object?>.from(map['owner_bank'] as Map))
          : BankDetails.empty,
      createdAt: _nullableDateValue(map['created_at']),
      updatedAt: _nullableDateValue(map['updated_at']),
      customerName:
          _nestedValue(map, 'customer_name') ?? _nestedValue(customer, 'name'),
      customerEmail:
          _nestedValue(map, 'customer_email') ??
          _nestedValue(customer, 'email'),
      costumeName: costumeName,
      costumeCategory:
          _nestedValue(costume, 'category') ??
          _nestedValue(map, 'costume_category'),
      costumeSize:
          _nestedValue(costume, 'size') ?? _nestedValue(map, 'costume_size'),
      costumeColor:
          _nestedValue(costume, 'color') ?? _nestedValue(map, 'costume_color'),
      costumeCharacterName:
          _nestedValue(costume, 'character_name') ??
          _nestedValue(map, 'costume_character_name'),
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return <String, Object?>{
      if (id > 0) 'id': id,
      if (ownerId > 0) 'owner_id': ownerId,
      'customer_id': customerId,
      'costume_id': costumeId,
      'quantity': quantity,
      'rental_start': startDate.toIso8601String(),
      'rental_end': endDate.toIso8601String(),
      'requested_rental_start': (requestedStartDate ?? startDate)
          .toIso8601String(),
      'requested_rental_end': (requestedEndDate ?? endDate).toIso8601String(),
      // Compatibility aliases keep older local screens functional.
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'duration_in_days': durationInDays,
      'price_per_day': pricePerDay,
      'extra_price_per_day': extraPricePerDay,
      'extra_days': extraDays,
      'included_fee_total': includedFeeTotal,
      'extra_fee_total': extraFeeTotal,
      'included_rental_days': includedRentalDays,
      'is_return_overdue': isReturnOverdue,
      'can_approve': canApprove,
      'can_reject': canReject,
      'can_return': canReturn,
      'can_report_lost': canReportLost,
      'can_complete': canComplete,
      'can_report_stain': canReportStain,
      'decided_at': decidedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'total_price': totalPrice,
      'status': status,
      'notes': effectiveCustomerNote,
      'customer_note': effectiveCustomerNote,
      'owner_note': ownerNote,
      'return_due_at': returnDueDate?.toIso8601String(),
      'return_due_date': returnDueDate?.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'returned_late': returnedLate ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'return_note': returnNote,
      'payment_method': paymentMethod.value,
      'payment_code': paymentCode,
      'has_payment_proof': hasPaymentProof,
      'payment_proof_filename': paymentProofFilename,
      'can_view_payment_proof': canViewPaymentProof,
      'owner_bank': ownerBank.toMap(),
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': now,
    };
  }

  RentalOrder copyWith({
    int? id,
    int? ownerId,
    int? customerId,
    int? costumeId,
    int? quantity,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? requestedStartDate,
    DateTime? requestedEndDate,
    double? totalPrice,
    String? status,
    int? durationInDays,
    double? pricePerDay,
    double? extraPricePerDay,
    int? extraDays,
    double? includedFeeTotal,
    double? extraFeeTotal,
    int? includedRentalDays,
    bool? isReturnOverdue,
    RentalIssue? issue,
    bool? canApprove,
    bool? canReject,
    bool? canReturn,
    bool? canReportLost,
    bool? canComplete,
    bool? canReportStain,
    DateTime? decidedAt,
    DateTime? approvedAt,
    String? notes,
    String? customerNote,
    String? ownerNote,
    DateTime? returnDueDate,
    DateTime? returnedAt,
    bool? returnedLate,
    DateTime? completedAt,
    String? returnNote,
    PaymentMethod? paymentMethod,
    String? paymentCode,
    bool? hasPaymentProof,
    String? paymentProofFilename,
    bool? canViewPaymentProof,
    BankDetails? ownerBank,
    String? costumeName,
    String? costumeCategory,
    String? costumeSize,
    String? costumeColor,
    String? costumeCharacterName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentalOrder(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      customerId: customerId ?? this.customerId,
      costumeId: costumeId ?? this.costumeId,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      requestedStartDate: requestedStartDate ?? this.requestedStartDate,
      requestedEndDate: requestedEndDate ?? this.requestedEndDate,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      durationInDays: durationInDays ?? this.durationInDays,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      extraPricePerDay: extraPricePerDay ?? this.extraPricePerDay,
      extraDays: extraDays ?? this.extraDays,
      includedFeeTotal: includedFeeTotal ?? this.includedFeeTotal,
      extraFeeTotal: extraFeeTotal ?? this.extraFeeTotal,
      includedRentalDays: includedRentalDays ?? this.includedRentalDays,
      isReturnOverdue: isReturnOverdue ?? this.isReturnOverdue,
      issue: issue ?? this.issue,
      canApprove: canApprove ?? this.canApprove,
      canReject: canReject ?? this.canReject,
      canReturn: canReturn ?? this.canReturn,
      canReportLost: canReportLost ?? this.canReportLost,
      canComplete: canComplete ?? this.canComplete,
      canReportStain: canReportStain ?? this.canReportStain,
      decidedAt: decidedAt ?? this.decidedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      notes: notes ?? this.notes,
      customerNote: customerNote ?? this.customerNote,
      ownerNote: ownerNote ?? this.ownerNote,
      returnDueDate: returnDueDate ?? this.returnDueDate,
      returnedAt: returnedAt ?? this.returnedAt,
      returnedLate: returnedLate ?? this.returnedLate,
      completedAt: completedAt ?? this.completedAt,
      returnNote: returnNote ?? this.returnNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentCode: paymentCode ?? this.paymentCode,
      hasPaymentProof: hasPaymentProof ?? this.hasPaymentProof,
      paymentProofFilename: paymentProofFilename ?? this.paymentProofFilename,
      canViewPaymentProof: canViewPaymentProof ?? this.canViewPaymentProof,
      ownerBank: ownerBank ?? this.ownerBank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName,
      customerEmail: customerEmail,
      costumeName: costumeName ?? this.costumeName,
      costumeCategory: costumeCategory ?? this.costumeCategory,
      costumeSize: costumeSize ?? this.costumeSize,
      costumeColor: costumeColor ?? this.costumeColor,
      costumeCharacterName: costumeCharacterName ?? this.costumeCharacterName,
    );
  }
}

class RentalIssue {
  const RentalIssue({
    required this.id,
    required this.orderId,
    required this.reportedBy,
    required this.type,
    required this.description,
    required this.status,
    this.reporterId = 0,
    this.fineAmount = 0,
    this.replacementCost = 0,
    this.hasEvidence = false,
    this.evidenceUrl,
    this.finePaidAt,
    this.replacementSubmittedAt,
    this.replacementReceivedAt,
    this.resolvedAt,
    this.resolutionNote = '',
    this.createdAt,
    this.updatedAt,
    this.customerName,
    this.costumeName,
  });

  final int id;
  final int orderId;
  final int reportedBy;
  final int reporterId;
  final String type;
  final String description;
  final String status;
  final double fineAmount;
  final double replacementCost;
  final bool hasEvidence;
  final String? evidenceUrl;
  final DateTime? finePaidAt;
  final DateTime? replacementSubmittedAt;
  final DateTime? replacementReceivedAt;
  final DateTime? resolvedAt;
  final String resolutionNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? customerName;
  final String? costumeName;

  bool get isOpen => status == 'open' || status == 'pending';
  bool get finePaid => finePaidAt != null;
  bool get replacementReceived => replacementReceivedAt != null;

  factory RentalIssue.fromMap(Map<String, Object?> map) {
    final reporterUser = _asMap(map['reporter']);
    final customer = _asMap(map['customer']);
    final costume = _asMap(map['costume']);
    final reporter = _intValue(
      map['reporter_id'],
      _intValue(map['reported_by'], _intValue(reporterUser['id'])),
    );
    return RentalIssue(
      id: _intValue(map['id']),
      orderId: _intValue(map['rental_order_id'], _intValue(map['order_id'])),
      reportedBy: reporter,
      reporterId: reporter,
      type: _stringValue(map['type']),
      description: _stringValue(map['description']),
      status: _stringValue(map['status'], 'open'),
      fineAmount: _doubleValue(map['fine_amount']),
      replacementCost: _doubleValue(map['replacement_cost']),
      hasEvidence: _boolValue(map['has_evidence']),
      evidenceUrl: _nestedValue(map, 'evidence_url'),
      finePaidAt: _nullableDateValue(map['fine_paid_at']),
      replacementSubmittedAt: _nullableDateValue(
        map['replacement_submitted_at'],
      ),
      replacementReceivedAt: _nullableDateValue(map['replacement_received_at']),
      resolvedAt: _nullableDateValue(map['resolved_at']),
      resolutionNote: _stringValue(map['resolution_note']),
      createdAt: _nullableDateValue(map['created_at']),
      updatedAt: _nullableDateValue(map['updated_at']),
      customerName:
          _nestedValue(map, 'customer_name') ??
          _nestedValue(customer, 'name') ??
          _nestedValue(reporterUser, 'name'),
      costumeName:
          _nestedValue(map, 'costume_name') ?? _nestedValue(costume, 'name'),
    );
  }

  Map<String, Object?> toMap() {
    final now = DateTime.now().toIso8601String();
    return <String, Object?>{
      if (id > 0) 'id': id,
      'rental_order_id': orderId,
      'reporter_id': reporterId == 0 ? reportedBy : reporterId,
      'reported_by': reporterId == 0 ? reportedBy : reporterId,
      'type': type,
      'description': description,
      'status': status,
      'fine_amount': fineAmount,
      'replacement_cost': replacementCost,
      'has_evidence': hasEvidence,
      'evidence_url': evidenceUrl,
      'fine_paid_at': finePaidAt?.toIso8601String(),
      'replacement_submitted_at': replacementSubmittedAt?.toIso8601String(),
      'replacement_received_at': replacementReceivedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_note': resolutionNote,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': now,
    };
  }

  RentalIssue copyWith({
    int? id,
    int? orderId,
    int? reportedBy,
    int? reporterId,
    String? type,
    String? description,
    String? status,
    double? fineAmount,
    double? replacementCost,
    bool? hasEvidence,
    String? evidenceUrl,
    DateTime? finePaidAt,
    DateTime? replacementSubmittedAt,
    DateTime? replacementReceivedAt,
    DateTime? resolvedAt,
    String? resolutionNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentalIssue(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      fineAmount: fineAmount ?? this.fineAmount,
      replacementCost: replacementCost ?? this.replacementCost,
      hasEvidence: hasEvidence ?? this.hasEvidence,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      finePaidAt: finePaidAt ?? this.finePaidAt,
      replacementSubmittedAt:
          replacementSubmittedAt ?? this.replacementSubmittedAt,
      replacementReceivedAt:
          replacementReceivedAt ?? this.replacementReceivedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName,
      costumeName: costumeName,
    );
  }
}
