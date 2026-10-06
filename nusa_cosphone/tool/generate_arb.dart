// Converts the Laravel `lang/*.json` catalogs into Flutter ARB files.
//
// The web project is the single source of truth for every translated string,
// so the mobile catalog is derived from it instead of being re-typed. Keys are
// flattened (`customer.payment.bank_name` -> `customerPaymentBankName`) because
// ARB keys may not contain dots.
//
// Usage: dart run tool/generate_arb.dart
import 'dart:convert';
import 'dart:io';

/// Where the Laravel catalogs live, relative to this tool.
const String laravelLangDir = r'C:\Users\DELL\Herd\nusa_rental_cosplay\lang';

/// Where the ARB files are written, relative to the Flutter project root.
const String arbDir = 'lib/l10n';

/// The locale of each Laravel catalog, mapped to its ARB file name.
const Map<String, String> locales = <String, String>{
  'id': 'app_id',
  'en': 'app_en',
  'zh': 'app_zh',
  'ja': 'app_ja',
  'ko': 'app_ko',
};

/// Strings that must never become an ARB entry.
///
/// Flutter reserves these for its own metadata, and a message using one of
/// them would produce a file gen_l10n refuses to load.
const Set<String> reservedKeys = <String>{
  '@@locale',
  'locale',
};

/// Convert a dotted Laravel translation key into a camelCase ARB key.
///
/// `customer.payment.bank_name` -> `customerPaymentBankName`
///
/// ARB keys become Dart identifiers, so they may only contain letters and
/// digits and may not start with a digit. Dots separate words, and any other
/// separator inside a segment becomes a word boundary too, which keeps the
/// generated keys readable (`admin.stats_admin access` ->
/// `adminStatsAdminAccess`).
String toArbKey(String dotted) {
  final words = dotted
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) return '';

  final buffer = StringBuffer(_lowerFirst(words.first));
  for (final word in words.skip(1)) {
    buffer.write(_upperFirst(word));
  }

  final key = buffer.toString();
  return RegExp(r'^[0-9]').hasMatch(key) ? 'k$key' : key;
}

/// Uppercase the first character.
String _upperFirst(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// Lowercase the first character.
String _lowerFirst(String value) =>
    value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);

/// Escape a value for embedding in a JSON string literal.
///
/// [jsonEncode] already handles this; the helper exists so the intent is clear
/// at the call site.
String _encode(Object? value) => jsonEncode(value);

Future<void> main(List<String> args) async {
  final root = Directory.current;
  final outputDirectory = Directory('${root.path}\\$arbDir');
  if (!outputDirectory.existsSync()) {
    outputDirectory.createSync(recursive: true);
  }

  // The template locale defines the key set every other locale is checked
  // against, so read it first.
  final templatePath = '$laravelLangDir\\id.json';
  final template = _readCatalog(templatePath);
  final templateKeys = template.keys.map(toArbKey).toSet();

  var generated = 0;

  for (final entry in locales.entries) {
    final locale = entry.key;
    final fileName = entry.value;
    final path = '$laravelLangDir\\$locale.json';

    final File source = File(path);
    if (!source.existsSync()) {
      stderr.writeln('Skipping $locale: $path not found.');
      continue;
    }

    final catalog = _readCatalog(path);
    final buffer = StringBuffer();
    buffer.writeln('{');
    buffer.writeln('  "@@locale": ${_encode(locale)},');

    final arbKeys = <String, String>{};

    for (final raw in catalog.keys) {
      final key = toArbKey(raw);
      if (key.isEmpty || reservedKeys.contains(key)) continue;
      if (arbKeys.containsKey(key)) continue;
      final value = catalog[raw];
      if (value is! String) continue;
      arbKeys[key] = value;
    }

    // Indonesian is the template: every key it defines must be present.
    if (locale == 'id') {
      for (final key in templateKeys) {
        arbKeys.putIfAbsent(key, () => key);
      }
    }

    final sortedKeys = arbKeys.keys.toList()..sort();
    for (var i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final comma = i == sortedKeys.length - 1 ? '' : ',';
      buffer.writeln('  ${_encode(key)}: ${_encode(arbKeys[key])}$comma');
    }

    buffer.writeln('}');

    final target = File('${outputDirectory.path}\\$fileName.arb');
    target.writeAsStringSync(buffer.toString());
    stdout.writeln('${target.path}: ${sortedKeys.length} keys');
    generated++;
  }

  stdout.writeln('Generated $generated ARB file(s).');
}

/// Read a Laravel JSON catalog into a flat string map.
Map<String, Object?> _readCatalog(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw FormatException('$path does not contain a JSON object.');
  }
  return decoded;
}