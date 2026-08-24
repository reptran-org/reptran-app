import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ------------------------------
/// Models for payload
/// ------------------------------

class SessionRewardsPayload {
  final String sessionId;

  /// total points earned in this session (can be 0)
  final int pointsDelta;

  /// optional badge earned in this session
  final RewardBadge? badge;

  const SessionRewardsPayload({
    required this.sessionId,
    required this.pointsDelta,
    required this.badge,
  });

  bool get hasPoints => pointsDelta > 0;
  bool get hasBadge => badge != null;
}

class RewardBadge {
  final String key;
  final String title;
  final String description;
  final String? iconUrl;

  const RewardBadge({
    required this.key,
    required this.title,
    required this.description,
    required this.iconUrl,
  });
}

/// ------------------------------
/// Overlay Widget
/// ------------------------------

class RewardOverlay extends StatefulWidget {
  const RewardOverlay({
    super.key,
    required this.payload,
    this.onViewSummary,
    this.onBackHome,
  });

  final SessionRewardsPayload payload;

  /// optional callbacks so you can route properly later
  final VoidCallback? onViewSummary;
  final VoidCallback? onBackHome;

  @override
  State<RewardOverlay> createState() => _RewardOverlayState();
}

class _RewardOverlayState extends State<RewardOverlay>
    with TickerProviderStateMixin {
  // staged visibility
  bool badgeVisible = false;
  bool textVisible = false;
  bool showButtons = false;

  // animations/controllers
  late final AnimationController _overlayCtrl;
  late final AnimationController _badgeCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pointsCtrl;
  late final AnimationController _particlesCtrl;

  // points count-up
  int pointsValue = 0;

  // Particle config
  final int particleCount = 40;
  late List<_Particle> _particles;
  final Random _rnd = Random();

  // RepTran palette (your existing vibe)
  static const Color bgDark = Color(0xFF1E1E1E);
  static const Color primaryDeep = Color(0xFF0F6F6E);
  static const Color accent = Color(0xFF38BFB2);
  static const Color successGreen = Color(0xFF4CD964);
  static const Color textSoft = Color(0xFFF8F9FA);

  final List<Color> particleColors = const [
    primaryDeep,
    accent,
    Color(0xFFFF6B5A),
    successGreen,
  ];

  bool get _hasBadge => widget.payload.badge != null;
  bool get _hasPoints => widget.payload.pointsDelta > 0;

  Color get _badgeColor => accent;
  bool showShimmer = true;

  String get _titleText {
    if (_hasBadge) return "Reward Unlocked 🎉";
    if (_hasPoints) return "Session Complete 💪";
    return "Workout Complete ✅";
  }

  String get _subtitleText {
    if (_hasBadge) return widget.payload.badge!.title;
    return "Consistency reinforced";
  }

  String get _supportingText {
    if (_hasBadge) return widget.payload.badge!.description;
    if (_hasPoints) return "You showed up — that matters.";
    return "You completed the session. Realignment is success.";
  }

  bool get _showBadgeSection => _hasBadge;
  bool get _showPointsPill => _hasPoints;

  bool get _showSeeAllRewardsButton {
    // If nothing earned, keep it minimal: only View Summary
    return _hasPoints || _hasBadge;
  }

  @override
  void initState() {
    super.initState();

    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _shimmerCtrl.stop();
      setState(() => showShimmer = false);
    });

    _pointsCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addListener(() {
          final target = widget.payload.pointsDelta;
          setState(() {
            pointsValue = (target * Curves.easeOut.transform(_pointsCtrl.value))
                .floor();
          });
        });

    _particlesCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // particles radial burst
    _particles = List.generate(particleCount, (i) {
      final angle = (2 * pi * i) / particleCount;
      final velocity = 150 + _rnd.nextDouble() * 100;
      final color = particleColors[_rnd.nextInt(particleColors.length)];
      final size = 4 + _rnd.nextDouble() * 8;
      final delay = i * 0.02;
      final dur = 1.5 + _rnd.nextDouble() * 0.5;

      return _Particle(
        angle: angle,
        distance: velocity,
        color: color,
        size: size,
        startMs: (delay * 1000).round(),
        durMs: (dur * 1000).round(),
      );
    });

    // staged sequence
    Future.delayed(const Duration(milliseconds: 80), () {
      _overlayCtrl.forward();
    });

    // badge only if it exists
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      if (_showBadgeSection) {
        setState(() => badgeVisible = true);
        _badgeCtrl.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      setState(() => textVisible = true);
      _textCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 820), () {
      if (!mounted) return;

      if (_hasPoints) {
        _pointsCtrl.forward(from: 0);
      }

      // particles only if something happened (points or badge)
      if (_hasPoints || _hasBadge) {
        _particlesCtrl.forward(from: 0);
      }
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => showButtons = true);
    });
  }

  @override
  void dispose() {
    _overlayCtrl.dispose();
    _badgeCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    _pointsCtrl.dispose();
    _particlesCtrl.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _handleViewSummary() {
    if (widget.onViewSummary != null) {
      widget.onViewSummary!.call();
      return;
    }
    _close();
  }

  void _handleBackHome() {
    if (widget.onBackHome != null) {
      widget.onBackHome!.call();
      return;
    }
    _close();
  }

  Widget _buildBadgeContent() {
    final badge = widget.payload.badge;
    if (badge == null) return const SizedBox.shrink();

    // If iconUrl exists, show it. Else fallback to icon.
    if (badge.iconUrl != null && badge.iconUrl!.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          badge.iconUrl!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Icon(
              PhosphorIconsRegular.medal,
              size: 64,
              color: _badgeColor,
            );
          },
        ),
      );
    }

    return Icon(PhosphorIconsRegular.medal, size: 64, color: _badgeColor);
  }

  @override
  Widget build(BuildContext context) {
    final overlayOpacity = CurvedAnimation(
      parent: _overlayCtrl,
      curve: Curves.easeOut,
    );

    final badgeSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut));

    final badgeScale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut));

    final textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    final glowT = Tween<double>(
      begin: 0.4,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    final shimmerT = CurvedAnimation(
      parent: _shimmerCtrl,
      curve: Curves.linear,
    );

    return FadeTransition(
      opacity: overlayOpacity,
      child: Stack(
        children: [
          // dim backdrop
          Positioned.fill(
            child: Opacity(opacity: 0.85, child: Container(color: bgDark)),
          ),
          // blur backdrop
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // particles (only visual)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particlesCtrl,
                builder: (_, __) => Stack(
                  children: _particles.map((p) {
                    final tGlobal = _particlesCtrl.value;
                    final ms =
                        (tGlobal *
                        _particlesCtrl.duration!.inMilliseconds.toDouble());
                    final localT = ((ms - p.startMs) / p.durMs).clamp(0.0, 1.0);

                    if (localT <= 0 || localT >= 1) {
                      return const SizedBox.shrink();
                    }

                    final eased = Curves.easeOut.transform(localT);
                    final dx = cos(p.angle) * p.distance * eased;
                    final dy = sin(p.angle) * p.distance * eased;
                    final scale = (1 - eased).clamp(0.0, 1.0);
                    final opacity = (1 - eased).clamp(0.0, 1.0);

                    return Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(dx, dy),
                        child: Align(
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                color: p.color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: p.color.withOpacity(0.35),
                                    blurRadius: 12 * scale,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // main content
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge section (only if badge exists)
                    if (_showBadgeSection)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _badgeCtrl,
                          _glowCtrl,
                          _shimmerCtrl,
                        ]),
                        builder: (_, __) {
                          return Opacity(
                            opacity: badgeVisible ? 1 : 0,
                            child: SlideTransition(
                              position: badgeSlide,
                              child: Transform.scale(
                                scale: badgeScale.value,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    // glow ring
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _badgeColor.withOpacity(
                                              glowT.value,
                                            ),
                                            blurRadius: 40 + 20 * glowT.value,
                                            spreadRadius: 8,
                                          ),
                                          BoxShadow(
                                            color: _badgeColor.withOpacity(
                                              glowT.value * 0.5,
                                            ),
                                            blurRadius: 80 + 40 * glowT.value,
                                            spreadRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // badge surface
                                    Container(
                                      width: 128,
                                      height: 128,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _badgeColor,
                                          width: 4,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _buildBadgeContent(),
                                    ),

                                    // shimmer sweep
                                    if (showShimmer)
                                      ClipOval(
                                        child: SizedBox(
                                          width: 128,
                                          height: 128,
                                          child: AnimatedBuilder(
                                            animation: shimmerT,
                                            builder: (_, __) {
                                              final x = _lerpDouble(
                                                -1,
                                                1,
                                                shimmerT.value,
                                              )!;
                                              return FractionalTranslation(
                                                translation: Offset(x, 0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin:
                                                          Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.white
                                                            .withOpacity(0.75),
                                                        Colors.transparent,
                                                      ],
                                                      stops: const [
                                                        0.45,
                                                        0.5,
                                                        0.55,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    if (_showBadgeSection) const SizedBox(height: 28),

                    // Text block (always)
                    FadeTransition(
                      opacity: textFade,
                      child: Column(
                        children: [
                          Text(
                            _titleText,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

                          // subtitle (badge title or "Consistency reinforced")
                          Text(
                            _subtitleText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _badgeColor,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 14),

                          // points pill (only if points > 0)
                          if (_showPointsPill)
                            AnimatedScale(
                              duration: const Duration(milliseconds: 250),
                              scale:
                                  (_pointsCtrl.isAnimating ||
                                      _pointsCtrl.isCompleted)
                                  ? 1
                                  : 0.95,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryDeep,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "+$pointsValue",
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: successGreen,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "points",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // supportive message
                          Text(
                            _supportingText,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.3,
                              color: textSoft,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Buttons
                    AnimatedOpacity(
                      opacity: showButtons ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        children: [
                          _HoverButton(
                            bg: primaryDeep,
                            bgHover: const Color(0xFF0D5E5D),
                            fg: Colors.white,
                            shadow: primaryDeep,
                            label: "View Summary",
                            icon: PhosphorIconsRegular.chartLineUp,
                            onPressed: _handleViewSummary,
                          ),
                          const SizedBox(height: 12),

                          _OutlineHoverButton(
                            label: "Back Home",
                            color: accent,
                            borderBase: accent.withOpacity(0.30),
                            borderHover: accent,
                            onPressed: _handleBackHome,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------
/// Particles
/// ------------------------------

class _Particle {
  final double angle;
  final double distance;
  final Color color;
  final double size;
  final int startMs;
  final int durMs;

  const _Particle({
    required this.angle,
    required this.distance,
    required this.color,
    required this.size,
    required this.startMs,
    required this.durMs,
  });
}

/// ------------------------------
/// Buttons (same as yours)
/// ------------------------------

class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.bg,
    required this.bgHover,
    required this.fg,
    required this.shadow,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color bg;
  final Color bgHover;
  final Color fg;
  final Color shadow;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : (_hover ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scale, scale),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _hover ? widget.bgHover : widget.bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.shadow.withOpacity(_hover ? 0.40 : 0.30),
                blurRadius: _hover ? 20 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 24, color: widget.fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineHoverButton extends StatefulWidget {
  const _OutlineHoverButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.borderBase,
    required this.borderHover,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color borderBase;
  final Color borderHover;

  @override
  State<_OutlineHoverButton> createState() => _OutlineHoverButtonState();
}

class _OutlineHoverButtonState extends State<_OutlineHoverButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.98 : (_hover ? 1.01 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scale, scale),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _hover ? widget.color.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hover ? widget.borderHover : widget.borderBase,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIconsRegular.sealCheck,
                size: 24,
                color: widget.color,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper for lerp double without importing dart:ui's lerpDouble
double? _lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a * (1.0 - t) + b * t;
}
