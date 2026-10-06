import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';

/// Lets the signed-in user edit their own name, username, email and password.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _username = TextEditingController(text: widget.user.username);
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final wantsPasswordChange = _newPassword.text.isNotEmpty;
    setState(() => _saving = true);

    final state = AppState.of(context);
    final ok = await state.updateProfile(
      name: _name.text,
      username: _username.text.trim().isEmpty ? null : _username.text,
      email: _email.text,
      password: wantsPasswordChange ? _newPassword.text : null,
      confirmation: wantsPasswordChange ? _confirmPassword.text : null,
      currentPassword: wantsPasswordChange ? _currentPassword.text : null,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // The password fields must not keep the old secret in memory.
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      showAppSnack(context, 'Profil berhasil diperbarui.');
      Navigator.of(context).pop(true);
      return;
    }

    showAppSnack(
      context,
      state.errorMessage ?? 'Gagal menyimpan perubahan.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profil')),
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
                    // Keeps fields at a comfortable width on tablets and
                    // desktop instead of stretching across the window.
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IdentityCard(user: widget.user),
                          SizedBox(height: shortScreen ? 18 : 24),
                          Text(
                            'Informasi akun',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _username,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              helperText: 'Dipakai untuk masuk bersama email',
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return null;
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
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Masukkan email valid'
                                : null,
                          ),
                          SizedBox(height: shortScreen ? 20 : 28),
                          Row(
                            children: [
                              const Expanded(child: Divider(height: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'Ganti password',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const Expanded(child: Divider(height: 1)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Kosongkan bila tidak ingin mengganti password.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _currentPassword,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              labelText: 'Password saat ini',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: _toggle(
                                _obscureCurrent,
                                () => setState(
                                  () => _obscureCurrent = !_obscureCurrent,
                                ),
                              ),
                            ),
                            validator: (v) => _newPassword.text.isEmpty
                                ? null
                                : (v == null || v.isEmpty)
                                ? 'Wajib diisi untuk mengganti password'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _newPassword,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              labelText: 'Password baru',
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: _toggle(
                                _obscureNew,
                                () =>
                                    setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? null
                                : (v.length < 6 ? 'Minimal 6 karakter' : null),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPassword,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Ulangi password baru',
                              prefixIcon: const Icon(
                                Icons.verified_user_outlined,
                              ),
                              suffixIcon: _toggle(
                                _obscureConfirm,
                                () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) => _newPassword.text.isEmpty
                                ? null
                                : (v != _newPassword.text
                                      ? 'Password tidak sama'
                                      : null),
                          ),
                          SizedBox(height: shortScreen ? 20 : 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _saving ? 'Menyimpan...' : 'Simpan perubahan',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Batal'),
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

  Widget _toggle(bool hidden, VoidCallback onPressed) => IconButton(
    tooltip: hidden ? 'Tampilkan password' : 'Sembunyikan password',
    onPressed: onPressed,
    icon: Icon(
      hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
  );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.isAdmin
        ? 'Administrator'
        : user.isOwner
        ? 'Cosrent Owner'
        : 'Customer';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          UserAvatar(user: user, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  roleLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
