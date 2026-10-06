/// Renders a picture from a local file path.
///
/// The thumbnail of a staged upload only exists on disk, which the web build
/// has no access to, so the concrete widget is chosen at compile time. On the
/// web it degrades to a labelled placeholder instead of failing to compile.
library;

export 'local_image_io.dart'
    if (dart.library.js_interop) 'local_image_stub.dart'
    if (dart.library.html) 'local_image_stub.dart';