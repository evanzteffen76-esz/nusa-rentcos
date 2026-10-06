import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_dashboard_page.dart';
import '../admin/admin_issues_page.dart';
import '../admin/admin_orders_page.dart';
import '../admin/admin_users_page.dart';
import '../customer/catalog_page.dart';
import '../customer/customer_home_page.dart';
import '../customer/customer_orders_page.dart';
import '../owner/owner_costumes_page.dart';
import '../owner/owner_dashboard_page.dart';
import '../owner/owner_issues_page.dart';
import '../owner/owner_orders_page.dart';
import '../profile/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user});

  final AppUser user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  /// Tabs are built the first time they are opened rather than all at once.
  /// Building every page eagerly meant four widget trees, four sets of loaded
  /// data and four image caches were resident from the moment the app started,
  /// which is enough memory pressure to get the process killed on low-RAM
  /// handsets and on small emulators.
  final _builtPages = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    // Only the landing tab is created up front; the rest wait to be opened.
    _buildPage(0);
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id ||
        oldWidget.user.role != widget.user.role ||
        oldWidget.user.area != widget.user.area) {
      _selectedIndex = 0;
      _builtPages
        ..clear()
        ..[0] = _buildPage(0);
      return;
    }

    // Same account, refreshed details (for example after saving the profile).
    // Cached pages captured the old AppUser, so recreate the ones already
    // built while keeping the same tabs open.
    if (oldWidget.user != widget.user) {
      final visited = _builtPages.keys.toList();
      _builtPages.clear();
      for (final index in visited) {
        _buildPage(index);
      }
    }
  }

  /// Builds (once) and returns the page for [index]. Callers must invoke this
  /// inside setState when the tab has not been visited yet.
  Widget _buildPage(int index) => _builtPages.putIfAbsent(
    index,
    () => switch (widget.user.area) {
      UserArea.admin => _adminPageAt(index),
      UserArea.owner => _ownerPageAt(index),
      UserArea.customer => _customerPageAt(index),
    },
  );

  /// Keeps every visited tab alive so its scroll position and loaded data
  /// survive switching, while unvisited tabs contribute nothing.
  List<Widget> _childrenFor(int count) => [
    for (var i = 0; i < count; i++) _builtPages[i] ?? const SizedBox.shrink(),
  ];

  List<_NavItem> get _items {
    if (widget.user.area == UserArea.admin) {
      return const [
        _NavItem(Icons.grid_view_rounded, 'Overview'),
        _NavItem(Icons.checkroom_outlined, 'Kostum'),
        _NavItem(Icons.people_alt_outlined, 'Pengguna'),
        _NavItem(Icons.receipt_long_outlined, 'Pesanan'),
        _NavItem(Icons.report_problem_outlined, 'Laporan'),
        _NavItem(Icons.person_outline_rounded, 'Profil'),
      ];
    }
    if (widget.user.area == UserArea.owner) {
      return const [
        _NavItem(Icons.space_dashboard_outlined, 'Dashboard'),
        _NavItem(Icons.receipt_long_outlined, 'Pesanan'),
        _NavItem(Icons.checkroom_outlined, 'Kostum'),
        _NavItem(Icons.report_problem_outlined, 'Laporan'),
        _NavItem(Icons.person_outline_rounded, 'Profil'),
      ];
    }
    return const [
      _NavItem(Icons.home_outlined, 'Beranda'),
      _NavItem(Icons.explore_outlined, 'Jelajah'),
      _NavItem(Icons.receipt_long_outlined, 'Pesanan'),
      _NavItem(Icons.person_outline_rounded, 'Profil'),
    ];
  }

  Widget _adminPageAt(int index) => switch (index) {
    0 => AdminDashboardPage(user: widget.user, onNavigate: _selectTab),
    1 => OwnerCostumesPage(user: widget.user, adminScope: true),
    2 => AdminUsersPage(user: widget.user),
    3 => AdminOrdersPage(user: widget.user),
    4 => AdminIssuesPage(user: widget.user),
    _ => ProfilePage(user: widget.user),
  };

  Widget _ownerPageAt(int index) => switch (index) {
    0 => OwnerDashboardPage(user: widget.user, onNavigate: _selectTab),
    1 => OwnerOrdersPage(user: widget.user),
    2 => OwnerCostumesPage(user: widget.user),
    3 => OwnerIssuesPage(user: widget.user),
    _ => ProfilePage(user: widget.user),
  };

  Widget _customerPageAt(int index) => switch (index) {
    0 => CustomerHomePage(
      user: widget.user,
      onBrowse: () => _selectTab(1),
      onOrders: () => _selectTab(2),
    ),
    1 => CatalogPage(user: widget.user),
    2 => CustomerOrdersPage(user: widget.user),
    _ => ProfilePage(user: widget.user),
  };

  void _selectTab(int index) {
    if (!mounted) return;
    final target = index.clamp(0, _items.length - 1);
    if (target == _selectedIndex) return;
    setState(() {
      _selectedIndex = target;
      // Build on first visit, inside setState, so the child is ready for the
      // rebuild that follows.
      _buildPage(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final items = _items;
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 760;
    final selectedIndex = _selectedIndex.clamp(0, items.length - 1);
    final title = items[selectedIndex].label;
    // Visited tabs stay in the tree (so their state survives) but unvisited
    // ones are empty, so a cold start holds one screen instead of four.
    final content = IndexedStack(
      index: selectedIndex,
      children: _childrenFor(items.length),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: width >= 400 ? 20 : 12,
        title: Row(
          children: [
            if (width >= 400) ...[
              const CosrentLogo(compact: true, showWordmark: false),
              const SizedBox(width: 11),
            ],
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mode terang/gelap',
            onPressed: state.toggleTheme,
            icon: Icon(
              state.themeMode == ThemeMode.dark ||
                      (state.themeMode == ThemeMode.system &&
                          Theme.of(context).brightness == Brightness.dark)
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          if (width >= 520)
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () =>
                  showAppSnack(context, 'Tidak ada notifikasi baru.'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: () => _selectTab(items.length - 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: UserAvatar(user: widget.user, radius: 18),
            ),
          ),
        ],
      ),
      body: useRail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _selectTab,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.85,
                  destinations: items
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: content,
                    ),
                  ),
                ),
              ],
            )
          : content,
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: _selectTab,
              destinations: items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
