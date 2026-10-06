import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'models.dart';

/// Repository boundary for the Laravel/MySQL backend.
///
/// The UI only depends on this class; the transport, Sanctum token, and
/// response shape stay here so the screens remain role-focused.
class CosrentRepository {
  CosrentRepository(this.client);

  final ApiClient client;
  AppUser? _currentUser;

  /// The maximum gallery size the server accepts, mirrored from
  /// `App\Http\Requests\Api\V1\SaveCostumeRequest`.
  static const int maxGalleryImages = 8;
  static const int maxGalleryVideos = 2;

  /// The maximum upload size of a single gallery image, in bytes.
  static const int maxImageBytes = 5 * 1024 * 1024;

  /// The maximum upload size of a single gallery video, in bytes.
  static const int maxVideoBytes = 25 * 1024 * 1024;

  AppUser? get currentUser => _currentUser;

  Future<void> initialize() => client.initialize();

  Future<AppUser?> restoreSession() async {
    if (!client.hasToken) return null;
    try {
      final response = await client.getJson('/auth/me');
      final user = _userFromResponse(response);
      _currentUser = user;
      return user;
    } on ApiException catch (error) {
      if (error.isUnauthorized) await client.clearToken();
      return null;
    }
  }

  Future<AppUser?> authenticate(String identifier, String password) async {
    try {
      final response = await client.postJson(
        '/auth/login',
        authenticated: false,
        body: {
          'login': identifier.trim().toLowerCase(),
          'password': password,
          'device_name': 'flutter-mobile',
        },
      );
      final map = _asMap(response);
      final token = map['token']?.toString();
      if (token == null || token.isEmpty) return null;
      await client.setToken(token);
      final user = AppUser.fromMap(_asMap(map['user']));
      _currentUser = user;
      return user;
    } on ApiException catch (error) {
      if (error.isValidation || error.isUnauthorized) return null;
      rethrow;
    }
  }

  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
    String? username,
    String? confirmation,
    String accountType = 'customer',
  }) async {
    final response = await client.postJson(
      '/auth/register',
      authenticated: false,
      body: {
        'name': name.trim(),
        'username': username?.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': confirmation ?? password,
        'account_type': accountType == 'owner' ? 'cosrent_owner' : 'customer',
        'device_name': 'flutter-mobile',
      },
    );
    final map = _asMap(response);
    final token = map['token']?.toString();
    if (token != null && token.isNotEmpty) await client.setToken(token);
    final user = AppUser.fromMap(_asMap(map['user']));
    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    try {
      if (client.hasToken) await client.postJson('/auth/logout');
    } finally {
      _currentUser = null;
      await client.clearToken();
    }
  }

  /// Update the signed-in account. Omitted fields are left untouched.
  ///
  /// [bankDetails] is written as a unit: the server rejects a partial trio, so
  /// all three values travel together or none of them do.
  Future<AppUser> updateProfile({
    String? name,
    String? username,
    String? email,
    String? password,
    String? confirmation,
    String? currentPassword,
    BankDetails? bankDetails,
  }) async {
    final body = <String, Object?>{
      if (name != null) 'name': name.trim(),
      if (username != null) 'username': username.trim().toLowerCase(),
      if (email != null) 'email': email.trim().toLowerCase(),
      if (password != null && password.isNotEmpty) ...{
        'password': password,
        'password_confirmation': confirmation ?? password,
        'current_password': currentPassword ?? '',
      },
      if (bankDetails != null) ...{
        'bank_name': bankDetails.bankName.trim(),
        'bank_account_number': bankDetails.accountNumber.trim(),
        'bank_account_holder': bankDetails.accountHolder.trim(),
      },
    };

    final response = await client.patchJson('/auth/profile', body: body);
    final user = _userFromResponse(response);
    _currentUser = user;
    return user;
  }

  /// Permanently delete the signed-in account. The local session is cleared
  /// even when the request fails, so the device never keeps a dead token.
  Future<void> deleteAccount(String password) async {
    try {
      await client.deleteJson('/auth/account', body: {'password': password});
    } finally {
      _currentUser = null;
      await client.clearToken();
    }
  }

  Future<AppUser?> getUser(int id) async {
    if (_currentUser?.id == id) return _currentUser;
    try {
      final response = await client.getJson('/auth/me');
      return _userFromResponse(response);
    } on ApiException catch (error) {
      if (error.isUnauthorized) await client.clearToken();
      return null;
    }
  }

  Future<List<AppUser>> getUsers() async {
    final response = await client.getJson(
      '/admin/users',
      query: const <String, String>{'per_page': '100'},
    );
    return _maps(response).map(AppUser.fromMap).toList();
  }

  Future<int> createUser({
    required String name,
    required String email,
    required String password,
    String? username,
    String role = 'customer',
    bool isAdmin = false,
    bool isCosrentOwner = false,
  }) async {
    final resolvedRole = isAdmin
        ? 'admin'
        : (isCosrentOwner || role == 'owner' ? 'owner' : 'customer');
    final response = await client.postJson(
      '/admin/users',
      body: {
        'name': name.trim(),
        'username': username?.trim().toLowerCase(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
        'role': resolvedRole,
      },
    );
    return _intValue(_asMap(response)['id']);
  }

  Future<void> updateUser(AppUser user) async {
    final body = <String, dynamic>{
      'name': user.name.trim(),
      'username': user.username.trim().toLowerCase(),
      'email': user.email.trim().toLowerCase(),
      'role': user.isAdmin ? 'admin' : (user.isOwner ? 'owner' : 'customer'),
    };
    if (user.password.isNotEmpty) {
      body['password'] = user.password;
      body['password_confirmation'] = user.password;
    }
    await client.patchJson('/admin/users/${user.id}', body: body);
  }

  Future<void> deleteUser(int id) async {
    await client.deleteJson('/admin/users/$id');
  }

  Future<Paginated<Costume>> getCostumes({
    String search = '',
    String category = 'Semua',
    bool availableOnly = false,
    bool publishedOnly = false,
    int page = 1,
    int perPage = 50,
  }) async {
    final query = <String, String>{
      'per_page': perPage.clamp(1, 100).toString(),
      'page': page.clamp(1, 10000).toString(),
    };
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (category.trim().isNotEmpty && category != 'Semua') {
      query['category'] = category.trim();
    }
    if (publishedOnly) query['published_only'] = '1';
    if (availableOnly) query['availability'] = 'available';
    final response = await client.getJson(_costumePath, query: query);
    return Paginated.fromJson<Costume>(response, _parseCostume);
  }

  Future<Costume?> getCostume(int id) async {
    try {
      final response = await client.getJson('$_costumePath/$id');
      return _parseCostume(_asMap(response));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<String>> getCostumeCategories() async {
    try {
      final response = await client.getJson('/costumes/categories');
      final values = _unwrap(response);
      if (values is List) {
        return [
          'Semua',
          ...values
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty),
        ];
      }
    } on ApiException {
      // Older backends may not expose the categories endpoint.
    }
    final costumes = await getCostumes().then((page) => page.items);
    final categories = costumes.map((item) => item.category).toSet().toList()
      ..sort();
    return ['Semua', ...categories];
  }

  /// Create a costume listing, uploading any new gallery media.
  Future<void> createCostume(
    Costume costume, {
    List<String> imagePaths = const <String>[],
    List<String> videoPaths = const <String>[],
  }) async {
    final body = _costumeBody(costume);
    if (_isAdmin && costume.ownerId > 0) body['owner_id'] = costume.ownerId;
    await _saveCostume(_costumePath, body, imagePaths, videoPaths);
  }

  /// Update a costume listing, applying gallery additions and removals.
  Future<void> updateCostume(
    Costume costume, {
    List<String> imagePaths = const <String>[],
    List<String> videoPaths = const <String>[],
    List<String> removeImageUrls = const <String>[],
    List<String> removeVideoUrls = const <String>[],
  }) async {
    final body = _costumeBody(costume);
    // The server matches removals against the stored paths it holds, which are
    // the tail of each public URL.
    if (removeImageUrls.isNotEmpty) {
      body['remove_images'] = removeImageUrls.map(_mediaPath).toList();
    }
    if (removeVideoUrls.isNotEmpty) {
      body['remove_videos'] = removeVideoUrls.map(_mediaPath).toList();
    }
    await _saveCostume(
      '$_costumePath/${costume.id}',
      body,
      imagePaths,
      videoPaths,
      method: 'patch',
    );
  }

  /// Post or patch a listing as multipart when media is involved.
  ///
  /// A listing without uploads goes over plain JSON, which keeps the common
  /// case cheap and avoids a multipart body the server would have to parse for
  /// no reason.
  Future<void> _saveCostume(
    String path,
    Map<String, dynamic> body,
    List<String> imagePaths,
    List<String> videoPaths, {
    String method = 'post',
  }) async {
    final files = <String, http.MultipartFile>{};

    for (final entry in imagePaths.indexed) {
      files['images[${entry.$1}]'] = await http.MultipartFile.fromPath(
        'images[${entry.$1}]',
        entry.$2,
      );
    }
    for (final entry in videoPaths.indexed) {
      files['videos[${entry.$1}]'] = await http.MultipartFile.fromPath(
        'videos[${entry.$1}]',
        entry.$2,
      );
    }

    if (files.isEmpty) {
      if (method == 'patch') {
        await client.patchJson(path, body: body);
      } else {
        await client.postJson(path, body: body);
      }
      return;
    }

    final fields = body.map(
      (key, value) => MapEntry<String, String>(key, _formValue(value)),
    );

    if (method == 'patch') {
      await client.patchMultipart(path, fields: fields, files: files);
    } else {
      await client.postMultipart(path, fields: fields, files: files);
    }
  }

  /// Render a JSON value as the string a form field expects.
  ///
  /// Multipart fields are always text, so a list becomes a JSON array and a
  /// boolean becomes `1`/`0`, matching what PHP parses back.
  String _formValue(Object? value) {
    if (value == null) return '';
    if (value is bool) return value ? '1' : '0';
    if (value is List) {
      return value.map(_formValue).toList().toString();
    }
    return value.toString();
  }

  /// Reduce a public media URL back to the stored path the server expects.
  ///
  /// The server intersects removals against the paths it already holds, so a
  /// client that sends a full URL would silently remove nothing.
  String _mediaPath(String url) {
    final marker = '/storage/';
    final index = url.indexOf(marker);
    if (index < 0) return url;
    return url.substring(index + marker.length);
  }

  Future<void> deleteCostume(int id) async {
    await client.deleteJson('$_costumePath/$id');
  }

  Future<Paginated<RentalOrder>> getOrders({String? status, int page = 1}) async {
    final query = <String, String>{
      'per_page': '50',
      'page': page.clamp(1, 10000).toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    final response = await client.getJson(_orderPath, query: query);
    return Paginated.fromJson<RentalOrder>(response, _parseOrder);
  }

  Future<RentalOrder?> getOrder(int id) async {
    try {
      final response = await client.getJson('$_orderPath/$id');
      return _parseOrder(_asMap(response));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Place a booking request.
  ///
  /// A cash booking sends plain JSON; a bank transfer has to carry the receipt,
  /// so it goes as multipart. `total_price` and the customer identity stay
  /// server-owned so the client can never disagree with the rental window.
  Future<RentalOrder?> createOrder({
    required int costumeId,
    required DateTime startDate,
    required int days,
    String notes = '',
    int quantity = 1,
    PaymentMethod paymentMethod = PaymentMethod.payAtOwner,
    String? paymentProofPath,
  }) async {
    final length = days < kMinRentalDays ? kMinRentalDays : days;
    final fields = <String, String>{
      'quantity': quantity.toString(),
      // The server prices from these two dates and derives the length itself,
      // so the end date is computed here rather than chosen by hand.
      'rental_start': _dateOnly(startDate),
      'rental_end': _dateOnly(rentalPeriodEnd(startDate, length)),
      'payment_method': paymentMethod.value,
      'customer_note': notes.trim(),
    };

    final path = '/customer/costumes/$costumeId/orders';

    if (paymentMethod.isBankTransfer) {
      if (paymentProofPath == null || paymentProofPath.isEmpty) {
        throw const ApiException(
          statusCode: 422,
          message: 'Lampirkan bukti transfer terlebih dahulu.',
        );
      }
      final response = await client.postMultipart(
        path,
        fields: fields,
        files: {
          'payment_proof': await http.MultipartFile.fromPath(
            'payment_proof',
            paymentProofPath,
          ),
        },
      );
      return _unwrap(response) is Map
          ? RentalOrder.fromMap(_asMap(response))
          : null;
    }

    final response = await client.postJson(path, body: fields);
    return _unwrap(response) is Map
        ? RentalOrder.fromMap(_asMap(response))
        : null;
  }

  /// Fetch the transfer receipt for an order.
  ///
  /// The endpoint is role-scoped on the server, so the path is derived from the
  /// signed-in account rather than passed in by the screen.
  Future<ApiFile> getPaymentProof(int orderId) async {
    final path = _isAdmin || (_currentUser?.isOwner ?? false)
        ? '/owner/orders/$orderId/payment-proof'
        : '/customer/orders/$orderId/payment-proof';
    return client.getFile(path);
  }

  /// Change an order's status.
  ///
  /// [rentalDays] only matters when approving: the server prices the order
  /// from the requested length, and the first [kMinRentalDays] days are already
  /// covered by the base price. It is omitted for every other transition.
  Future<void> updateOrderStatus(
    int id,
    String status, {
    String? notes,
    int? rentalDays,
  }) async {
    if (_isAdmin) {
      await client.patchJson(
        '/admin/orders/$id/status',
        body: {'status': status},
      );
      return;
    }

    switch (status) {
      case 'approved':
        await client.patchJson(
          '/owner/orders/$id/approve',
          body: {
            'owner_note': notes?.trim(),
            'rental_days': ?rentalDays,
          },
        );
        return;
      case 'rejected':
        await client.patchJson(
          '/owner/orders/$id/reject',
          body: {
            'owner_note': notes?.trim().isNotEmpty == true
                ? notes!.trim()
                : 'Pesanan ditolak oleh owner.',
          },
        );
        return;
      case 'returned':
        await client.postJson(
          '/customer/orders/$id/return',
          body: {'return_note': notes?.trim()},
        );
        return;
      case 'completed':
        await client.patchJson('/owner/orders/$id/complete');
        return;
      default:
        throw StateError('Status pesanan tidak didukung: $status');
    }
  }

  Future<void> deleteOrder(int id) async {
    if (_isAdmin) {
      await client.deleteJson('/admin/orders/$id');
    } else {
      await client.deleteJson('/customer/orders/$id');
    }
  }

  Future<List<RentalIssue>> getIssues({int? orderId, String? status}) async {
    if (_currentUser == null) return const [];
    final query = <String, String>{'per_page': '100'};
    if (status != null && status.isNotEmpty && status != 'all') {
      query['status'] = status;
    }
    // The server scopes both endpoints to the authenticated user, so only
    // owners and admins can list issues at all.
    final path = _isAdmin ? '/admin/issues' : '/owner/issues';
    final response = await client.getJson(path, query: query);
    final issues = _maps(response).map(RentalIssue.fromMap).toList();
    if (orderId == null) return issues;
    return issues.where((issue) => issue.orderId == orderId).toList();
  }

  /// Fetch the evidence photo attached to an issue report.
  Future<ApiFile> getIssueEvidence(int orderId, int issueId) =>
      client.getFile('/owner/orders/$orderId/issues/$issueId/evidence');

  Future<void> createIssue({
    required int orderId,
    required int reportedBy,
    required String type,
    required String description,
    double fineAmount = 0,
    double? replacementCost,
    String? evidencePath,
  }) async {
    if (type == 'stain') {
      if (fineAmount < 1) {
        throw StateError('Denda minimal Rp1.');
      }
      await _sendIssue(
        '/owner/orders/$orderId/issues',
        type: type,
        description: description,
        amount: fineAmount,
        evidencePath: evidencePath,
      );
    } else if (type == 'lost') {
      if (replacementCost == null || replacementCost < 1) {
        throw StateError('Biaya replacement minimal Rp1.');
      }
      await _sendIssue(
        '/customer/orders/$orderId/loss-report',
        type: type,
        description: description,
        amount: replacementCost,
        evidencePath: evidencePath,
      );
    } else {
      throw StateError('Jenis masalah harus stain atau lost.');
    }
  }

  Future<void> _sendIssue(
    String path, {
    required String type,
    required String description,
    required double amount,
    String? evidencePath,
  }) async {
    if (evidencePath == null || evidencePath.isEmpty) {
      throw StateError('Lampirkan bukti foto atau PDF terlebih dahulu.');
    }
    final amountField = type == 'stain' ? 'fine_amount' : 'replacement_cost';
    final fileField = type == 'stain' ? 'evidence' : 'replacement_proof';
    final fields = <String, String>{
      'description': description.trim(),
      amountField: amount.round().toString(),
    };
    await client.postMultipart(
      path,
      fields: fields,
      files: {
        fileField: await http.MultipartFile.fromPath(fileField, evidencePath),
      },
    );
  }

  Future<void> updateIssueStatus(
    int id,
    String status, {
    String resolutionNote = '',
    RentalIssue? issue,
  }) async {
    if (status != 'resolved') {
      throw StateError('Status laporan harus resolved.');
    }
    final type = issue?.type ?? '';
    final body = <String, dynamic>{
      'fine_paid': type == 'stain',
      'replacement_received': type == 'lost',
      'resolution_note': resolutionNote.trim(),
    };
    if (_isAdmin) {
      await client.patchJson('/admin/issues/$id/resolve', body: body);
    } else {
      if (issue == null) {
        throw StateError('Data laporan tidak ditemukan.');
      }
      await client.patchJson(
        '/owner/orders/${issue.orderId}/issues/$id/resolve',
        body: body,
      );
    }
  }

  Future<void> deleteIssue(int id) async {
    await client.deleteJson('/admin/issues/$id');
  }

  Future<Map<String, int>> getDashboardStats() async {
    final response = await client.getJson(
      _isAdmin ? '/admin/dashboard' : '/dashboard',
    );
    final map = _asMap(response);
    return <String, int>{
      for (final entry in map.entries)
        if (entry.value is num) entry.key: (entry.value as num).toInt(),
    };
  }

  /// Every list endpoint is scoped to the authenticated account on the
  /// server, so the role alone decides the path.
  String get _costumePath {
    if (_isAdmin) return '/admin/costumes';
    if (_currentUser?.isOwner ?? false) return '/owner/costumes';
    return '/costumes';
  }

  String get _orderPath {
    if (_isAdmin) return '/admin/orders';
    if (_currentUser?.isOwner ?? false) return '/owner/orders';
    return '/customer/orders';
  }

  Map<String, dynamic> _costumeBody(Costume costume) {
    return <String, dynamic>{
      'name': costume.name.trim(),
      'character_name': costume.characterName.trim(),
      'category': costume.category.trim(),
      'size': costume.size.trim(),
      'color': costume.color.trim(),
      'description': costume.description.trim(),
      'image_url': costume.imageUrl?.trim(),
      'price_per_day': costume.price.round(),
      'extra_price_per_day': costume.extraPricePerDay.round(),
      'stock': costume.stock,
      'is_published': costume.isPublished,
    };
  }

  /// Rewrite every entry of a media list, dropping any that cannot be
  /// rewritten.
  List<String> _retarget(List<String> urls) => urls
      .map(client.normalizeMediaUrl)
      .whereType<String>()
      .toList(growable: false);

  /// Parse a costume and retarget its media onto the active API host.
  Costume _parseCostume(Map<String, Object?> map) {
    final costume = Costume.fromMap(map);
    final hasMedia =
        costume.imageUrl != null ||
        costume.coverImageUrl != null ||
        costume.imageUrls.isNotEmpty ||
        costume.videoUrls.isNotEmpty;
    if (!hasMedia) return costume;

    return costume.copyWith(
      imageUrl: client.normalizeMediaUrl(costume.imageUrl),
      coverImageUrl: client.normalizeMediaUrl(costume.coverImageUrl),
      imageUrls: _retarget(costume.imageUrls),
      videoUrls: _retarget(costume.videoUrls),
    );
  }

  /// Parse an order and retarget any media the costume snapshot carries.
  RentalOrder _parseOrder(Map<String, Object?> map) {
    final order = RentalOrder.fromMap(map);
    final raw = map['costume'];
    if (raw is! Map) return order;

    // The order embeds a costume snapshot, so its gallery has to be
    // rewritten too or the detail screen shows broken pictures.
    final costume = _parseCostume(Map<String, Object?>.from(raw));

    return order.copyWith(
      costumeName: costume.name.isEmpty ? order.costumeName : costume.name,
      costumeCategory: costume.category.isEmpty
          ? order.costumeCategory
          : costume.category,
      costumeSize: costume.size.isEmpty ? order.costumeSize : costume.size,
      costumeColor: costume.color.isEmpty ? order.costumeColor : costume.color,
      costumeCharacterName: costume.characterName.isEmpty
          ? order.costumeCharacterName
          : costume.characterName,
    );
  }

  AppUser _userFromResponse(dynamic response) {
    return AppUser.fromMap(_asMap(_unwrap(response)));
  }

  dynamic _unwrap(dynamic value) {
    if (value is Map && value.containsKey('data')) return value['data'];
    return value;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    final unwrapped = _unwrap(value);
    if (unwrapped is Map) return Map<String, dynamic>.from(unwrapped);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    final unwrapped = _unwrap(value);
    if (unwrapped is! List) return <Map<String, dynamic>>[];
    return unwrapped
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool get _isAdmin => _currentUser?.isAdmin ?? false;
}
