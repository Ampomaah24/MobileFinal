import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget adminWidget;
  final Widget? userWidget;
  final bool hideIfUnauthorized;

  const RoleBasedWidget({
    Key? key,
    required this.adminWidget,
    this.userWidget,
    this.hideIfUnauthorized = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    if (authService.isAdmin) {
      return adminWidget;
    } else if (userWidget != null) {
      return userWidget!;
    } else if (!hideIfUnauthorized) {
      return const SizedBox.shrink(); // Empty widget if not authorized and not hiding
    } else {
      return const SizedBox.shrink(); // Empty widget if not authorized
    }
  }
}