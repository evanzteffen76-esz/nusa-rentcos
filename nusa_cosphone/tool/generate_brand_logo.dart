// Regenerates the CosplayNusa brand art from the canonical icon set in
// ~/Downloads/brand_icons: a squircle badge in near-black with a white
// tents-and-plus mark inside it.
//
// Run with:
//   flutter test tool/generate_brand_logo.dart
//
// Outputs land in:
//   assets/brand/                                - badge + wordmark lockups
//   android/app/src/main/res/mipmap-*/ic_launcher.png
//   ios/Runner/Assets.xcassets/AppIcon.appiconset/
//   web/favicon.png, web/icons/
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Source geometry
//
// Every coordinate below is measured from the 512px master in brand_icons and
// lives in that file's coordinate space, so the numbers here can be diffed
// against a fresh measurement of the source. `k` maps them onto the size being
// rendered.
// ---------------------------------------------------------------------------

/// The source canvas the measurements were taken on.
const double _canvas = 512.0;

/// The plate is inset inside the source canvas; launcher icons bleed to the
/// edges instead (the OS mask owns the corners there), so both are expressed
/// against the plate rather than the canvas.
const double _plateInset = 39.5;
const double _plateSize = _canvas - 2 * _plateInset;

/// Exponent of the plate's superellipse corners (2 = circle, 4.4 = the
/// continuous "squircle" the source uses).
const double _squircle = 4.4;

/// Near-black plate - the icon shown on light surfaces.
const _plateLight = Color(0xFF0A0A12);

/// Navy plate - the icon shown on dark surfaces.
const _plateDark = Color(0xFF19142D);

/// Tailwind slate-950 - the lockup wordmark ink.
const _slate950 = Color(0xFF020617);

/// Tailwind violet-600 - the "NUSA" half of the wordmark.
const _violet600 = Color(0xFF7C3AED);

/// |v| raised to [p], keeping the sign.
double _powSigned(double v, double p) =>
    v < 0 ? -math.pow(-v, p).toDouble() : math.pow(v, p).toDouble();

