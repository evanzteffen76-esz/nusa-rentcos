import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../owner/owner_issues_page.dart';

class AdminIssuesPage extends StatelessWidget {
  const AdminIssuesPage({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) =>
      OwnerIssuesPage(user: user, ownerScope: false);
}
