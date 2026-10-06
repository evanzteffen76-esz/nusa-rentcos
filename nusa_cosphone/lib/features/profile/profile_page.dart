import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../settings/api_settings_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final roleLabel = user.isAdmin
        ? 'Administrator'
        : user.isOwner
        ? 'Cosrent Owner'
        : 'Customer';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        const PageIntro(
          eyebrow: 'Akun saya',
          title: 'Profil',
          subtitle: 'Atur preferensi dan informasi akunmu.',
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
                AppColors.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              UserAvatar(user: user, radius: 34, showStatus: true),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profil',
                onPressed: () => _openEditProfile(context),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Preferensi tampilan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 11),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SoftIcon(
                      icon: Icons.palette_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mode tema',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pilih tampilan yang paling nyaman.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ThemeChoice(
                      label: 'Sistem',
                      icon: Icons.brightness_auto_outlined,
                      selected: state.themeMode == ThemeMode.system,
                      onTap: () => state.setThemeMode(ThemeMode.system),
                    ),
                    _ThemeChoice(
                      label: 'Terang',
                      icon: Icons.light_mode_outlined,
                      selected: state.themeMode == ThemeMode.light,
                      onTap: () => state.setThemeMode(ThemeMode.light),
                    ),
                    _ThemeChoice(
                      label: 'Gelap',
                      icon: Icons.dark_mode_outlined,
                      selected: state.themeMode == ThemeMode.dark,
                      onTap: () => state.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (user.isOwner) ...[
          Card(
            child: ListTile(
              leading: SoftIcon(
                icon: Icons.account_balance_outlined,
                color: AppColors.success,
              ),
              title: const Text(
                'Rekening bank',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                user.hasBankAccount
                    ? '${user.bankDetails.bankName} • '
                          '${user.bankDetails.maskedAccountNumber}'
                    : 'Belum diisi, sehingga pelanggan tidak bisa transfer.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _editBankDetails(context, state),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Card(
          child: Column(
            children: [
              _ProfileAction(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                subtitle: 'Pengingat booking dan pembaruan status',
                onTap: () => showAppSnack(
                  context,
                  'Preferensi notifikasi segera hadir.',
                ),
              ),
              const Divider(height: 1),
              _ProfileAction(
                icon: Icons.help_outline_rounded,
                title: 'Pusat bantuan',
                subtitle: 'FAQ dan panduan sewa kostum',
                onTap: () => _showHelp(context),
              ),
              const Divider(height: 1),
              _ProfileAction(
                icon: Icons.settings_ethernet_rounded,
                title: 'Pengaturan aplikasi',
                subtitle: 'Bahasa, tema, dan alamat server API',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ApiSettingsPage(),
                  ),
                ),
              ),
              const Divider(height: 1),
              _ProfileAction(
                icon: Icons.info_outline_rounded,
                title: 'Tentang CosplayNusa',
                subtitle: 'Versi 1.0.0 • dibuat untuk para cosplayer',
                onTap: () => showAppSnack(
                  context,
                  'CosplayNusa • Pakai ceritanya, buat kenangan.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context, state),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Keluar dari akun'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () => _confirmDeleteAccount(context, state),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Hapus akun'),
        ),
        const SizedBox(height: 15),
        Center(
          child: Text(
            'Data tersimpan aman di perangkat ini',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditProfilePage(user: AppState.of(context).currentUser ?? user),
      ),
    );
    if (changed != true || !context.mounted) return;
    // The shell rebuilds from AppState, so the new name/email shows up as soon
    // as the edit page pops.
    showAppSnack(context, 'Profil berhasil diperbarui.');
  }

  Future<void> _confirmLogout(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Token akses akan dicabut dan data lokal akan dibersihkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.logout();
  }

  /// Deleting an account cascades to the user's costumes, orders and reports,
  /// so the dialog spells that out and asks for the password to prove identity.
  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AppState state,
  ) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hapus akun permanen?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akun, kostum, dan riwayat pesanan kamu akan dihapus '
                  'permanen dan tidak dapat dikembalikan.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Password akun',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: passwordController.text.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus permanen'),
            ),
          ],
        ),
      ),
    );

    final password = passwordController.text;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => passwordController.dispose(),
    );

    if (confirmed != true || password.isEmpty || !context.mounted) return;

    final ok = await state.deleteAccount(password);
    if (!context.mounted) return;

    if (ok) {
      // Clearing currentUser drops the whole shell, which lands back on the
      // login page on its own.
      showAppSnack(context, 'Akun berhasil dihapus.');
    } else {
      showAppSnack(
        context,
        state.errorMessage ?? 'Gagal menghapus akun.',
        isError: true,
      );
    }
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pusat bantuan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            const Text(
              '• Pilih kostum dan tanggal sewa yang tersedia.\n• Tunggu owner menyetujui booking kamu.\n• Laporkan masalah sebelum mengembalikan kostum.\n• Hubungi owner jika ada kendala pada proses sewa.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: SoftIcon(
      icon: icon,
      color: Theme.of(context).colorScheme.primary,
      size: 40,
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(
      subtitle,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

/// Edit the bank coordinates customers transfer to.
///
/// The three fields are written as a unit: the server rejects a partial trio,
/// so the dialog validates the same rule before spending a round trip on it.
Future<void> _editBankDetails(BuildContext context, AppState state) async {
  final user = state.currentUser;
  if (user == null) return;

  final bankName = TextEditingController(text: user.bankDetails.bankName);
  final accountNumber = TextEditingController(
    text: user.bankDetails.accountNumber,
  );
  final accountHolder = TextEditingController(
    text: user.bankDetails.accountHolder,
  );

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Rekening bank'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pelanggan memakai rekening ini saat memilih transfer bank.'
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bankName,
              decoration: const InputDecoration(
                labelText: 'Nama bank',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: accountNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor rekening',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: accountHolder,
              decoration: const InputDecoration(
                labelText: 'Atas nama',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );

  // The dialog owns the controllers only while it is open.
  final details = BankDetails(
    bankName: bankName.text,
    accountNumber: accountNumber.text,
    accountHolder: accountHolder.text,
  );
  bankName.dispose();
  accountNumber.dispose();
  accountHolder.dispose();

  if (saved != true || !context.mounted) return;
  final ok = await state.updateProfile(bankDetails: details);
  if (!context.mounted) return;
  showAppSnack(
    context,
    ok
        ? 'Data rekening disimpan.'
        : state.errorMessage ?? 'Gagal menyimpan rekening.',
    isError: !ok,
  );
}
