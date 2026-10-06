import 'dart:io';

/// Build candidate hosts from the device's own IPv4 interfaces.
///
/// For every non-loopback address the device holds, the address itself and its
/// neighbours across a small range are offered. That covers the common case
/// where the handset is on `192.168.1.x` and the development machine sits on
/// the same subnet, without needing to know the address in advance.
Future<List<String>> hostCandidates(int port) async {
  final List<NetworkInterface> interfaces;
  try {
    interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
  } on Object {
    // The platform can refuse to enumerate interfaces (a restricted profile, a
    // sandboxed host). Discovery is best effort: the caller falls back to the
    // static candidates and the in-app settings screen.
    return const <String>[];
  }

  final hosts = <String>{};

  for (final NetworkInterface interface in interfaces) {
    for (final InternetAddress address in interface.addresses) {
      final parts = address.address.split('.');
      if (parts.length != 4) continue;

      final prefix = parts.take(3).join('.');
      final last = int.tryParse(parts.last);
      if (last == null) continue;

      // The host itself, then its immediate neighbours. `.1` is usually the
      // router and the tail of a /24 is usually empty, so weight the guesses
      // towards the low, commonly assigned host numbers.
      hosts.add('$prefix.$last');
      for (var offset = 1; offset <= 4; offset++) {
        if (last - offset >= 1) hosts.add('$prefix.${last - offset}');
      }
      for (final candidate in const <int>[1, 2, 100, 101, 102]) {
        if (candidate != last) hosts.add('$prefix.$candidate');
      }
    }
  }

  return hosts
      .map((host) => 'http://$host:$port')
      .toList(growable: false);
}