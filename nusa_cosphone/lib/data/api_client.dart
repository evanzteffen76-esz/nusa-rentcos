import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// A small persistence contract keeps the API client easy to test.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class PreferencesTokenStore implements TokenStore {
  PreferencesTokenStore(this.preferences);

  static const tokenKey = 'cosrent_api_token';
  final SharedPreferences preferences;

  @override
  Future<String?> read() async => preferences.getString(tokenKey);

  @override
  Future<void> write(String token) async {
    await preferences.setString(tokenKey, token);
  }

  @override
  Future<void> clear() async {
    await preferences.remove(tokenKey);
  }
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const tokenKey = 'cosrent_api_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: tokenKey);
}

class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async => token = value;

  @override
  Future<void> clear() async => token = null;
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors = const <String, dynamic>{},
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic> errors;

  bool get isUnauthorized => statusCode == 401;
  bool get isValidation => statusCode == 422;

  /// The server is unreachable or answered with a 5xx.
  ///
  /// Screens use this to offer a retry or the API settings entry point instead
  /// of showing the server's wording, which would say nothing useful.
  bool get isConnectionFailure => statusCode == 0 || statusCode >= 500;

  @override
  String toString() => message;
}

/// A file served by an authenticated download endpoint, such as a transfer
/// receipt or an issue evidence photo.
class ApiFile {
  const ApiFile({required this.bytes, required this.filename, this.mimeType});

  final Uint8List bytes;
  final String filename;
  final String? mimeType;

  /// Whether the payload can be rendered as an image in-app.
  bool get isImage {
    final type = mimeType?.toLowerCase();
    if (type != null && type.isNotEmpty) return type.startsWith('image/');
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    return const <String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'heic',
    }.contains(extension);
  }
}

/// HTTP boundary for the Laravel Sanctum API.
class ApiClient {
  /// Build a client.
  ///
  /// Discovering the base URL has to await the device's network interfaces, so
  /// when no [baseUrl] is given the candidate list is resolved in
  /// [configureCandidates] instead of the constructor. Until that runs,
  /// [baseUrl] holds the Herd site, which resolves through the hosts file on
  /// web, desktop and the iOS simulator. Every request awaits the candidate
  /// list first, so a request is never sent to a host that was only guessed.
  ApiClient({
    String? baseUrl,
    List<String>? fallbackBaseUrls,
    http.Client? httpClient,
    TokenStore? tokenStore,
    bool? autoResolve,
    SharedPreferences? preferences,
  }) : baseUrl = baseUrl != null
           ? AppConfig.normalizeBaseUrl(baseUrl)
           : _herdFallbackUrl,
       _autoResolve = autoResolve ?? baseUrl == null,
       _http = httpClient ?? http.Client() {
    if (baseUrl != null) {
      _candidateBaseUrls = <String>[
        AppConfig.normalizeBaseUrl(baseUrl),
        ...?fallbackBaseUrls?.map(AppConfig.normalizeBaseUrl),
      ];
      baseUrlReady = true;
    } else {
      _candidateBaseUrls = <String>[this.baseUrl];
      _pendingPreferences = preferences ?? _preferences;
      _pendingFallbacks = fallbackBaseUrls;
    }
    _tokenStore =
        tokenStore ??
        (_preferences == null
            ? MemoryTokenStore()
            : PreferencesTokenStore(_preferences!));
  }

  /// The URL used before discovery finishes.
  static String get _herdFallbackUrl =>
      AppConfig.normalizeBaseUrl('https://nusa_rental_cosplay.test');

  String baseUrl;
  final bool _autoResolve;
  final http.Client _http;
  late final TokenStore _tokenStore;
  late final List<String> _candidateBaseUrls;

  SharedPreferences? _pendingPreferences;
  List<String>? _pendingFallbacks;
  Future<void>? _candidateLoad;

  String? _token;
  bool _endpointResolved = false;

  /// Whether [candidateBaseUrls] holds the full discovery result.
  bool baseUrlReady = false;

  bool get autoResolve => _autoResolve;
  bool get endpointResolved => _endpointResolved;

  /// Every host that will be probed, most likely first.
  List<String> get candidateBaseUrls =>
      List<String>.unmodifiable(_candidateBaseUrls);

  /// Resolve the discovery candidates once, caching the resulting future.
  ///
  /// Every request calls this, so concurrent first requests share a single
  /// interface enumeration rather than each starting their own.
  Future<void> configureCandidates() {
    final pending = _pendingPreferences;
    final fallbacks = _pendingFallbacks;
    if (pending == null && fallbacks == null) return Future<void>.value();

    _pendingPreferences = null;
    _pendingFallbacks = null;

    return _candidateLoad ??= _loadCandidates(pending, fallbacks);
  }

