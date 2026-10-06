/// Enumerates the host addresses this device holds.
///
/// The web build has no access to the socket layer, so the concrete
/// implementation is chosen at compile time by the conditional export below.
/// Importing this file therefore stays safe on every platform the app ships to.
library;

export 'network_interfaces_io.dart'
    if (dart.library.js_interop) 'network_interfaces_stub.dart'
    if (dart.library.html) 'network_interfaces_stub.dart';