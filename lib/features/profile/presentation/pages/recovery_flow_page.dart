// RecoverFlowScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:go_router/go_router.dart';



/// RepTran — Recover Flow (2-step)
/// Step 1: Missed today?  -> Illustration + CTA
/// Step 2: Quick Reset Goals -> 2x2 options + CTAs
class RecoverFlowPage extends StatefulWidget {
  const RecoverFlowPage({super.key});

  @override
  State<RecoverFlowPage> createState() => _RecoverFlowScreenState();
}

class _RecoverFlowScreenState extends State<RecoverFlowPage> {
  int _step = 0; // 0..1
  int _selectedQuick = 0;

  void _next() {
    if (_step < 1) {
      setState(() => _step += 1);
    } else {
      // Static demo action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quick reset started!',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLight = cs.brightness == Brightness.light;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xxl,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StepHeader(activeIndex: _step, total: 2),
                    const SizedBox(height: AppSpacing.md),

                    // Heading + Subheading
                    Text(
                      _step == 0 ? 'Missed today?' : 'Quick Reset Goals',
                      style: textTheme.headlineSmall!.copyWith(color: isLight ? cs.primary : cs.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _step == 0
                          ? "That's okay — consistency is built on comebacks."
                          : 'Pick something small to stay on track.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface
                            .withValues(alpha: AppOpacities.secondary),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (_step == 0) _buildStepOne(context) else _buildStepTwo(context),

                    const SizedBox(height: AppSpacing.lg),

                    // Primary CTA
                    _PrimaryButton(
                      label: _step == 0 ? 'Choose a quick reset' : 'Start Now',
                      icon: _step == 0 ? PhosphorIconsRegular.arrowRight : null,
                      onPressed: _next,
                    ),

                    // Outline secondary CTA only on step 2
                    if (_step == 1) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _OutlineButton(
                        label: 'Plan Tomorrow',
                        icon: PhosphorIconsRegular.calendarBlank,
                        onPressed: () {},
                      ),
                    ],

                    // Helper text under primary on step 0
                    if (_step == 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Small actions keep your momentum alive',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepOne(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: SizedBox(
              height: AppSpacing.xl * 4, // ~160px visual well
              child: SvgPicture.string(
                _recoverSvg,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
         
        ],
      ),
    );
  }




Widget _buildStepTwo(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  IconData _leadingIconFor(int i) {
    switch (i) {
      case 0:
        return PhosphorIconsRegular.pulse;        // mobility / flow
      case 1:
        return PhosphorIconsRegular.footprints; // walk
      case 2:
        return PhosphorIconsRegular.plant;            // breathe / stretch
      default:
        return PhosphorIconsRegular.fireSimple;           // core / quick
    }
  }

  Widget tile({
    required int index,
    required String emoji,
    required String title,
    required String meta,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      onTap: () => setState(() => _selectedQuick = index),
      child: ConstrainedBox(
        // equal height for all cards; tall enough for the content
        constraints: BoxConstraints(minHeight: AppSpacing.lg * 7),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.positive, width: 1),
            boxShadow: AppShadows.e1(cs),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 40x40 positive circle + positive icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_leadingIconFor(index), size: 24, color: AppColors.positive),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Emoji (use theme typography per tokens)
              Text(emoji, style: tt.bodyMedium, textAlign: TextAlign.center),

              const SizedBox(height: AppSpacing.sm),

              Text(
                title,
                style: tt.bodyMedium?.copyWith(fontWeight: AppTypography.wSemibold),
                textAlign: TextAlign.center,
                softWrap: true,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(meta, style: tt.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final w = (constraints.maxWidth - AppSpacing.sm) / 2; // two columns
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          SizedBox(width: w, child: tile(index: 0, emoji: '🧘‍♂️', title: '7-min mobility flow', meta: '7 min')),
          SizedBox(width: w, child: tile(index: 1, emoji: '🚶', title: '10-min walk', meta: '10 min')),
          SizedBox(width: w, child: tile(index: 2, emoji: '🌿', title: 'Stretch + breathe', meta: '5 min')),
          SizedBox(width: w, child: tile(index: 3, emoji: '💪', title: 'Short core set', meta: 'Quick')),
        ],
      );
    },
  );
}

}

/// Centered step header: previous + current filled, active bar wider (60px) than inactive (40px)
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.activeIndex, required this.total});
  final int activeIndex; // 0-based
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final filled = i <= activeIndex;
        final isActive = i == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: i == total - 1 ? 0 : AppSpacing.xs),
          child: Container(
            width: isActive ? 60 : 40, // per design request
            height: AppSpacing.xs,
            decoration: BoxDecoration(
              color: filled
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: AppOpacities.disabled),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
          ),
        );
      }),
    );
  }
}

/// Default tokenized card
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(cs),
        boxShadow: AppShadows.e1(cs),
      ),
      child: child,
    );
  }
}

/// Primary button (scheme.secondary) — icon optional
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: AppShadows.e1(cs),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            // onTap: () => context.push('/profile/recovery-completion'), // ← added
            onTap: onPressed,

            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: tt.titleMedium?.copyWith(color: cs.onSecondary),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(icon, size: 24, color: cs.onSecondary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline button using primary border
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: cs.secondary, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: cs.secondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: tt.titleMedium?.copyWith(color: cs.secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- SVG used in Step 1 illustration ---
const String _recoverSvg = '''
<svg width="100%" height="180" viewBox="0 0 240 180" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="skyGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#38BFB2" stop-opacity="0.1"/>
      <stop offset="100%" stop-color="#38BFB2" stop-opacity="0.3"/>
    </linearGradient>
  </defs>
  <rect width="240" height="180" fill="url(#skyGradient)" rx="12"/>
  <path d="M 0 140 Q 60 130 120 135 T 240 140 L 240 180 L 0 180 Z" fill="#38BFB2" opacity="0.2"/>
  <circle cx="120" cy="100" r="35" fill="#38BFB2" opacity="0.4"/>
  <circle cx="120" cy="100" r="28" fill="#38BFB2" opacity="0.6"/>
  <circle cx="120" cy="100" r="20" fill="#38BFB2" opacity="0.8"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(0 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(30 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(60 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(90 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(120 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(150 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(180 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(210 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(240 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(270 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(300 120 100)"/>
  <line x1="120" y1="55" x2="120" y2="40" stroke="#38BFB2" stroke-width="3" stroke-linecap="round" opacity="0.5" transform="rotate(330 120 100)"/>
  <path d="M 120 140 L 120 175" stroke="#0F6F6E" stroke-width="4" opacity="0.3" stroke-dasharray="4 4"/>
</svg>
''';
