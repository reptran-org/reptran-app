import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reptran_app/features/auth/services/auth_flow_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:reptran_app/core/services/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reptran_app/core/network/api_client.dart';

class SocialAuthService {
  static final Dio _dio = ApiClient().dio;

  static const _secureStorage = FlutterSecureStorage();

  static Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      // Initialize Google Sign-In with your web client ID

      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);

      // Ensure platform supports authenticate()
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        logger.i('⚠️ This platform needs a custom sign-in UI');
      }

      // Open Google account chooser
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Fetch authentication details
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        logger.i('❌ Missing Google ID Token');
      }

      logger.i('✅ Google Sign-In Success');
      logger.i('ID Token: $idToken');

      // Send token to backend for verification
      final resp = await _dio.post(
        '/auth/social-login',
        data: {'provider': 'google', 'providerToken': idToken},
      );

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await _secureStorage.write(key: 'auth_token', value: token);
        }
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_account', true);

        if (user != null) {
          await prefs.setString('me_user', jsonEncode(user));
        }

        if (context.mounted) {
          await AuthFlowService.decideAndRoute(context);
        }
      } else {
        logger.i('❌ Server error: ${resp.statusCode}');
      }
    } catch (e) {
      logger.i('❌ Google Sign-In error: $e');
    }
  }

  static Future<void> handleFacebookSignIn(BuildContext context) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        logger.i('🚫 Facebook login cancelled by user');
        return;
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        logger.i('❌ Facebook login failed: ${result.status}');
        return;
      }

      final AccessToken accessToken = result.accessToken!;
      final String fbToken = accessToken.tokenString; // ✅ use tokenString

      // Optional: fetch a small profile snapshot
      Map<String, dynamic>? userData;
      try {
        userData =
            await FacebookAuth.instance.getUserData(
                  fields: "id,name,email,picture.width(200)",
                )
                as Map<String, dynamic>?;
        logger.i('✅ Facebook User Data: $userData');
      } catch (e) {
        logger.i('⚠️ Could not fetch Facebook profile snapshot: $e');
      }

      // Send token to backend
      final resp = await _dio.post(
        '/auth/social-login',
        data: {'provider': 'facebook', 'providerToken': fbToken},
      );

      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        final token = data['token'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        if (token != null) {
          await _secureStorage.write(key: 'auth_token', value: token);
        }
        if (refreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_account', true);
        if (user != null) {
          await prefs.setString('me_user', jsonEncode(user));
        }

        if (context.mounted) {
          await AuthFlowService.decideAndRoute(context);
        }
      } else {
        logger.i(
          '❌ Server error during Facebook social-login: ${resp.statusCode}',
        );
      }
    } catch (e) {
      logger.i('❌ Facebook Sign-In error: $e');
    }
  }

  static Future<void> handleTwitterSignIn(BuildContext context) async {
    final twitterLogin = TwitterLogin(
      apiKey: dotenv.env['TWITTER_API_KEY'] ?? '',
      apiSecretKey: dotenv.env['TWITTER_API_SECRET'] ?? '',
      redirectURI: dotenv.env['TWITTER_REDIRECT_URI'] ?? 'reptran://',
    );

    final authResult = await twitterLogin.login();

    switch (authResult.status) {
      case TwitterLoginStatus.loggedIn:
        final token = authResult.authToken;
        final secret = authResult.authTokenSecret;

        if (token == null || secret == null) {
          logger.i('❌ Missing Twitter credentials');
          return;
        }

        logger.i('✅ Twitter login success. Token: $token Secret: $secret');

        try {
          // Send token + secret to backend
          final resp = await _dio.post(
            '/auth/social-login',
            data: {
              'provider': 'twitter',
              'providerToken': token,
              'providerTokenSecret': secret,
            },
          );

          if (resp.statusCode == 200) {
            final data = resp.data as Map<String, dynamic>;
            final jwt = data['token'] as String?;
            final refreshToken = data['refreshToken'] as String?;
            final me = data['user'] as Map<String, dynamic>?;

            if (jwt != null) {
              await _secureStorage.write(key: 'auth_token', value: jwt);
            }
            if (refreshToken != null) {
              await _secureStorage.write(
                key: 'refresh_token',
                value: refreshToken,
              );
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_account', true);

            if (me != null) {
              await prefs.setString('me_user', jsonEncode(me));
            }

            if (context.mounted) {
              await AuthFlowService.decideAndRoute(context);
            }
          } else {
            logger.i('❌ Server error: ${resp.statusCode}');
          }
        } catch (e) {
          logger.i('❌ Twitter login API error: $e');
        }
        break;

      case TwitterLoginStatus.cancelledByUser:
        logger.i('🚫 Twitter login cancelled by user');
        break;

      case TwitterLoginStatus.error:
        logger.i('❌ Twitter login error: ${authResult.errorMessage}');
        break;

      default:
        logger.i('❓ Unknown Twitter login status');
        break;
    }
  }
}
