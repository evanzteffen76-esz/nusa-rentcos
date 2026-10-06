import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Lets someone point the app at an API host from inside the app.
///
/// A physical handset cannot resolve the developer's `.test` domain, and the
/// machine's address on the shared network changes with the DHCP lease. This
/// screen is the escape hatch: type the host, check it answers, and the value
/// is remembered for the next launch.
class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  late final TextEditingController _controller;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: AppConfig.savedBaseUrl(null) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan API')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageIntro(
              eyebrow: 'Koneksi',
              title: 'Alamat server',
              subtitle:
                  'Isi alamat komputer yang menjalankan Laravel. Untuk emulator '
                  'Android, gunakan 10.0.2.2. Untuk device fisik, gunakan IP '
                  'Wi-Fi komputer, misalnya 192.168.1.10, atau 127.0.0.1 bila '
                  'Anda sudah menjalankan adb reverse tcp:8000 tcp:8000.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'URL API',
                hintText: 'http://192.168.1.10:8000 atau http://127.0.0.1:8000',
                helperText:
                    'Boleh ditulis tanpa /api/v1, bagian '
                    'tersebut dilengkapi otomatis.',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            if (AppConfig.hasConfiguredBaseUrl)
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'URL dikunci oleh --dart-define=API_BASE_URL saat '
                          'build, jadi nilai di sini tidak dipakai.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              Card(
                color: _messageIsError
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _messageIsError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_message!)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Simpan & uji koneksi'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _retryDiscovery,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Cari server otomatis'),
            ),
            const SizedBox(height: 26),
            const _CandidateList(),
            const SizedBox(height: 26),
            const _LanguagePicker(),
            const SizedBox(height: 20),
            Text(
              'Host aktif: ${state.apiBaseUrl}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final state = AppState.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });

    final reachable = await state.setApiBaseUrl(_controller.text);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _messageIsError = !reachable;
      _message = reachable
          ? 'Berhasil terhubung ke ${state.apiBaseUrl}.'
          : 'Gagal menghubungi ${state.apiBaseUrl}. '
                'Pastikan alamat benar, perangkat di Wi-Fi yang sama, dan '
                'server Laravel aktif dengan port yang benar.';
    });
  }

  Future<void> _retryDiscovery() async {
    final state = AppState.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });

    _controller.clear();
    final reachable = await state.setApiBaseUrl(null);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _messageIsError = !reachable;
      _message = reachable
          ? 'Server ditemukan di ${state.apiBaseUrl}.'
          : 'Tidak ada server yang menjawab. Periksa Wi-Fi dan pastikan '
                'Laravel berjalan.';
    });
  }
}

/// The hosts the app probed, so a failure is diagnosable on the device.
class _CandidateList extends StatelessWidget {
  const _CandidateList();

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final client = state.repository.client;
    final candidates = client.candidateBaseUrls;

    if (candidates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Kandidat yang dicoba'),
        const SizedBox(height: 8),
        for (final candidate in candidates.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  candidate == state.apiBaseUrl
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    candidate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The language switcher, kept beside the connection settings because both
/// are app-level preferences rather than part of any one screen.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Bahasa'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final language in AppLanguage.values)
              ChoiceChip(
                label: Text(language.nativeName),
                selected: state.language == language,
                onSelected: (_) => state.setLanguage(language),
              ),
          ],
        ),
      ],
    );
  }
}

/// A compact theme control reused by the profile screen.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Terang'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Gelap'),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text('Sistem'),
        ),
      ],
      selected: <ThemeMode>{state.themeMode},
      onSelectionChanged: (selection) =>
          state.setThemeMode(selection.first),
    );
  }
}

/// A labelled block used by the profile screen sections.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

/// Marks the informational accent colour for a section icon.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      SoftIcon(icon: icon, color: AppColors.info, size: 38);
}