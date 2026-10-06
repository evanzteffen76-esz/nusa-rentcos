/// No socket layer on the web, so there is nothing to discover.
///
/// The browser reaches the API through the Herd domain, which resolves through
/// the host's own hosts file, so the static candidates are already correct.
Future<List<String>> hostCandidates(int port) async => const <String>[];