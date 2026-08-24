import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:reptran_app/features/auth/services/auth_flow_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    await AuthFlowService.decideAndRoute(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final brightness = scheme.brightness;
    final logoSize = size.width * 0.40;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
                  brightness == Brightness.dark
                      ? 'assets/images/reptran_logo_white.png'
                      : 'assets/images/reptran_logo.png',
                  width: logoSize,
                  height: logoSize,
                )
                .animate()
                .fadeIn(duration: 350.ms)
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),

            Text(
                  'Transform through reps',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .slideY(begin: 0.4, end: 0.0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
