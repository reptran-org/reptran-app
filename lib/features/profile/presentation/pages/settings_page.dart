// SettingsPage.dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reptran_app/core/constants/tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:reptran_app/features/auth/services/auth_services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoggingOut = false;

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
              // ⬇️ firstSectionHasBg = true
              // No root horizontal padding or top padding.
              // Top AppSpacing.xxl is applied INSIDE the first section.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== First Section with its own BG and padding =====
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      boxShadow: AppShadows.e0,
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, // left
                      AppSpacing.xxl, // top framing goes INSIDE
                      AppSpacing.md, // right
                      AppSpacing.xxl, // bottom framing goes INSIDE
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading + Subheading (includeHeadingSubheading = true)
                        Text(
                          'Settings',
                          style: tt.headlineSmall,
                          softWrap: true,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Manage your account, preferences, and reminders.',
                          style: tt.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(
                              alpha: AppOpacities.secondary,
                            ),
                          ),
                          softWrap: true,
                        ),

                        // Section: ACCOUNT
                      ],
                    ),
                  ),

                  // ===== Rest of the page (normal horizontal padding) =====
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),

                        _SectionHeader(label: 'ACCOUNT'),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.user,
                          title: 'Edit Profile',
                          subtitle: 'Update your name and personal details',
                          onTap: () {
                            context.push('/profile/edit-profile');
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.envelopeSimple,
                          title: 'Email & Password',
                          subtitle: 'Change your login credentials',
                          onTap: () {
                            context.push('/profile/email-password');
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.lockSimple,
                          title: 'Privacy & Data',
                          subtitle: 'Control your data and privacy settings',
                            onTap: () {
                            context.push('/profile/privacy-and-data');
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Section: APP PREFERENCES
                        _SectionHeader(label: 'APP PREFERENCES'),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.bellSimple,
                          title: 'Notifications',
                          subtitle:
                              'Manage notification preferences → Notification Center',
                           onTap: () {
                            context.push('/profile/notifications');
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.faders,
                          title: 'Behavior Settings',
                          subtitle:
                              'Configure triggers, reminders, and identity tone → Trigger Settings',
                          route: '/profile/settings/environment',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.palette,
                          title: 'Appearance',
                          subtitle: 'Toggle between Light and Dark theme',
                          route: '/profile/appearance',
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Section: SUPPORT
                        _SectionHeader(label: 'SUPPORT'),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.question,
                          title: 'Help & FAQs',
                          subtitle: 'Find answers to common questions',
                          onTap: () =>
                              context.pushNamed('helpAndAbout', extra: 'faq'),
                        ),

                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.info,
                          title: 'About RepTran',
                          subtitle: 'Learn more about the app and our mission',
                          onTap: () =>
                              context.pushNamed('helpAndAbout', extra: 'about'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SettingsTile(
                          icon: PhosphorIconsRegular.paperPlaneTilt,
                          title: 'Contact Support',
                          subtitle: 'Get in touch with our team',
                          onTap: () => context.pushNamed(
                            'helpAndAbout',
                            extra: 'support',
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Footer: Version + Logout
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Version 1.0.0',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: AppOpacities.tertiary,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: _OutlineButton(
                                  label: _isLoggingOut
                                      ? 'Logging out...'
                                      : 'Log Out',
                                  icon: _isLoggingOut
                                      ? null
                                      : PhosphorIconsRegular.signOut,
                                  isLoading: _isLoggingOut,
                                  onTap: _isLoggingOut
                                      ? null
                                      : () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (_) {
                                              final scheme = Theme.of(
                                                context,
                                              ).colorScheme;
                                              final tt = Theme.of(
                                                context,
                                              ).textTheme;

                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                backgroundColor: scheme.surface,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    AppSpacing.lg,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // 🔴 Title
                                                      Text(
                                                        'Log out?',
                                                        style: tt.titleLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),

                                                      const SizedBox(
                                                        height: AppSpacing.sm,
                                                      ),

                                                      // 📝 Subtitle
                                                      Text(
                                                        'You will need to log in again to continue using RepTran.',
                                                        style: tt.bodyMedium
                                                            ?.copyWith(
                                                              color: scheme
                                                                  .onSurface
                                                                  .withValues(
                                                                    alpha: 0.7,
                                                                  ),
                                                            ),
                                                      ),

                                                      const SizedBox(
                                                        height: AppSpacing.lg,
                                                      ),

                                                      // 🔘 Actions
                                                      Row(
                                                        children: [
                                                          // Cancel
                                                          Expanded(
                                                            child: GestureDetector(
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: Container(
                                                                height: 44,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                  border: Border.all(
                                                                    color: scheme
                                                                        .outline,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  'Cancel',
                                                                  style: tt
                                                                      .titleMedium,
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          const SizedBox(
                                                            width:
                                                                AppSpacing.sm,
                                                          ),

                                                          // Logout (accent)
                                                          Expanded(
                                                            child: GestureDetector(
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: Container(
                                                                height: 44,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                  color: AppColors
                                                                      .accent,
                                                                ),
                                                                child: Text(
                                                                  'Log Out',
                                                                  style: tt
                                                                      .titleMedium
                                                                      ?.copyWith(
                                                                        color: AppColors
                                                                            .whiteUtility,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                          if (confirm != true) return;

                                          setState(() => _isLoggingOut = true);

                                          await AuthServices.logout();

                                          if (!mounted) return;

                                          context.go('/auth/login');
                                        },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ⬇️ Bottom framing outside sections
                  const SizedBox(height: AppSpacing.xxl),
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
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: tt.titleMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
      ),
      softWrap: true,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route; // ✅ now optional
  final VoidCallback? onTap; // ✅ custom override

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap:
          onTap ??
          (route != null
              ? () => context.push(route!)
              : null), // ✅ safe fallback
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: AppBorders.boxCard(scheme),
          boxShadow: AppShadows.e1(scheme),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: scheme.secondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.bodyMedium, softWrap: true),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: tt.bodySmall,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 24,
              color: scheme.onSurface.withValues(alpha: AppOpacities.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    this.icon,
    this.onTap,
    this.isLoading = false, // ✅ new
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading; // ✅ new

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.accent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ] else if (icon != null) ...[
                  Icon(icon, size: 24, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: tt.titleMedium?.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
