import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // for navigation
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/auth/services/auth_services.dart';
import 'package:reptran_app/features/welcome/routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loggingOut = false;

  Future<void> _onLogoutPressed() async {
    setState(() => _loggingOut = true);
    await AuthServices.logout(callServer: true);
    setState(() => _loggingOut = false);

    // Decide where to route: if device had account marker, go to login,
    // otherwise go to Welcome (marketing) — this is up to you.
    final hasAccount = await AuthServices.hasAccountMarker();
    if (!mounted) return;
    if (hasAccount) {
      context.go('/auth/login');
    } else {
      context.go(WelcomeRoutes.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          "RepTran",
          style: TextStyle(
            fontSize: AppTypography.title,
            fontWeight: AppTypography.wBold,
            color: AppColors.whiteUtility,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsFill.bell),
            color: AppColors.whiteUtility,
            onPressed: () {},
          ),
          // Logout icon
          IconButton(
            icon: _loggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(PhosphorIconsRegular.signOut),
            color: AppColors.whiteUtility,
            onPressed: _loggingOut ? null : _onLogoutPressed,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          // rest of your body unchanged...
        ),
      ),
    );
  }
}
