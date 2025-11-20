import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// A widget that guards routes based on user roles.
/// 
/// This widget checks if the current user has the required role to access
/// the protected content. If not, it redirects to the fallback route.
/// 
/// Note: requiredRole is still a string ('student' or 'instructor') for backward compatibility,
/// but internally it uses the isStudent boolean for access control.
class RoleGuard extends StatefulWidget {
  final String requiredRole;
  final Widget child;
  final String fallbackRoute;
  final Widget? loadingWidget;

  const RoleGuard({
    Key? key,
    required this.requiredRole,
    required this.child,
    this.fallbackRoute = '/login',
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _isChecking = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (authProvider.currentUser == null) {
      _redirect();
      return;
    }

    // Enforce role-based access
    final hasAccess = await authProvider.enforceRoleAccess(widget.requiredRole);
    
    if (mounted) {
      setState(() {
        _isChecking = false;
        _hasAccess = hasAccess;
      });
      
      if (!hasAccess) {
        _redirect();
      }
    }
  }

  void _redirect() {
    // Add a small delay to ensure the navigation works properly
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(widget.fallbackRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return widget.loadingWidget ?? 
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
    
    return _hasAccess ? widget.child : const SizedBox.shrink();
  }
}