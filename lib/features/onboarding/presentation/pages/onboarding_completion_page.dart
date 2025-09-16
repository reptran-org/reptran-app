import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:reptran_app/core/constants/tokens.dart';
import 'package:reptran_app/features/auth/services/auth_service.dart';
import 'package:reptran_app/features/onboarding/services/onboarding_service.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:reptran_app/features/onboarding/presentation/widgets/onboarding_cta_button.dart';

class OnboardingCompletionPage extends StatefulWidget {
  const OnboardingCompletionPage({super.key});

  @override
  State<OnboardingCompletionPage> createState() =>
      _OnboardingCompletionPageState();
}

class _OnboardingCompletionPageState extends State<OnboardingCompletionPage> {
  Map<String, dynamic>? _draft;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await OnboardingService.readDraft();
    setState(() => _draft = draft);
  }

  Future<void> _submit() async {
    if (_draft == null) {
      _showSnack('Nothing to submit.', error: true);
      return;
    }
    setState(() => _sending = true);

    try {
      final resp = await AuthService().submitOnboarding(_draft!);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await OnboardingService.clearDraft();
        _showSnack('Onboarding submitted!');
        if (mounted) context.go('/home');
      } else {
        _showSnack('Submission failed. Try again.', error: true);
      }
    } catch (e) {
      _showSnack('Network error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OnboardingScaffold(
      icon: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.secondary],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: Icon(
          PhosphorIconsFill.handsPraying,
          size: 40,
          color: scheme.onPrimary,
        ),
      ),
      title: "Thanks for sharing with us",
      subtitle:
          "Your journey is yours — we're just here to make it easier and more consistent. You'll always know why we ask for something, and you're in control.",
      child: Column(
        children: [
          OnboardingCtaButton(
            onPressed: _submit,
            loading: _sending,
            label: 'Start My Journey',
          ),
        ],
      ),
    );
  }
}
