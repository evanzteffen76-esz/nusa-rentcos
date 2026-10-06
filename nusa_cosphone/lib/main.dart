import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/api_client.dart';
import 'data/cosrent_repository.dart';
import 'features/auth/login_page.dart';
import 'features/settings/api_settings_page.dart';
import 'features/shell/main_shell.dart';
import 'l10n/l10n.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/common_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // Bound the decoded-image cache. The default budget is generous enough that
  // a long browsing session on a cheap device can push the process into the
  // low-memory kill range.
  PaintingBinding.instance.imageCache
    ..maximumSize = 160
    ..maximumSizeBytes = 64 << 20;

  // Never let an unexpected error take the whole app down: log it and keep
  // running so a transient failure in one screen does not close the app.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('CosplayNusa framework error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('CosplayNusa uncaught error: $error');
    return true;
  };

  // Release decoded images when the app leaves the foreground. Holding them
  // while backgrounded is one of the most common reasons Android kills the
  // process, so the user reopens the app to a cold start.
  AppLifecycleListener(
    onPause: () {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    },
    onDetach: PaintingBinding.instance.imageCache.clear,
  );

  // A missing or corrupt preferences file must not stop the app from starting.
  // Only the token and the URL override depend on it, so when it is
  // unavailable the client falls back to an in-memory token store and
  // automatic host discovery.
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } on Object catch (error) {
    debugPrint('SharedPreferences unavailable, continuing in memory: $error');
  }

  if (preferences != null) {
    ApiClient.configurePreferences(preferences);
  }

  // The keychain needs a platform channel, which the web build does not have,
  // and both stores need somewhere to persist: shared preferences on the web,
  // the secure enclave elsewhere.
  final tokenStore = preferences == null
      ? MemoryTokenStore()
      : (kIsWeb
            ? PreferencesTokenStore(preferences)
            : SecureTokenStore());

  final client = ApiClient(tokenStore: tokenStore, preferences: preferences);
  final repository = CosrentRepository(client);
  await repository.initialize();
  final state = AppState(repository);
  await state.initialize();
  runApp(CosplayNusaApp(state: state));
}

class CosplayNusaApp extends StatelessWidget {
  const CosplayNusaApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          title: 'CosplayNusa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          locale: state.language.locale,
          home: const _AppGate(),
        ),
      ),
    );
  }
}

/// Decides between the splash, login and role shells.
///
/// This deliberately subscribes to [AppState] itself. `MaterialApp` captures
/// its `home` when the first route is built, so a plain `const` widget there
/// would keep rendering the login screen forever once a login succeeds.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  AppState? _state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppState.of(context);
    if (identical(state, _state)) return;
    _state?.removeListener(_handleChange);
    _state = state..addListener(_handleChange);
  }

  @override
  void dispose() {
    _state?.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _state ?? AppState.of(context);
    if (state.isLoading) return const _SplashPage();

    // A failure to reach the API is shown before the login screen so the user
    // can point the app at a reachable host instead of guessing at a password
    // that was never checked.
    if (state.connectionMessage != null && state.currentUser == null) {
      return _ConnectionGate(message: state.connectionMessage!);
    }

    final user = state.currentUser;
    if (user == null) return const LoginPage();
    return MainShell(
      key: ValueKey('${user.role}-${user.id}'),
      user: user,
    );
  }
}

/// Shown when no API host answered, with a way to fix the URL in place.
class _ConnectionGate extends StatelessWidget {
  const _ConnectionGate({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CosrentLogo(),
                const SizedBox(height: 28),
                Icon(
                  Icons.wifi_off_rounded,
                  size: 44,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Server tidak terjangkau',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.apiBaseUrl,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: () => state.retryConnection(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba lagi'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.settings_ethernet_rounded),
                  label: const Text('Atur URL API'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ApiSettingsPage(),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CosrentLogo(),
            const SizedBox(height: 28),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Menyiapkan petualanganmu...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}