/// The badge outline: a superellipse sampled finely enough that the facets are
/// invisible at launcher sizes.
Path _squirclePath(Rect rect, double exponent, {int stepsPerQuadrant = 48}) {
  final rx = rect.width / 2;
  final ry = rect.height / 2;
  final p = 2 / exponent;
  final path = Path();
  for (var q = 0; q < 4; q++) {
    for (var i = 0; i <= stepsPerQuadrant; i++) {
      final t = q * math.pi / 2 + (i / stepsPerQuadrant) * math.pi / 2;
      final x = rect.center.dx + rx * _powSigned(math.cos(t), p);
      final y = rect.center.dy + ry * _powSigned(math.sin(t), p);
      if (q == 0 && i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
  }
  return path..close();
}

/// Draws the tent, its two rules and the plus.
///
/// [origin] is the top-left of the source-space square, [k] its scale.
void _drawMark(Canvas canvas, Offset origin, double k) {
  double X(double x) => origin.dx + x * k;
  double Y(double y) => origin.dy + y * k;

  final white = Paint()..color = Colors.white;

  // Tent: two tapered legs, each a parallelogram. The legs slope half a pixel
  // per pixel; their end cuts run twice as steep, so the top pair crosses into
  // the notch at the peak and the bottom pair closes the feet under the tent.
  // The hollow between the legs needs no hole of its own.
  canvas.drawPath(
    Path()
      ..moveTo(X(244), Y(152)) // peak, outer
      ..lineTo(X(146), Y(347.5)) // foot, outer
      ..lineTo(X(171), Y(360)) // foot cut, buried in the ground bar
      ..lineTo(X(268.8), Y(164.4)) // inner edge back up to the peak cut
      ..close(),
    white,
  );
  canvas.drawPath(
    Path()
      ..moveTo(X(269), Y(152))
      ..lineTo(X(367), Y(347.5))
      ..lineTo(X(342), Y(360))
      ..lineTo(X(244.2), Y(164.4))
      ..close(),
    white,
  );

  // Cross bar: a band spanning the tent, so its ends follow the slanted edges.
  canvas.drawPath(
    Path()
      ..moveTo(X(189.25), Y(261.5))
      ..lineTo(X(323.75), Y(261.5))
      ..lineTo(X(337.75), Y(289.5))
      ..lineTo(X(175.25), Y(289.5))
      ..close(),
    white,
  );

  // Ground bar.
  canvas.drawRect(
    Rect.fromLTRB(X(157.5), Y(339.5), X(353.5), Y(367.5)),
    white,
  );

  // Plus.
  canvas.drawRect(
    Rect.fromLTRB(X(321.5), Y(151.5), X(337.5), Y(212.5)),
    white,
  );
  canvas.drawRect(
    Rect.fromLTRB(X(299), Y(174.5), X(360), Y(190.5)),
    white,
  );
}

/// Square app icon: plate with the mark centred inside it.
///
/// [bleed] scales the plate up to fill [s] edge to edge instead of keeping the
/// source's inset margin. [rounded] rounds the plate into the source's
/// squircle; launcher icons pass false, because the OS mask (iOS squircle,
/// Android circle/squircle, PWA maskable) owns the corners and a pre-rounded
/// plate would read as a double-rounded edge.
void _drawIcon(
  Canvas canvas,
  double s, {
  bool bleed = false,
  bool rounded = true,
  Color plate = _plateLight,
}) {
  final k = s / (bleed ? _plateSize : _canvas);
  final origin = bleed
      ? Offset(-_plateInset * k, -_plateInset * k)
      : Offset.zero;
  final inset = _plateInset * k;
  final plateRect = Rect.fromLTWH(
    origin.dx + inset,
    origin.dy + inset,
    _plateSize * k,
    _plateSize * k,
  );
  canvas.drawPath(
    rounded
        ? _squirclePath(plateRect, _squircle)
        : (Path()..addRect(plateRect)),
    Paint()..color = plate,
  );
  _drawMark(canvas, origin, k);
}

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final data = ByteData.view(bytes.buffer);
  (FontLoader(family)..addFont(Future<ByteData>.value(data))).load();
}

TextPainter _text(
  String value, {
  required String family,
  required double size,
  required double tracking,
  required Color color,
}) {
  // tracking is expressed in em (Tailwind letter-spacing) and converted to
  // logical pixels here.
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        letterSpacing: tracking * size,
        color: color,
        height: 1.0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter;
}

/// Horizontal lockup: badge, then the COSPLAY / NUSA wordmark.
Future<Size> _lockupSize(double scale, {Color ink = _slate950}) async {
  final icon = 44.0 * scale;
  final gap = 12.0 * scale;
  final cosplay = _text(
    'COSPLAY',
    family: 'RobotoBlack',
    size: 14.0 * scale,
    tracking: 0.22,
    color: ink,
  );
  final nusa = _text(
    'NUSA',
    family: 'RobotoBold',
    size: 9.92 * scale,
    tracking: 0.34,
    color: _violet600,
  );
  final blockWidth = cosplay.width > nusa.width ? cosplay.width : nusa.width;
  return Size(icon + gap + blockWidth, icon);
}

void _drawLockup(
  Canvas canvas,
  double scale, {
  Color ink = _slate950,
  Color plate = _plateLight,
}) {
  final icon = 44.0 * scale;
  _drawIcon(canvas, icon, bleed: true, plate: plate);

  final cosplay = _text(
    'COSPLAY',
    family: 'RobotoBlack',
    size: 14.0 * scale,
    tracking: 0.22,
    color: ink,
  );
  final nusa = _text(
    'NUSA',
    family: 'RobotoBold',
    size: 9.92 * scale,
    tracking: 0.34,
    color: _violet600,
  );

  // Flutter adds letterSpacing after the final glyph too; discount it so the
  // block stays optically centred against the badge.
  final cosplayWidth = cosplay.width - 0.22 * 14.0 * scale;
  final nusaWidth = nusa.width - 0.34 * 9.92 * scale;
  final blockWidth = cosplayWidth > nusaWidth ? cosplayWidth : nusaWidth;

  final blockHeight = cosplay.height + 4.0 * scale + nusa.height;
  final left = icon + 12.0 * scale;
  final top = (icon - blockHeight) / 2;

  cosplay.paint(canvas, Offset(left, top));
  nusa.paint(canvas, Offset(left, top + cosplay.height + 4.0 * scale));

  // Keep the measured width honest for callers that size the canvas.
  assert(blockWidth > 0);
}

/// Encodes [image] as a truecolor (no alpha channel) PNG.
///
/// Launcher icons are full-bleed, so alpha carries no information - and the
/// App Store rejects marketing icons that still declare an alpha channel.
Future<Uint8List> _encodeOpaquePng(ui.Image image) async {
  final raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
      .buffer
      .asUint8List();
  final stride = image.width * 4;

  // One filter byte (0 = None) per scanline, then RGB triplets.
  final scanlines = Uint8List(image.height * (image.width * 3 + 1));
  var out = 0;
  for (var y = 0; y < image.height; y++) {
    scanlines[out++] = 0;
    var i = y * stride;
    for (var x = 0; x < image.width; x++) {
      scanlines[out++] = raw[i];
      scanlines[out++] = raw[i + 1];
      scanlines[out++] = raw[i + 2];
      i += 4;
    }
  }

  final ihdr = BytesBuilder()
    ..add(_be32(image.width))
    ..add(_be32(image.height))
    ..add(const [8, 2, 0, 0, 0]); // depth 8, truecolor, deflate, no interlace

  final png = BytesBuilder()..add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  _chunk(png, 'IHDR', ihdr.toBytes());
  _chunk(png, 'IDAT', ZLibCodec(level: 9).encode(scanlines));
  _chunk(png, 'IEND', const []);
  return png.toBytes();
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

void _chunk(BytesBuilder png, String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  png
    ..add(_be32(data.length))
    ..add(typeBytes)
    ..add(data)
    ..add(_be32(_crc32([...typeBytes, ...data])));
}

Uint8List _be32(int value) => Uint8List(4)
  ..[0] = (value >> 24) & 0xFF
  ..[1] = (value >> 16) & 0xFF
  ..[2] = (value >> 8) & 0xFF
  ..[3] = value & 0xFF;

Future<void> _write(
  String path,
  double width,
  double height,
  void Function(Canvas) paint, {
  bool opaque = false,
}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final bytes = opaque
      ? await _encodeOpaquePng(image)
      : (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List();
  image.dispose();

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  // ignore: avoid_print
  print(
    '  ${path.padRight(56)} ${width.toInt()}x${height.toInt()}'
    '${opaque ? '  rgb' : ''}',
  );
}

/// Android density buckets for the legacy `ic_launcher.png` mipmaps.
const _androidDensities = <String, double>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

Future<void> _writeAndroidIcons() async {
  for (final entry in _androidDensities.entries) {
    final size = entry.value;
    await _write(
      'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      size,
      size,
      (c) => _drawIcon(c, size, bleed: true, rounded: false),
      opaque: true,
    );
  }
}

/// Sizes every icon listed in the appiconset's `Contents.json`, so the set can
/// never drift out of sync with the asset catalog.
Future<void> _writeIosIcons() async {
  const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final catalog = jsonDecode(await File('$dir/Contents.json').readAsString())
      as Map<String, dynamic>;
  for (final entry
      in (catalog['images'] as List).cast<Map<String, dynamic>>()) {
    final filename = entry['filename'] as String?;
    if (filename == null) continue;
    // `size` reads "20x20" (points); only the leading edge is needed.
    final points = double.parse((entry['size'] as String).split('x').first);
    final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
    final size = (points * scale).roundToDouble();
    await _write(
      '$dir/$filename',
      size,
      size,
      (c) => _drawIcon(c, size, bleed: true, rounded: false),
      opaque: true,
    );
  }
}

Future<void> _writeWebIcons() async {
  // Browser chrome and the home-screen shortcut: full-bleed, no transparency.
  for (final size in [32.0, 192.0, 512.0]) {
    final name = size == 32 ? 'favicon.png' : 'icons/Icon-${size.toInt()}.png';
    await _write(
      'web/$name',
      size,
      size,
      (c) => _drawIcon(c, size, bleed: true, rounded: false),
      opaque: true,
    );
  }

  // Maskable icons get cropped to a circle/squircle, but the mark's furthest
  // point sits 29% out from the centre - well inside the 40% safe circle - so
  // the artwork can bleed exactly like the plain icons.
  for (final size in [192.0, 512.0]) {
    await _write(
      'web/icons/Icon-maskable-${size.toInt()}.png',
      size,
      size,
      (c) => _drawIcon(c, size, bleed: true, rounded: false),
      opaque: true,
    );
  }
}

void main() {
  test('generate CosplayNusa brand and launcher icons', () async {
    final fonts = Platform.environment['FLUTTER_ROOT'] ?? r'C:\Android\flutter';
    final dir = Directory(fonts);
    final fontDir = dir.existsSync()
        ? '${dir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}'
              'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}material_fonts'
        : '';
    await _loadFont(
      'RobotoBlack',
      '$fontDir${Platform.pathSeparator}roboto-black.ttf',
    );
    await _loadFont(
      'RobotoBold',
      '$fontDir${Platform.pathSeparator}roboto-bold.ttf',
    );

    // ignore: avoid_print
    print('writing assets/brand/');
    // App icons - one device pixel per output pixel, so no resampling blur.
    for (final size in [1024, 512, 256, 192, 48]) {
      await _write(
        'assets/brand/cosplaynusa-icon-$size.png',
        size.toDouble(),
        size.toDouble(),
        (c) => _drawIcon(c, size.toDouble()),
      );
    }
    await _write(
      'assets/brand/cosplaynusa-favicon-32.png',
      32,
      32,
      (c) => _drawIcon(c, 32),
    );

    // Dark-surface badge, for in-app use on dark themes.
    for (final size in [1024.0, 512.0, 192.0]) {
      await _write(
        'assets/brand/cosplaynusa-icon-dark-${size.toInt()}.png',
        size,
        size,
        (c) => _drawIcon(c, size, plate: _plateDark),
      );
    }

    // Light-background lockups.
    for (final scale in [8.0, 4.0, 2.0]) {
      final size = await _lockupSize(scale);
      final name = 'assets/brand/cosplaynusa-logo-${(size.width).toInt()}.png';
      await _write(name, size.width, size.height, (c) => _drawLockup(c, scale));
    }

    // Dark-background variant: white wordmark on the navy plate.
    for (final scale in [8.0, 4.0]) {
      final size = await _lockupSize(scale, ink: Colors.white);
      await _write(
        'assets/brand/cosplaynusa-logo-light-${size.width.toInt()}.png',
        size.width,
        size.height,
        (c) => _drawLockup(c, scale, ink: Colors.white, plate: _plateDark),
      );
    }

    // ignore: avoid_print
    print('writing android/ launcher icons');
    await _writeAndroidIcons();

    // ignore: avoid_print
    print('writing ios/ AppIcon set');
    await _writeIosIcons();

    // ignore: avoid_print
    print('writing web/ favicon and manifest icons');
    await _writeWebIcons();
  });
}