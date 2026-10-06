import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class OwnerIssuesPage extends StatefulWidget {
  const OwnerIssuesPage({
    super.key,
    required this.user,
    this.ownerScope = true,
  });

  final AppUser user;
  final bool ownerScope;

  @override
  State<OwnerIssuesPage> createState() => _OwnerIssuesPageState();
}

class _OwnerIssuesPageState extends State<OwnerIssuesPage> {
  String _filter = 'all';
  late Future<List<RentalIssue>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RentalIssue>> _load() =>
      AppState.of(context).repository.getIssues(status: _filter);

  Future<void> _reload() {
    final future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _resolve(RentalIssue issue) async {
    final noteController = TextEditingController(text: issue.resolutionNote);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tangani laporan'),
        content: TextField(
          controller: noteController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Catatan penyelesaian',
            hintText:
                'Contoh: noda sudah dibersihkan atau biaya sedang diproses.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            child: const Text('Tandai selesai'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => noteController.dispose(),
    );
    if (result == null || !mounted) return;
    try {
      await AppState.of(context).repository.updateIssueStatus(
        issue.id,
        'resolved',
        resolutionNote: result,
        issue: issue,
      );
      if (mounted) {
        showAppSnack(context, 'Laporan ditandai selesai.');
        _reload();
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          'Gagal menyelesaikan laporan: $error',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageIntro(
                eyebrow: 'Aftercare',
                title: 'Laporan & masalah',
                subtitle:
                    'Tangani laporan customer dengan cepat dan transparan.',
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  _Filter(
                    label: 'Semua',
                    selected: _filter == 'all',
                    onTap: () {
                      _filter = 'all';
                      _reload();
                    },
                  ),
                  const SizedBox(width: 8),
                  _Filter(
                    label: 'Terbuka',
                    selected: _filter == 'open',
                    onTap: () {
                      _filter = 'open';
                      _reload();
                    },
                  ),
                  const SizedBox(width: 8),
                  _Filter(
                    label: 'Selesai',
                    selected: _filter == 'resolved',
                    onTap: () {
                      _filter = 'resolved';
                      _reload();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<RentalIssue>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ScrollableRefreshable(child: LoadingView());
              }
              if (snapshot.hasError) {
                return ScrollableRefreshable(
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Gagal memuat laporan',
                    message: '${snapshot.error}',
                    actionLabel: 'Coba lagi',
                    onAction: _reload,
                  ),
                );
              }
              final issues = snapshot.data ?? [];
              if (issues.isEmpty) {
                return const ScrollableRefreshable(
                  child: EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Tidak ada laporan',
                    message: 'Semua masalah sudah tertangani.',
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  itemCount: issues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _IssueCard(
                    issue: issues[index],
                    onResolve: () => _resolve(issues[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.onResolve});

  final RentalIssue issue;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(issue.type);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SoftIcon(
                  icon: Icons.report_problem_outlined,
                  color: color,
                  size: 43,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${statusLabel(issue.type)} • ${issue.costumeName ?? 'Kostum'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dilaporkan oleh ${issue.customerName ?? 'customer'} • ${formatCompactDate(issue.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: issue.status, compact: true),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                issue.description,
                style: const TextStyle(height: 1.35),
              ),
            ),
            if (issue.resolutionNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 17,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue.resolutionNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (issue.isOpen) ...[
              const SizedBox(height: 13),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onResolve,
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Tandai selesai'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
