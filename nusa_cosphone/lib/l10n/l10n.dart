import 'package:flutter/material.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// A language the mobile client can be switched to.
///
/// This mirrors `config/locales.php` on the Laravel side: the same five
/// languages, with the native name used for the picker label so a speaker can
/// always find their own language.
enum AppLanguage {
  indonesian(code: 'id', nativeName: 'Bahasa Indonesia'),
  english(code: 'en', nativeName: 'English'),
  mandarin(code: 'zh', nativeName: '中文'),
  japanese(code: 'ja', nativeName: '日本語'),
  korean(code: 'ko', nativeName: '한국어');

  const AppLanguage({required this.code, required this.nativeName});

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.indonesian;
    final normalized = code.trim().toLowerCase();
    return AppLanguage.values.firstWhere(
      (language) => language.code == normalized,
      orElse: () => AppLanguage.indonesian,
    );
  }
}

/// Short access to the active translations.
///
/// `context.l10n.customerDashboardTitle` instead of the two-line
/// `AppLocalizations.of(context)!`, which also removes the null assertion that
/// would otherwise crash a screen built outside a `MaterialApp` localizations
/// scope.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The [AppLocalizations] currently in scope.
///
/// Reading this outside a localized widget tree is a programming error, so the
/// missing case fails loudly in debug and returns the template locale in
/// release rather than throwing inside a `build` method.
AppLocalizations? maybeLocalizationsOf(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations);

/// Build the [AppLocalizations] for a locale without a widget tree.
///
/// The language switcher previews nothing, but the theme and the date
/// formatting in a few widgets need a locale before the first frame.
AppLocalizations localizationsForLocale(Locale locale) =>
    lookupAppLocalizations(locale);

/// The locale list handed to `MaterialApp`, in picker order.
List<Locale> get supportedAppLocales =>
    AppLanguage.values.map((language) => language.locale).toList();

/// Pick the [AppLanguage] that best matches the device language.
///
/// Falls back to Indonesian, which is the template locale and therefore the
/// one every untranslated string resolves in.
AppLanguage resolveDeviceLanguage(Locale? deviceLocale) {
  final code = deviceLocale?.languageCode.toLowerCase();
  if (code == null) return AppLanguage.indonesian;
  return AppLanguage.fromCode(code);
}

/// The locale to start the app in, before a stored preference is read.
///
/// Falls back to Indonesian, which is the template locale and therefore the one
/// every untranslated string resolves in.
AppLanguage initialAppLanguage() => resolveDeviceLanguage(
  WidgetsBinding.instance.platformDispatcher.locale,
);