  Future<void> _loadCandidates(
    SharedPreferences? preferences,
    List<String>? fallbacks,
  ) async {
    final discovered = await AppConfig.apiBaseUrls(preferences: preferences);
    final candidates = <String>{
      ...discovered,
      ...?fallbacks?.map(AppConfig.normalizeBaseUrl),
    }.toList();

    // Keep the active base URL first when it is already a candidate, so an
    // override chosen in the settings screen survives a rediscovery.
    final ordered = candidates.contains(baseUrl)
        ? <String>[baseUrl, ...candidates.where((url) => url != baseUrl)]
        : candidates;

    _candidateBaseUrls
      ..clear()
      ..addAll(ordered);
    baseUrlReady = true;
  }

  // This is replaced by main() before the first request. It exists only to
  // keep the client constructor safe for simple unit tests.
  static SharedPreferences? _preferences;

  static void configurePreferences(SharedPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> initialize() async {
    await configureCandidates();
    await resolveEndpoint();
    try {
      _token = await _tokenStore.read();
    } catch (_) {
      _token = null;
    }
  }

  /// Selects a reachable local API host for emulator and handset development.
  ///
  /// An explicit API_BASE_URL is never replaced. Without one, every candidate
  /// from [AppConfig] is probed in turn, which covers the Herd domain, the
  /// emulator host aliases and the development machine on the local Wi-Fi.
  Future<void> resolveEndpoint({bool force = false}) async {
    await configureCandidates();
    if (!_autoResolve || (_endpointResolved && !force)) return;

    for (final candidate in _candidateBaseUrls) {
      try {
        final response = await _http
            .get(
              _buildUriForBase(candidate, '/health'),
              headers: const <String, String>{'Accept': 'application/json'},
            )
            .timeout(AppConfig.probeTimeout);
        if (response.statusCode < 500) {
          baseUrl = candidate;
          _endpointResolved = true;
          return;
        }
      } on TimeoutException {
        // Try the next candidate host.
      } on http.ClientException {
        // Try the next candidate host.
      } on Object {
        // A host may be unavailable while the app is starting. On Android a DNS
        // or connect failure surfaces here, so nothing narrower than a blanket
        // catch is worth writing.
      }
    }
  }

  /// Replace the probed endpoint and stop auto-resolution.
  ///
  /// Used by the in-app API settings screen so someone on a physical device can
  /// point the app at their machine without a rebuild.
  void setBaseUrl(String value, {bool resolve = true}) {
    final normalized = AppConfig.normalizeBaseUrl(value);
    baseUrl = normalized;
    _candidateBaseUrls
      ..clear()
      ..add(normalized);
    _endpointResolved = !resolve;
    baseUrlReady = true;
  }

  /// Point an absolute media URL at the host the app is actually using.
  ///
  /// The server builds media URLs from `APP_URL`, which on a development
  /// machine is the Herd domain on port 443. A handset that reached the API
  /// over `http://192.168.1.10:8000` cannot resolve that domain, so every
  /// picture would 404. Rewriting the authority to the active API host keeps
  /// the path intact and makes the gallery load wherever the app is pointed.
  ///
  /// Relative URLs, and URLs already on the right host, are returned as they
  /// are; a URL that cannot be parsed is passed through untouched rather than
  /// discarded.
  String? normalizeMediaUrl(String? url) {
    if (url == null || url.isEmpty) return url;

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return url;
    }

    final active = Uri.tryParse(baseUrl);
    if (active == null || active.host.isEmpty) return url;
    if (parsed.host == active.host && parsed.port == active.port) return url;

    return parsed
        .replace(
          scheme: active.scheme,
          host: active.host,
          port: active.hasPort ? active.port : null,
        )
        .toString();
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> setToken(String token) async {
    _token = token;
    try {
      await _tokenStore.write(token);
    } catch (_) {
      // Keep the in-memory session usable on platforms without a keychain.
    }
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await _tokenStore.clear();
    } catch (_) {
      // The in-memory token is already cleared.
    }
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) {
    return _send(
      () => _http.get(
        _buildUri(path, query),
        headers: _headers(authenticated: authenticated),
      ),
    );
  }

  Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send(
      () => _http.post(
        _buildUri(path),
        headers: _headers(authenticated: authenticated, json: true),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> patchJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send(
      () => _http.patch(
        _buildUri(path),
        headers: _headers(authenticated: authenticated, json: true),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> deleteJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send(
      () => _http.delete(
        _buildUri(path),
        headers: _headers(authenticated: authenticated, json: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  /// POST a multipart body, optionally carrying uploaded files.
  ///
  /// Repeat one upload by giving each [http.MultipartFile] its own field name,
  /// such as `images[0]` and `images[1]`, which PHP folds back into a list.
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const <String, String>{},
    Map<String, http.MultipartFile> files =
        const <String, http.MultipartFile>{},
  }) {
    return _sendMultipart('POST', path, fields: fields, files: files);
  }

  /// PATCH a multipart body, used to update a listing together with its media.
  Future<dynamic> patchMultipart(
    String path, {
    Map<String, String> fields = const <String, String>{},
    Map<String, http.MultipartFile> files =
        const <String, http.MultipartFile>{},
  }) {
    return _sendMultipart('PATCH', path, fields: fields, files: files);
  }

  Future<dynamic> _sendMultipart(
    String method,
    String path, {
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
  }) async {
    await resolveEndpoint();
    try {
      final request = http.MultipartRequest(method, _buildUri(path));
      request.headers.addAll(_headers(authenticated: true));
      request.fields.addAll(fields);
      request.files.addAll(files.values);
      final streamed = await _http
          .send(request)
          .timeout(AppConfig.uploadTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Server terlalu lama merespons. Periksa koneksi Anda.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    }
  }

  /// Download an authenticated file, such as a payment proof or evidence.
  ///
  /// The endpoint is behind Sanctum, so the bytes are fetched here rather than
  /// by [Image.network], which cannot attach the bearer token.
  Future<ApiFile> getFile(String path) async {
    await resolveEndpoint();
    try {
      final response = await _http
          .get(_buildUri(path), headers: _headers(authenticated: true))
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Reuse the JSON error wording so callers see one message format, then
        // fall back if the body held no message at all.
        try {
          _decodeResponse(response);
        } on ApiException {
          rethrow;
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Permintaan gagal (HTTP ${response.statusCode}).',
        );
      }

      return ApiFile(
        bytes: response.bodyBytes,
        filename: _filenameFromResponse(response),
        mimeType: _headerValue(response.headers['content-type']),
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Server terlalu lama merespons. Periksa koneksi Anda.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    }
  }

  void close() => _http.close();

  Uri _buildUri(String path, [Map<String, String>? query]) =>
      _buildUriForBase(baseUrl, path, query);

  Uri _buildUriForBase(
    String apiBaseUrl,
    String path, [
    Map<String, String>? query,
  ]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$apiBaseUrl/$normalizedPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _headers({
    bool authenticated = true,
    bool json = false,
  }) {
    return <String, String>{
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (authenticated && hasToken) 'Authorization': 'Bearer $_token',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    await resolveEndpoint();
    try {
      final response = await request().timeout(AppConfig.requestTimeout);
      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Server terlalu lama merespons. Periksa koneksi Anda.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(statusCode: 0, message: error.message);
    }
  }

  /// Pull the filename out of a `Content-Disposition` header.
  ///
  /// Falls back to a generic name so the caller always has a label.
  String _filenameFromResponse(http.Response response) {
    final disposition = _headerValue(response.headers['content-disposition']);
    if (disposition == null) return 'download';

    final match = RegExp(
      r'''filename\*?=(?:UTF-8'')?"?([^";]+)"?''',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (match == null) return 'download';

    final value = match.group(1);
    if (value == null || value.isEmpty) return 'download';
    return Uri.decodeComponent(value);
  }

  /// Read a header that may arrive as a single value or as a list.
  String? _headerValue(Object? value) {
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value.first.toString();
    return null;
  }

  dynamic _decodeResponse(http.Response response) {
    dynamic payload;
    if (response.body.trim().isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } on FormatException {
        payload = <String, dynamic>{'message': response.body};
      }
    } else {
      payload = <String, dynamic>{};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final errors = map['errors'] is Map
        ? Map<String, dynamic>.from(map['errors'] as Map)
        : <String, dynamic>{};
    final message =
        _errorMessage(map, errors) ??
        'Permintaan gagal (HTTP ${response.statusCode}).';
    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }

  String? _errorMessage(
    Map<String, dynamic> payload,
    Map<String, dynamic> errors,
  ) {
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value != null) return value.toString();
    }
    final direct = payload['message']?.toString().trim();
    if (direct != null &&
        direct.isNotEmpty &&
        !direct.toLowerCase().contains('unauthenticated')) {
      return direct;
    }
    if (responseMessageFallback(payload)) return 'Autentikasi diperlukan.';
    return null;
  }

  bool responseMessageFallback(Map<String, dynamic> payload) {
    return payload.containsKey('message') &&
        payload['message'].toString().toLowerCase().contains('unauthenticated');
  }
}