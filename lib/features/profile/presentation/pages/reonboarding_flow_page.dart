// ComebackFlowScreen.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';



/// RepTran — 3-step "Comeback" flow
/// - Uses tokens & theme only
/// - Stateful: tap primary button to advance steps
class ComebackFlowPage extends StatefulWidget {
  const ComebackFlowPage({super.key});

  @override
  State<ComebackFlowPage> createState() => _ComebackFlowScreenState();
}

class _ComebackFlowScreenState extends State<ComebackFlowPage> {
  int _step = 0; // 0..2
  int _sessionsPerWeek = 2;
  double _confidence = 7;

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      // Final action (static demo)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Journey restarted 🎯',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
       final isLight = scheme.brightness == Brightness.light;


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
                    // Step Indicator
                    _StepHeader(activeIndex: _step, total: 3),
                    const SizedBox(height: AppSpacing.lg),

                    // Heading + Subheading (change per step)
                    Text(
                      _titleForStep(_step),
                      style: textTheme.headlineSmall!.copyWith(color: isLight ? scheme.primary : scheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _subForStep(_step),
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface
                            .withValues(alpha: AppOpacities.secondary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Body content
                    if (_step == 0) _buildStepOne(context) else
                    if (_step == 1) _buildStepTwo(context) else
                      _buildStepThree(context),

                    const SizedBox(height: AppSpacing.md),

                    // Primary CTA (common button)
                    _PrimaryButton(
                      label: _step < 2 ? 'Continue' : 'Restart Journey',
                      icon: _step < 2
                          ? PhosphorIconsRegular.arrowRight
                          : null,
                      onPressed: _next,
                    ),
                    if (_step == 2) ...[
  const SizedBox(height: AppSpacing.sm),
  Text(
    "Every restart is a fresh chapter. You've got this.",
    textAlign: TextAlign.center,
    style: textTheme.bodySmall,
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

  // --- Step-specific content ---


 String _stepOneSvg = '''
<svg width="100%" height="180" viewBox="0 0 240 180" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="skyGradient" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#38BFB2" stop-opacity="0.1"/>
      <stop offset="100%" stop-color="#38BFB2" stop-opacity="0.3"/>
    </linearGradient>
  </defs>

  <!-- Sky -->
  <rect width="240" height="180" fill="url(#skyGradient)" rx="12"/>

  <!-- Ground / Horizon -->
  <path d="M 0 140 Q 60 130 120 135 T 240 140 L 240 180 L 0 180 Z" fill="#38BFB2" opacity="0.2"/>

  <!-- Sun (concentric) -->
  <circle cx="120" cy="100" r="35" fill="#38BFB2" opacity="0.4"/>
  <circle cx="120" cy="100" r="28" fill="#38BFB2" opacity="0.6"/>
  <circle cx="120" cy="100" r="20" fill="#38BFB2" opacity="0.8"/>

  <!-- Rays (rotate base segment around the sun) -->
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

  <!-- Path / Trail -->
  <path d="M 120 140 L 120 175" stroke="#0F6F6E" stroke-width="4" opacity="0.3" stroke-dasharray="4 4"/>
</svg>
''';


Widget _buildStepOne(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return _Card(
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: SizedBox(
            height: AppSpacing.xl * 4, // tokenized height (~160px); SVG scales
            width: double.infinity,
            child: SvgPicture.string(
              _stepOneSvg,
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget sessionsOption(int value) {
      final selected = _sessionsPerWeek == value;
      return _ChoiceButton(
        label: '${value}x/week',
        selected: selected,
        onTap: () => setState(() => _sessionsPerWeek = value),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       LayoutBuilder(
  builder: (context, constraints) {
    // Available width for the row
    final totalWidth = constraints.maxWidth;

    // 2 columns → subtract one horizontal gap
    final itemWidth = (totalWidth - AppSpacing.xs) / 2;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        SizedBox(width: itemWidth, child: sessionsOption(2)),
        SizedBox(width: itemWidth, child: sessionsOption(3)),
        SizedBox(width: itemWidth, child: sessionsOption(4)),
        SizedBox(width: itemWidth, child: sessionsOption(5)),
      ],
    );
  },
),

        const SizedBox(height: AppSpacing.sm),
_Card(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // Title + Score row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Confidence Level', style: textTheme.titleMedium),
          Text('${_confidence.toStringAsFixed(0)}/10', style: textTheme.bodyMedium),
        ],
      ),

      const SizedBox(height: AppSpacing.sm),

      // <-- Slider must NOT be inside a Row
SliderTheme(
  data: SliderTheme.of(context).copyWith(
    trackHeight: AppSpacing.xs, // 8px token
    trackShape: const _FullWidthTrackShape(), // ← full-bleed track
    activeTrackColor: scheme.outline,    // same both sides
    inactiveTrackColor: scheme.outline,
    thumbColor: scheme.secondary,        // the ball
    overlayColor: Colors.transparent,    // no glow
    tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 0),
    showValueIndicator: ShowValueIndicator.never,
  ),
  child: Slider(
    value: _confidence,
    onChanged: (v) => setState(() => _confidence = v),
    min: 1,
    max: 10,
    // no divisions -> no dots
  ),
),
      const SizedBox(height: AppSpacing.xs),

      // Low / High labels
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Low',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              )),
          Text('High',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
              )),
        ],
      ),
    ],
  ),
)

     
      ],
    );
  }

  Widget _buildStepThree(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.secondary.withValues(alpha: AppOpacities.secondary),
                  scheme.primary.withValues(alpha: AppOpacities.primary),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: AppShadows.e2(scheme),
              border: Border.all(width: 2, color: AppColors.whiteUtility)
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: textTheme.displaySmall?.copyWith(
                color: scheme.onSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Card(
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.quotes, size: 24, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "I'm the type of person who trains ${_sessionsPerWeek}x/week.",
                  style: textTheme.bodyMedium,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      
      ],
    );
  }

  // --- Helpers ---

  String _titleForStep(int s) {
    switch (s) {
      case 0:
        return 'Welcome back, Alex 👋';
      case 1:
        return 'Adjust Plan';
      default:
        return 'Let’s set your comeback identity';
    }
  }

  String _subForStep(int s) {
    switch (s) {
      case 0:
        return "Life happens. Let's ease you in again.";
      case 1:
        return 'How many sessions/week feel doable now?';
      default:
        return 'Your renewed commitment starts here.';
    }
  }
}

