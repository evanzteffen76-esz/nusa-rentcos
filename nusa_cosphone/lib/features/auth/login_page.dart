import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final state = AppState.of(context);
    final success = await state.login(
      _identifierController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!success) {
      showAppSnack(
        context,
        state.errorMessage ?? 'Login gagal.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primary.withValues(alpha: 0.08),
              scheme.surface,
              scheme.secondary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Cap the OS text-size setting: at very large scales the long
        // Indonesian labels and the "Daftar sekarang" button no longer fit
        // their rows on narrow devices.
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 1,
          maxScaleFactor: 1.3,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                // Two columns need genuine room in *both* axes. A landscape
                // phone is wide but short, and a split layout would squeeze
                // the brand panel into an unusable column.
                final twoColumn = size.width >= 900 && size.height >= 560;
                final shortScreen = size.height < 620;
                final gutter = size.width < 380 ? 16.0 : 22.0;
                final verticalPad = shortScreen ? 16.0 : 28.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: gutter,
                    vertical: verticalPad,
                  ),
                  child: ConstrainedBox(
                    // Derive the minimum from the real viewport so short
                    // devices are not forced into a pointless scroll.
                    constraints: BoxConstraints(
                      maxWidth: 1120,
                      minHeight: math.max(0, size.height - verticalPad * 2),
                    ),
                    child: Center(
                      child: twoColumn
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(child: _BrandPanel()),
                                SizedBox(width: shortScreen ? 40 : 64),
                                SizedBox(
                                  width: (size.width * 0.40).clamp(
                                    300.0,
                                    420.0,
                                  ),
                                  child: _buildForm(context),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BrandPanel(compact: true, short: shortScreen),
                                SizedBox(height: shortScreen ? 22 : 32),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  child: _buildForm(context),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final state = AppState.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat datang kembali',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Masuk untuk melanjutkan petualangan cosplay-mu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: 'Email atau username',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              final identifier = value?.trim() ?? '';
              if (identifier.isEmpty) {
                return 'Masukkan email atau username';
              }
              if (identifier.length > 255) {
                return 'Email atau username terlalu panjang';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Password wajib diisi' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  showAppSnack(context, 'Hubungi admin untuk reset password.'),
              child: const Text('Lupa password?'),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _isSubmitting ? 'Memproses...' : 'Masuk ke CosplayNusa',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Gunakan email atau username yang terdaftar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              // TextButton.icon already wraps the label in a Flexible, so the
              // text itself only needs to be allowed to shrink and wrap.
              label: const Text(
                'Belum punya akun? Daftar sekarang',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false, this.short = false});

  final bool compact;

  /// Drops the marketing copy on short screens so the form stays reachable
  /// without a long scroll.
  final bool short;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 430 : 510),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CosrentLogo(),
          SizedBox(height: compact ? (short ? 22 : 34) : 56),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: scheme.primary),
                const SizedBox(width: 7),
                // Flexible so a large system font scale shrinks the caption
                // instead of pushing the pill past the screen edge.
                Flexible(
                  child: Text(
                    'COSPLAY STARTS HERE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Pakai ceritanya.\nBuat kenangan.',
              style:
                  (compact
                          ? Theme.of(context).textTheme.headlineLarge
                          : Theme.of(context).textTheme.displaySmall)
                      ?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.03,
                        letterSpacing: -1.2,
                      ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Temukan kostum yang bikin setiap karakter terasa hidup.—from daily cosplay to the biggest convention.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 34),
            // Wrap instead of Row so the three highlights reflow onto a second
            // line on narrow desktop windows instead of being crushed.
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: const [
                _Feature(
                  icon: Icons.verified_outlined,
                  label: 'Kostum terkurasi',
                ),
                _Feature(
                  icon: Icons.local_shipping_outlined,
                  label: 'Mudah dipesan',
                ),
                _Feature(
                  icon: Icons.favorite_border_rounded,
                  label: 'Dibuat dengan cinta',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _accountType = 'customer';

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final state = AppState.of(context);
    final success = await state.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      username: _username.text,
      confirmation: _confirmation.text,
      accountType: _accountType,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      Navigator.of(context).pop();
      showAppSnack(context, 'Akun berhasil dibuat. Selamat datang!');
    } else {
      showAppSnack(
        context,
        state.errorMessage ?? 'Pendaftaran gagal.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat akun')),
      body: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.3,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final shortScreen = size.height < 620;
              final gutter = size.width < 380 ? 16.0 : 22.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  shortScreen ? 8 : 16,
                  gutter,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    // Without this the fields stretch across an entire
                    // desktop window, which makes them unusable to aim at.
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CosrentLogo(),
                          SizedBox(height: shortScreen ? 20 : 30),
                          Text(
                            'Mulai petualanganmu',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _accountType == 'owner'
                                ? 'Buat akun Cosrent Owner untuk mengelola kostum dan pesanan.'
                                : 'Buat akun customer untuk menyimpan booking dan melacak status sewa kostum.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          SizedBox(height: shortScreen ? 16 : 22),
                          DropdownButtonFormField<String>(
                            initialValue: _accountType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tipe akun',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'customer',
                                child: Text(
                                  'Customer — sewa kostum',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'owner',
                                child: Text(
                                  'Cosrent Owner — kelola kostum',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () => _accountType = value ?? 'customer',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _username,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.length < 3) {
                                return 'Username minimal 3 karakter';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9._-]+$')
                                  .hasMatch(value)) {
                                return 'Gunakan huruf, angka, titik, _ atau -';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Masukkan email valid'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Tampilkan password'
                                    : 'Sembunyikan password',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Minimal 6 karakter'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmation,
                            obscureText: _obscure,
                            decoration: const InputDecoration(
                              labelText: 'Konfirmasi password',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                            validator: (v) => v != _password.text
                                ? 'Password tidak sama'
                                : null,
                          ),
                          SizedBox(height: shortScreen ? 18 : 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Daftar sekarang'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Sudah punya akun? Masuk'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
