import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network_interfaces.dart';

/// Runtime configuration for the Laravel API.
///
/// The backend is served by Herd on the local HTTPS domain
/// `nusa_rental_cosplay.test`, which resolves to 127.0.0.1 through the hosts
/// file, so web, desktop and the iOS simulator all use the same URL.
///
/// A physical Android device cannot use that: it has no hosts entry for the
/// domain, and `10.0.2.2` / `10.0.3.2` are emulator-only aliases for the
/// developer machine. Its way in is either the developer machine's address on
/// the shared Wi-Fi network, or `adb reverse tcp:8000 tcp:8000`, which maps the
/// device's own loopback onto that machine. Because the Wi-Fi address changes
/// with the DHCP lease, [AppConfig] resolves it in three steps:
///
/// 1. a URL saved from the in-app API settings screen,
/// 2. an explicit `--dart-define=API_BASE_URL=...`,
/// 3. a probe of every known local candidate, including the gateway addresses
///    discovered from the device's own network interfaces.
///
/// Override the URL explicitly with
/// `--dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1`.
class AppConfig {
  const AppConfig._();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Preference key holding the URL chosen in the in-app settings screen.
  static const String baseUrlPreferenceKey = 'cosrent_api_base_url';

  /// Herd site that hosts the Laravel API over HTTPS.
  static const _herdBaseUrl = 'https://nusa_rental_cosplay.test';

  /// The port the API is served on when Herd is bypassed.
  static const int _fallbackPort = 8000;

  /// How long a single health probe may take.
  ///
  /// The original value was 1.2s, which is fine for loopback but routinely
  /// expires against a phone on Wi-Fi, making a reachable backend look dead.
  static const Duration probeTimeout = Duration(seconds: 4);

  /// How long a regular API call may take.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// How long an upload may take. Videos are large, so this is generous.
  static const Duration uploadTimeout = Duration(minutes: 3);

  static bool get hasConfiguredBaseUrl => _configuredBaseUrl.trim().isNotEmpty;

  /// The saved override, if the user set one in the API settings screen.
  static String? savedBaseUrl(SharedPreferences? preferences) {
    if (hasConfiguredBaseUrl) return _configuredBaseUrl.trim();
    final saved = preferences?.getString(baseUrlPreferenceKey)?.trim();
    if (saved == null || saved.isEmpty) return null;
    return saved;
  }

  /// Persist an override chosen in the in-app settings screen.
  ///
  /// A value coming from `--dart-define` wins over anything stored here, so a
  /// build-time configuration cannot be silently overridden on the device.
  static Future<void> saveBaseUrl(
    SharedPreferences preferences,
    String? value,
  ) async {
    if (hasConfiguredBaseUrl) return;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await preferences.remove(baseUrlPreferenceKey);
      return;
    }
    await preferences.setString(baseUrlPreferenceKey, trimmed);
  }

  /// The URLs to probe when nothing else pinned the endpoint.
  ///
  /// The Herd domain and the emulator host aliases are always tried. On a real
  /// handset the local subnet addresses from [networkCandidates] are added, so
  /// the app finds the developer machine without any configuration.
  static Future<List<String>> apiBaseUrls({
    SharedPreferences? preferences,
    bool includeNetworkCandidates = true,
  }) async {
    final configured = _configuredBaseUrl.trim();
    if (configured.isNotEmpty) {
      return <String>[normalizeBaseUrl(configured)];
    }

    final saved = preferences?.getString(baseUrlPreferenceKey)?.trim();
    if (saved != null && saved.isNotEmpty) {
      return <String>[normalizeBaseUrl(saved)];
    }

    final candidates = <String>{..._platformDefaults, _herdBaseUrl};

    if (includeNetworkCandidates && !kIsWeb) {
      candidates.addAll(await _networkCandidates());
    }

    return candidates.map(normalizeBaseUrl).toList();
  }

  static List<String> get _platformDefaults {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const <String>[
        // Android Studio emulator: the host loopback.
        'http://10.0.2.2:$_fallbackPort',
        // Genymotion emulator.
        'http://10.0.3.2:$_fallbackPort',
        // A USB-connected handset, once `adb reverse tcp:8000 tcp:8000` has been
        // run. `adb reverse` maps the device's own loopback onto the developer
        // machine, so this address works without knowing the machine's Wi-Fi
        // address and without putting both devices on the same network.
        'http://127.0.0.1:$_fallbackPort',
      ];
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // The iOS simulator shares the host network stack, so the Herd domain
      // resolves; localhost is the fallback when it does not.
      return const <String>['http://127.0.0.1:$_fallbackPort'];
    }
    // Web and desktop resolve the Herd domain through the hosts file.
    return const <String>[];
  }

  /// Candidate hosts derived from this device's own network interfaces.
  ///
  /// Delegates to the platform implementation, which is a no-op on the web.
  /// See [hostCandidates] for how the guesses are built.
  static Future<List<String>> _networkCandidates() =>
      hostCandidates(_fallbackPort);

  /// The first candidate, used as the starting point before probing.
  ///
  /// Falls back to the Herd domain when discovery is unavailable, which is the
  /// only option on the web anyway.
  static Future<String> apiBaseUrl({SharedPreferences? preferences}) async =>
      (await apiBaseUrls(preferences: preferences)).first;

  /// Normalize a user- or build-supplied URL into an API root.
  ///
  /// Accepts a bare host, a host with `/api`, or a full `/api/v1` root, so a
  /// value pasted from a browser address bar still works.
  static String normalizeBaseUrl(String value) {
    var base = value.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('/api/v1')) return base;
    if (base.endsWith('/api')) return '$base/v1';
    return '$base/api/v1';
  }
}