/// Step header with progress bars
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.activeIndex, required this.total});

  final int activeIndex; // 0-based
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isCompletedOrActive = i <= activeIndex;
        final bool isActive = i == activeIndex;

        return Padding(
          padding: EdgeInsets.only(
            right: i == total - 1 ? 0 : AppSpacing.xs,
          ),
          child: Container(
            width: isActive ? 60 : 40, // ← EXACT WIDTHS YOU REQUESTED
            height: AppSpacing.xs,     // token height (8px)
            decoration: BoxDecoration(
              color: isCompletedOrActive
                  ? scheme.primary
                  : scheme.outline,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
          ),
        );
      }),
    );
  }
}

/// Tokenized default card
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon; // ← now nullable
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.e1(scheme),
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
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onSecondary,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(icon, size: 24, color: scheme.onSecondary),
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

/// Outline choice button using tokens
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: double.infinity, // <-- important so it fills the SizedBox
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: AppOpacities.disabled)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? PhosphorIconsRegular.checkCircle
                  : PhosphorIconsRegular.circle,
              size: 24,
              color: selected ? scheme.primary : scheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 2.0;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    // ← No side inset: use the entire width available
    return Rect.fromLTWH(offset.dx, trackTop, parentBox.size.width, trackHeight);
  }
}
