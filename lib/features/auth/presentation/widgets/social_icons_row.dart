import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reptran_app/core/constants/tokens.dart';

typedef SocialTap = void Function();

class SocialIconsRow extends StatelessWidget {
  final SocialTap? onGoogle;
  final SocialTap? onFacebook;
  final SocialTap? onTwitter;

  const SocialIconsRow({
    super.key,
    this.onGoogle,
    this.onFacebook,
    this.onTwitter,
  });

  Widget _icon(
    String asset,
    SocialTap? onTap,
    BuildContext context, {
    Color? override,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppShadows.e1(scheme),
          color: scheme.surface,
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 24,
            height: 24,
            colorFilter: override != null
                ? ColorFilter.mode(override, BlendMode.srcIn)
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _icon('assets/images/facebook-svg.svg', onFacebook, context),
        const SizedBox(width: AppSpacing.sm),
        _icon('assets/images/google-svg.svg', onGoogle, context),
        const SizedBox(width: AppSpacing.sm),
        _icon(
          'assets/images/twitter-svg.svg',
          onTwitter,
          context,
          override: scheme.brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ],
    );
  }
}
