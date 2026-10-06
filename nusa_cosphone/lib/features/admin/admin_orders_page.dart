import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../owner/owner_orders_page.dart';

/// Admin view of every rental order.
///
/// The repository selects `/admin/orders` from the authenticated role, while
/// the shared order list keeps the same status filters and detail workflow as
/// the owner view.
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return OwnerOrdersPage(user: user, adminScope: true);
  }
}
