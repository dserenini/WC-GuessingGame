import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/auth/screens/login_screen.dart';
import 'package:copa2026/features/groups/screens/group_screen.dart';
import 'package:copa2026/features/ranking/screens/ranking_screen.dart';
import 'package:copa2026/features/leagues/screens/leagues_screen.dart';
import 'package:copa2026/features/settings/screens/settings_screen.dart';
import 'package:copa2026/features/admin/screens/admin_screen.dart';
import 'package:copa2026/features/profile/screens/profile_screen.dart';
import 'package:copa2026/features/profile/screens/visitor_profile_screen.dart';
import 'package:copa2026/features/profile/screens/advanced_stats_screen.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/features/auth/screens/onboarding_screen.dart';
import 'package:copa2026/features/help/screens/help_screen.dart';
import 'package:copa2026/features/auth/screens/update_password_screen.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final localeNotifier = ref.watch(localeProvider.notifier);

  return GoRouter(
    initialLocation: '/profile',
    redirect: (context, state) {
      final authStateValue = authState.valueOrNull;
      final session = authStateValue?.session;
      final authEvent = authStateValue?.event;
      final isLoggedIn = session != null;
      
      final isLoginPage = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isUpdatePassword = state.matchedLocation == '/update-password';
      final hasSelectedLanguage = localeNotifier.hasSelectedLanguage;

      if (authEvent == AuthChangeEvent.passwordRecovery && !isUpdatePassword) {
        return '/update-password';
      }

      if (!isLoggedIn && !isLoginPage && !isUpdatePassword) return '/login';
      
      if (isLoggedIn && authEvent != AuthChangeEvent.passwordRecovery) {
        if (!hasSelectedLanguage && !isOnboarding && !isUpdatePassword) return '/onboarding';
        if (hasSelectedLanguage && (isLoginPage || isOnboarding || isUpdatePassword)) return '/profile';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/update-password',
        name: 'update-password',
        builder: (_, __) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/groups/:group',
        name: 'group',
        builder: (_, state) {
          final group = state.pathParameters['group'] ?? 'A';
          return GroupScreen(groupLetter: group);
        },
      ),
      GoRoute(
        path: '/ranking',
        name: 'ranking',
        builder: (_, __) => const RankingScreen(),
      ),
      GoRoute(
        path: '/stats',
        name: 'advanced-stats',
        builder: (_, __) => const AdvancedStatsScreen(),
      ),
      GoRoute(
        path: '/user/:userId',
        name: 'visitor-profile',
        builder: (_, state) {
          final userId = state.pathParameters['userId'] ?? '';
          final entry = state.extra is RankingEntry ? state.extra as RankingEntry : null;
          return VisitorProfileScreen(userId: userId, entry: entry);
        },
      ),
      GoRoute(
        path: '/leagues',
        name: 'leagues',
        builder: (_, __) => const LeaguesScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminScreen(),
        redirect: (context, state) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null || !kAdminUids.contains(user.id)) {
            return '/groups/A';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (_, __) => const HelpScreen(),
      ),
    ],
  );
});
