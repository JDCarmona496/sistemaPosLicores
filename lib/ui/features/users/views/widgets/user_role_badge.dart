import 'package:flutter/material.dart';

import '../../../../../domain/models/user.dart';

class UserRoleBadge extends StatelessWidget {
  final UserRole role;

  const UserRoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (role) {
      UserRole.admin => (Colors.purple, Icons.admin_panel_settings),
      UserRole.seller => (Colors.blue, Icons.point_of_sale),
      UserRole.delivery => (Colors.orange, Icons.delivery_dining),
    };

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(role.label),
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color.withAlpha(100)),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
