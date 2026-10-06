import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, required this.user});

  final AppUser user;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _search = TextEditingController();
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<AppUser>> _load() async {
    final users = await AppState.of(context).repository.getUsers();
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where(
          (user) =>
              user.name.toLowerCase().contains(query) ||
              user.username.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _openForm([AppUser? user]) async {
    final result = await showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _UserFormSheet(user: user),
    );
    if (result == null || !mounted) return;
    final repository = AppState.of(context).repository;
    try {
      if (user == null) {
        await repository.createUser(
          name: result.name,
          username: result.username,
          email: result.email,
          password: result.password.isEmpty ? 'password' : result.password,
          role: result.role,
          isAdmin: result.isAdmin,
          isCosrentOwner: result.isCosrentOwner,
        );
        if (!mounted) return;
        showAppSnack(context, 'Pengguna baru berhasil dibuat.');
      } else {
        await repository.updateUser(result);
        if (!mounted) return;
        showAppSnack(context, 'Data pengguna berhasil diperbarui.');
      }
      _reload();
    } catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          'Gagal menyimpan pengguna: $error',
          isError: true,
        );
      }
    }
  }

  Future<void> _delete(AppUser user) async {
    if (user.id == widget.user.id) {
      showAppSnack(
        context,
        'Akun admin yang sedang digunakan tidak dapat dihapus.',
        isError: true,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${user.name}?'),
        content: const Text(
          'Pesanan dan data terkait pengguna juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppState.of(context).repository.deleteUser(user.id);
      if (mounted) {
        showAppSnack(context, 'Pengguna berhasil dihapus.');
        _reload();
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, 'Gagal menghapus: $error', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: PageIntro(
                        eyebrow: 'Administrasi',
                        title: 'Pengguna',
                        subtitle: 'Kelola akses customer, owner, dan admin.',
                      ),
                    ),
                    SoftIcon(
                      icon: Icons.people_alt_outlined,
                      color: AppColors.info,
                      size: 50,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onSubmitted: (_) => _reload(),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ScrollableRefreshable(child: LoadingView());
                }
                if (snapshot.hasError) {
                  return ScrollableRefreshable(
                    child: EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Gagal memuat pengguna',
                      message: '${snapshot.error}',
                      actionLabel: 'Coba lagi',
                      onAction: _reload,
                    ),
                  );
                }
                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const ScrollableRefreshable(
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'Pengguna tidak ditemukan',
                      message: 'Coba kata kunci lain.',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _UserCard(
                      user: users[index],
                      onEdit: () => _openForm(users[index]),
                      onDelete: () => _delete(users[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah pengguna'),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isAdmin
        ? AppColors.danger
        : user.isOwner
        ? AppColors.secondary
        : AppColors.info;
    final roleLabel = user.isAdmin
        ? 'Admin'
        : user.isOwner
        ? 'Owner'
        : 'Customer';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            UserAvatar(user: user, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({this.user});
  final AppUser? user;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  String _role = 'customer';

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _name = TextEditingController(text: user?.name ?? '');
    _username = TextEditingController(text: user?.username ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _password = TextEditingController(text: user?.password ?? '');
    _role = user == null ? 'customer' : user.role;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final user = widget.user;
    Navigator.of(context).pop(
      AppUser(
        id: user?.id ?? 0,
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
        isAdmin: _role == 'admin',
        isCosrentOwner: _role == 'owner',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user == null ? 'Tambah pengguna' : 'Edit pengguna',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              Text(
                'Atur informasi dan role akses pengguna.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
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
                  if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                    return 'Gunakan huruf, angka, titik, _ atau -';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email tidak valid' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (v) =>
                    widget.user == null && (v == null || v.length < 6)
                    ? 'Minimal 6 karakter'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(
                    value: 'owner',
                    child: Text('Owner / Cosrent'),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) =>
                    setState(() => _role = value ?? 'customer'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    widget.user == null ? 'Buat pengguna' : 'Simpan perubahan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
