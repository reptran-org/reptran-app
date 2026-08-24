// HelpAndAboutPage.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelpAndAboutPage extends StatefulWidget {
  const HelpAndAboutPage({super.key, this.targetSection});

  final String? targetSection;

  @override
  State<HelpAndAboutPage> createState() => _HelpAndAboutPageState();
}

class _HelpAndAboutPageState extends State<HelpAndAboutPage> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _faqKey = GlobalKey();
  final GlobalKey _supportKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection();
    });
  }

  void _scrollToSection() {
    if (widget.targetSection == null) return;

    GlobalKey? targetKey;

    switch (widget.targetSection) {
      case 'faq':
        targetKey = _faqKey;
        break;
      case 'support':
        targetKey = _supportKey;
        break;
      case 'about':
        targetKey = _aboutKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              // firstSectionHasBg: true → no root padding.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== First section with its own BG and full framing inside =====
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      boxShadow: AppShadows.e0,
                    ), // uses scheme.surface by Scaffold
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xxl,
                      AppSpacing.md,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading & subheading (includeHeadingSubheading: true)
                        Text('Help & About', style: tt.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "We're here to keep you consistent — not perfect.",
                          style: tt.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(
                              alpha: AppOpacities.secondary,
                            ),
                          ),
                          softWrap: true,
                        ),

                        // FAQ Section Header
                      ],
                    ),
                  ),

                  // ===== Rest of the page with normal horizontal padding =====
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          key: _faqKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                icon: PhosphorIconsRegular.question,
                                label: 'Frequently Asked Questions',
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // FAQ items (static)
                            _FaqItem(
  title: 'How do I recover after missing workouts?',
  answer:
      'Just show up again. RepTran focuses on recovery, not punishment. Missing once doesn’t reset your identity.',
),
SizedBox(height: AppSpacing.sm),

_FaqItem(
  title: 'How are rewards calculated?',
  answer:
      'Rewards are based on consistency, not intensity. Showing up regularly matters more than pushing hard occasionally.',
),
SizedBox(height: AppSpacing.sm),

_FaqItem(
  title: 'Can I change my identity goal?',
  answer:
      'Yes. Your identity evolves. You can update your goal anytime to match who you want to become.',
),
SizedBox(height: AppSpacing.sm),

_FaqItem(
  title: "What if I don't want notifications?",
  answer:
      'You can disable them anytime. RepTran adapts to you — not the other way around.',
),
SizedBox(height: AppSpacing.sm),

_FaqItem(
  title: 'How does the community feature work?',
  answer:
      'It’s a soft accountability layer. No pressure, no comparison — just shared consistency.',
),
                              const SizedBox(height: AppSpacing.md),

                              // Contact Support
                              Container(
                                key: _supportKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionHeader(
                                      icon: PhosphorIconsRegular.headset,
                                      label: 'Contact Support',
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    const _SupportCard(),

                                    const SizedBox(height: AppSpacing.md),

                                    // About RepTran
                                    Container(
                                      key: _aboutKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _SectionHeader(
                                            icon: PhosphorIconsRegular.heart,
                                            label: 'About RepTran',
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          const _AboutCard(),
                                        ],
                                      ),
                                    ),

                                    // Bottom framing outside sections
                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ===================== Helpers =====================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, size: 24, color: scheme.secondary),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: tt.titleMedium,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.title,
    required this.answer,
  });

  final String title;
  final String answer;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      constraints: const BoxConstraints(
        minHeight: 72, // 👈 ensures 2-line visual height
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => setState(() => _isOpen = !_isOpen),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: tt.bodyMedium,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: const StrutStyle(
                        height: 1.4, // 👈 consistent line height
                        forceStrutHeight: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      PhosphorIconsRegular.caretDown,
                      size: 20,
                      color: scheme.onSurface.withValues(
                        alpha: AppOpacities.secondary,
                      ),
                    ),
                  ),
                ],
              ),

              /// EXPANDABLE ANSWER
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: _isOpen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.answer,
                            style: tt.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(
                                alpha: AppOpacities.secondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Just the icon now, no container
          Icon(
            PhosphorIconsRegular.envelopeSimple,
            size: 24,
            color: scheme.secondary,
          ),

          const SizedBox(width: AppSpacing.sm),

          // Right side content stacked, aligned at the same start
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need help?', style: tt.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Email us at support@reptran.com',
                  style: tt.bodyMedium,
                  softWrap: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "We typically respond within 24 hours. We're a small team committed to helping you succeed.",
                  style: tt.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(
                      alpha: AppOpacities.secondary,
                    ),
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _repTranEmblemSvg = '''
<svg width="120" height="120" viewBox="0 0 120 120">
  <circle cx="60" cy="60" r="45" fill="none" stroke="#0F6F6E" stroke-width="3" stroke-dasharray="8 4" opacity="0.3"/>
  <circle cx="60" cy="60" r="35" fill="none" stroke="#38BFB2" stroke-width="3" stroke-dasharray="6 3" opacity="0.5"/>
  <circle cx="60" cy="60" r="25" fill="none" stroke="#4CD964" stroke-width="3" opacity="0.7"/>
  <circle cx="60" cy="60" r="12" fill="#0F6F6E" opacity="0.2"/>
  <circle cx="60" cy="15" r="4" fill="#38BFB2" opacity="0.8"/>
  <circle cx="105" cy="60" r="4" fill="#4CD964" opacity="0.8"/>
  <circle cx="60" cy="105" r="4" fill="#FF6B5A" opacity="0.8"/>
</svg>
''';

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: AppBorders.boxCard(scheme),
        boxShadow: AppShadows.e1(scheme),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered emblem
          Center(
            child: SizedBox(
              height: 80,
              width: 80,
              child: SvgPicture.string(_repTranEmblemSvg),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Bold first line (headline-style)
          RichText(
            text: TextSpan(
              style: tt.bodyMedium?.copyWith(color: scheme.onSurface),
              children: [
                TextSpan(
                  text: 'RepTran is built from first principles',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(
                  text:
                      ' to help people become consistent — by aligning identity, emotion, and environment.',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          _Para(
            'We believe that lasting change doesn\'t come from willpower or motivation. It comes from designing systems that make your desired behavior the path of least resistance.',
          ),
          _Para(
            'Identity shapes action. When you see yourself as “someone who works out,” showing up becomes natural. RepTran reinforces that identity through small, consistent wins — not grand transformations.',
          ),
          _Para(
            'Emotion drives momentum. We celebrate your progress, acknowledge setbacks without judgment, and remind you why you started. Every notification is designed to feel supportive, never shaming.',
          ),
          _Para(
            'Environment enables habit. By triggering the right cues at the right moments, we help you build automatic routines. The goal isn\'t to think about working out — it\'s to just do it, naturally.',
          ),

          Divider(),
          const SizedBox(height: AppSpacing.sm),

          Text(
            '"We\'re not here to make you perfect. We\'re here to help you show up, consistently, as the person you want to become."',
            style: tt.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
            softWrap: true,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text('— The RepTran Team', style: tt.bodySmall, softWrap: true),
        ],
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: tt.bodyMedium, softWrap: true),
    );
  }
}
