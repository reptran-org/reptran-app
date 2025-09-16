import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:reptran_app/features/auth/presentation/pages/create_new_password_page.dart';
import 'package:reptran_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:reptran_app/features/auth/presentation/pages/login_page.dart';
import 'package:reptran_app/features/auth/presentation/pages/signup_page.dart';
import 'package:reptran_app/features/auth/presentation/pages/verify_otp_page.dart';

class AuthRoutes {
  static const path = '/auth';

  static GoRoute route() => GoRoute(
    path: path,
    redirect: (context, state) {
      // If already logged in, skip auth flow:
      // return '/home';
      return null;
    },
    routes: [
      GoRoute(
        name: 'login',
        path: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'signup',
        path: 'signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignUpPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'forgot-password',
        path: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'create-new-password',
        path: 'create-new-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateNewPasswordPage(),
          transitionsBuilder: _transition,
        ),
      ),
      GoRoute(
        name: 'verify-otp',
        path: 'verify-otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map?;
          final email = extra?['email'] as String?;
          final purpose = extra?['purpose'] as String?; // ✅ pick up purpose too

          return CustomTransitionPage(
            key: state.pageKey,
            child: VerifyOtpPage(
              email: email,
              purpose: purpose, // ✅ forward it to widget
            ),
            transitionsBuilder: _transition,
          );
        },
      ),
    ],
  );

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
    Widget child,
  ) {
    return FadeScaleTransition(animation: animation, child: child);
  }
}
