import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileStats {
  final String username;
  final String? avatarUrl;
  final String email;
  final int totalBets;
  final int totalMatches;
  final int totalPoints;
  final int exactHits;   // points == 3 (acerto no placar)
  final int resultHits;  // points == 1 (acerto no resultado)

  const ProfileStats({
    required this.username,
    this.avatarUrl,
    required this.email,
    required this.totalBets,
    required this.totalMatches,
    required this.totalPoints,
    required this.exactHits,
    required this.resultHits,
  });
}

final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('Usuário não autenticado');
  }

  // Fetch profile
  final profileData = await client
      .from('profiles')
      .select('username, avatar_url')
      .eq('id', user.id)
      .single();

  // Fetch all bets for this user
  final betsData = await client
      .from('bets')
      .select('points')
      .eq('user_id', user.id);

  // Fetch total match count
  final matchesData = await client
      .from('matches')
      .select('id');

  final bets = betsData as List;
  final totalBets = bets.length;
  final totalMatches = (matchesData as List).length;

  int totalPoints = 0;
  int exactHits = 0;
  int resultHits = 0;

  for (final bet in bets) {
    final pts = (bet['points'] as num?)?.toInt() ?? 0;
    totalPoints += pts;
    if (pts == 3) exactHits++;
    if (pts == 1) resultHits++;
  }

  return ProfileStats(
    username: profileData['username'] as String? ?? '',
    avatarUrl: profileData['avatar_url'] as String?,
    email: user.email ?? '',
    totalBets: totalBets,
    totalMatches: totalMatches,
    totalPoints: totalPoints,
    exactHits: exactHits,
    resultHits: resultHits,
  );
});
