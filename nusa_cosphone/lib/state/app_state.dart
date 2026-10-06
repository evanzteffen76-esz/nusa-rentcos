import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/api_client.dart';
import '../data/cosrent_repository.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);

  final CosrentRepository repository;
  SharedPreferences? _preferences;
  AppUser? currentUser;
  ThemeMode themeMode = ThemeMode.system;

  /// The active UI language. Indonesian is the template locale, so it also
  /// backs every string that has not been translated yet.
  AppLanguage language = AppLanguage.indonesian;

  bool isLoading = true;
  String? errorMessage;

  /// The last connection problem, kept separately from [errorMessage] so the
  /// app can offer the API settings screen instead of a bare error message.
  String? connectionMessage;

  static const _userIdKey = 'session_user_id';
  static const _themeKey = 'cosrent-theme';
  static const _languageKey = 'cosrent-language';

  /// The API host currently in use.
  String get apiBaseUrl => repository.client.baseUrl;

  Future<void> initialize() async {
    await initializeDateFormatting('id_ID');
    _preferences = await SharedPreferences.getInstance();

    final savedTheme = _preferences?.getString(_themeKey);
    themeMode = switch (savedTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    language = AppLanguage.fromCode(
      _preferences?.getString(_languageKey) ??
          initialAppLanguage().code,
    );

    // The old local prototype stored only a user id. Remove it so an old
    // session can never masquerade as an authenticated API session.
    await _preferences?.remove(_userIdKey);
    try {
      currentUser = await repository.restoreSession();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Tidak dapat terhubung. ';
    }
    // Probe once even when there is no stored session: on a handset the
    // API host has to be discovered, and without this the first thing the
    // user sees is a login form that cannot possibly succeed. Setting
    // [connectionMessage] routes them to the connection screen instead.
    if (currentUser == null && errorMessage == null) {
      final reachable = await _probeCurrentHost();
      if (!reachable) {
        connectionMessage =
            'Tidak ada server API yang menjawab di $apiBaseUrl. '
            'Periksa Wi-Fi dan URL API.';
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    errorMessage = null;
    try {
      final user = await repository.authenticate(identifier, password);
      if (user == null) {
        errorMessage = 'Email/username atau password tidak cocok.';
        notifyListeners();
        return false;
      }
      currentUser = user;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = _connectionAware(error);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage =
          'Tidak dapat terhubung ke server. Pastikan Laravel API aktif.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? username,
    String? confirmation,
    String accountType = 'customer',
  }) async {
    errorMessage = null;
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      errorMessage = 'Nama, email, dan password wajib diisi.';
      notifyListeners();
      return false;
    }
    final normalizedUsername = username?.trim() ?? '';
    if (normalizedUsername.isNotEmpty &&
        (normalizedUsername.length < 3 ||
            !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(normalizedUsername))) {
      errorMessage = 'Username minimal 3 karakter dan hanya memakai huruf, angka, titik, _ atau -.';
      notifyListeners();
      return false;
    }
    if (confirmation != null && confirmation != password) {
      errorMessage = 'Konfirmasi password tidak sama.';
      notifyListeners();
      return false;
    }
    if (!email.contains('@')) {
      errorMessage = 'Masukkan email yang valid.';
      notifyListeners();
      return false;
    }
    try {
      final user = await repository.register(
        name: name,
        email: email,
        password: password,
        username: username,
        confirmation: confirmation,
        accountType: accountType,
      );
      currentUser = user;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.isValidation
          ? 'Email sudah digunakan atau data belum valid.'
          : _connectionAware(error);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Pendaftaran gagal. Periksa koneksi ke server.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
    } catch (_) {
      // Local session is always cleared, even if the network is unavailable.
      await repository.client.clearToken();
    }
    currentUser = null;
    errorMessage = null;
    connectionMessage = null;
    notifyListeners();
  }

  /// Save profile edits. On failure [errorMessage] holds the server's reason
  /// so the form can surface it inline.
  Future<bool> updateProfile({
    String? name,
    String? username,
    String? email,
    String? password,
    String? confirmation,
    String? currentPassword,
    BankDetails? bankDetails,
  }) async {
    errorMessage = null;
    final changingPassword = password != null && password.isNotEmpty;

    if (name != null && name.trim().isEmpty) {
      errorMessage = 'Nama tidak boleh kosong.';
      notifyListeners();
      return false;
    }
    if (username != null &&
        username.trim().isNotEmpty &&
        (username.trim().length < 3 ||
            !RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username.trim()))) {
      errorMessage = 'Username minimal 3 karakter dan hanya memakai huruf, angka, titik, _ atau -.';
      notifyListeners();
      return false;
    }
    if (email != null && !email.contains('@')) {
      errorMessage = 'Masukkan email yang valid.';
      notifyListeners();
      return false;
    }
    if (changingPassword) {
      if (password.length < 6) {
        errorMessage = 'Password baru minimal 6 karakter.';
        notifyListeners();
        return false;
      }
      if (confirmation != password) {
        errorMessage = 'Konfirmasi password tidak sama.';
        notifyListeners();
        return false;
      }
      if (currentPassword == null || currentPassword.isEmpty) {
        errorMessage = 'Masukkan password saat ini.';
        notifyListeners();
        return false;
      }
    }
    // The server rejects a partial trio, so catch it before the round trip.
    if (bankDetails != null && !_isBankDetailsComplete(bankDetails)) {
      errorMessage =
          'Isi nama bank, nomor rekening, dan atas nama sekaligus, atau kosongkan semuanya.';
      notifyListeners();
      return false;
    }

    try {
      final user = await repository.updateProfile(
        name: name,
        username: username,
        email: email,
        password: changingPassword ? password : null,
        confirmation: confirmation,
        currentPassword: currentPassword,
        bankDetails: bankDetails,
      );
      currentUser = user;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = _connectionAware(error);
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Gagal menyimpan perubahan. Periksa koneksi.';
      notifyListeners();
      return false;
    }
  }

  /// Delete the signed-in account. The session is dropped either way.
  Future<bool> deleteAccount(String password) async {
    errorMessage = null;
    if (password.isEmpty) {
      errorMessage = 'Masukkan password untuk konfirmasi.';
      notifyListeners();
      return false;
    }
    try {
      await repository.deleteAccount(password);
      currentUser = null;
      errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Gagal menghapus akun. Periksa koneksi.';
      notifyListeners();
      return false;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _preferences?.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Switch the UI language and remember the choice.
  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    await _preferences?.setString(_languageKey, value.code);
    notifyListeners();
  }

  /// Point the app at a specific API host and remember it.
  ///
  /// [value] may be empty to clear the override and fall back to automatic
  /// discovery. Returns `true` when a request to the new host answered, which
  /// is what the settings screen reports back to the user.
  Future<bool> setApiBaseUrl(String? value) async {
    final trimmed = value?.trim() ?? '';
    final preferences = _preferences;

    if (preferences != null) {
      await AppConfig.saveBaseUrl(preferences, trimmed);
    }

    final client = repository.client;
    if (trimmed.isEmpty) {
      // Clear the override and let discovery pick a host again.
      if (preferences != null) await AppConfig.saveBaseUrl(preferences, null);
      final candidates = await AppConfig.apiBaseUrls(
        preferences: preferences,
      );
      client.setBaseUrl(candidates.first, resolve: false);
    } else {
      client.setBaseUrl(trimmed, resolve: false);
    }

    final reachable = await _probeCurrentHost();
    connectionMessage = reachable
        ? null
        : 'Tidak dapat menghubungi $apiBaseUrl. Periksa URL, Wi-Fi, dan '
              'apakah server Laravel sedang berjalan.';
    notifyListeners();
    return reachable;
  }

  /// Re-run endpoint discovery without clearing the session.
  Future<bool> retryConnection() async {
    await repository.client.resolveEndpoint(force: true);
    final reachable = await _probeCurrentHost();
    connectionMessage = reachable
        ? null
        : 'Tidak ada server API yang menjawab. Periksa koneksi dan URL API.';
    errorMessage = connectionMessage;
    notifyListeners();
    return reachable;
  }

  /// Ask the health endpoint whether the active host is serving.
  Future<bool> _probeCurrentHost() async {
    try {
      final response = await repository.client.getJson(
        '/health',
        authenticated: false,
      );
      return response is Map;
    } on ApiException {
      return false;
    } on Object {
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    connectionMessage = null;
    notifyListeners();
  }

  /// Turn a transport failure into an actionable message.
  String _connectionAware(ApiException error) {
    if (!error.isConnectionFailure) return error.message;
    return 'Tidak dapat terhubung ke API ($apiBaseUrl). '
        'Pastikan Laravel aktif dan URL API benar.';
  }

  /// Whether a bank details form holds either all three fields or none.
  static bool _isBankDetailsComplete(BankDetails details) {
    final values = <String>[
      details.bankName.trim(),
      details.accountNumber.trim(),
      details.accountHolder.trim(),
    ];
    final filled = values.where((value) => value.isNotEmpty).length;
    return filled == 0 || filled == values.length;
  }

  static AppState of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan pada widget tree.');
    return scope!.notifier!;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required super.notifier, required super.child, super.key});

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) => true;
}