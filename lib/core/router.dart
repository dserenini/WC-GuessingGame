import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/auth/screens/login_screen.dart';
import 'package:copa2026/features/groups/screens/group_screen.dart';
import 'package:copa2026/features/ranking/screens/ranking_screen.dart';
import 'package:copa2026/features/leagues/screens/leagues_screen.dart';
import 'package:copa2026/features/knockout/screens/knockout_screen.dart';
import 'package:copa2026/features/knockout/screens/knockout_stats_screen.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/shared/providers/phase_provider.dart';
import 'package:copa2026/features/settings/screens/settings_screen.dart';
import 'package:copa2026/features/admin/screens/admin_screen.dart';
import 'package:copa2026/features/profile/screens/profile_screen.dart';
import 'package:copa2026/features/profile/screens/visitor_profile_screen.dart';
import 'package:copa2026/features/profile/screens/advanced_stats_screen.dart';
import 'package:copa2026/features/profile/screens/achievements_screen.dart';
import 'package:copa2026/features/results/screens/results_screen.dart';
import 'package:copa2026/features/results/screens/ko_results_screen.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/features/help/screens/help_screen.dart';
import 'package:copa2026/features/prizes/screens/prizes_screen.dart';
import 'package:copa2026/features/auth/screens/update_password_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // Bloqueia deep-link p/ rotas que são SÓ da fase de grupos quando: a fase é
  // knockout (groupStageVisible == false) OU o usuário não participa dos grupos
  // (groupParticipant == false). Enquanto os providers carregam (valueOrNull ==
  // null), deixa passar para não piscar a tela.
  String? groupOnlyGuard(BuildContext context, GoRouterState state) {
    final visible = ref.read(groupStageVisibleProvider).valueOrNull;
    final participant = ref.read(groupParticipantProvider).valueOrNull;
    if (visible == false || participant == false) return '/profile';
    return null;
  }

  // Resultados (Seleção + Evolução): gated APENAS pela flag de fase de grupos do
  // usuário (groups_unlocked OU admin). Fica disponível em QUALQUER fase do
  // torneio (groups/mixed/knockout) — não depende de groupStageVisible.
  String? groupParticipantGuard(BuildContext context, GoRouterState state) {
    final participant = ref.read(groupParticipantProvider).valueOrNull;
    if (participant == false) return '/profile';
    return null;
  }

  // Bloqueia deep-link p/ rotas exclusivas do mata-mata quando o usuário não
  // tem acesso ao KO (knockoutVisible == false). Enquanto o provider carrega
  // (valueOrNull == null), deixa passar para não piscar a tela.
  String? knockoutGuard(BuildContext context, GoRouterState state) {
    final visible = ref.read(knockoutVisibleProvider).valueOrNull;
    if (visible == false) return '/profile';
    return null;
  }

  return GoRouter(
    initialLocation: '/profile',
    redirect: (context, state) {
      final authStateValue = authState.valueOrNull;
      final session = authStateValue?.session;
      final authEvent = authStateValue?.event;
      final isLoggedIn = session != null;

      final isLoginPage = state.matchedLocation == '/login';
      final isUpdatePassword = state.matchedLocation == '/update-password';

      if (authEvent == AuthChangeEvent.passwordRecovery && !isUpdatePassword) {
        return '/update-password';
      }

      if (!isLoggedIn && !isLoginPage && !isUpdatePassword) return '/login';

      // O onboarding (idioma + nome + telefone) agora é uma etapa da própria
      // tela de Perfil, decidida pelos dados da conta (ver ProfileScreen).
      if (isLoggedIn && authEvent != AuthChangeEvent.passwordRecovery) {
        if (isLoginPage || isUpdatePassword) return '/profile';
      }

      return null;
    },
    routes: [
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
        redirect: groupOnlyGuard,
      ),
      GoRoute(
        path: '/ranking',
        name: 'ranking',
        builder: (_, __) => const RankingScreen(),
      ),
      GoRoute(
        path: '/stats',
        name: 'advanced-stats',
        builder: (_, state) {
          final tab = state.extra is int ? state.extra as int : 0;
          return AdvancedStatsScreen(initialTab: tab);
        },
        redirect: groupOnlyGuard,
      ),
      GoRoute(
        path: '/achievements',
        name: 'achievements',
        builder: (_, __) => const AchievementsScreen(),
        redirect: groupOnlyGuard,
      ),
      GoRoute(
        path: '/results',
        name: 'results',
        builder: (_, __) => const ResultsScreen(),
        redirect: groupParticipantGuard,
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
        path: '/knockout',
        name: 'knockout',
        builder: (_, __) => const KnockoutScreen(),
        redirect: (context, state) {
          // Bloqueia deep-link de quem não tem acesso. Enquanto o provider
          // ainda carrega (valueOrNull == null), deixa passar — a própria
          // KnockoutScreen mostra o aviso de bloqueio.
          final visible = ref.read(knockoutVisibleProvider).valueOrNull;
          if (visible == false) return '/profile';
          return null;
        },
      ),
      GoRoute(
        path: '/knockout-stats',
        name: 'knockout-stats',
        builder: (_, __) => const KnockoutStatsScreen(),
        redirect: (context, state) {
          // Mesmo gating do /knockout: só inscritos veem as estatísticas do KO.
          final visible = ref.read(knockoutVisibleProvider).valueOrNull;
          if (visible == false) return '/profile';
          return null;
        },
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
      GoRoute(
        path: '/prizes',
        name: 'prizes',
        builder: (_, __) => const PrizesScreen(),
        redirect: groupOnlyGuard,
      ),
      GoRoute(
        path: '/ko-prizes',
        name: 'ko-prizes',
        builder: (_, __) => const PrizesScreen(knockout: true),
        redirect: knockoutGuard,
      ),
      GoRoute(
        path: '/ko-results',
        name: 'ko-results',
        builder: (_, __) => const KoResultsScreen(),
        redirect: knockoutGuard,
      ),
    ],
  );
});
