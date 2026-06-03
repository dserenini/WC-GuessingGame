import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileStats {
  final String username;
  final String? fullName;
  final String displayPreference;
  final String? avatarUrl;
  final String email;
  final int totalBets;
  final int totalMatches;
  final int totalPoints;
  final int exactHits;   // points == 3 (acerto no placar)
  final int resultHits;  // points == 1 (acerto no resultado)
  final int superPalpitesUsed;

  const ProfileStats({
    required this.username,
    this.fullName,
    required this.displayPreference,
    this.avatarUrl,
    required this.email,
    required this.totalBets,
    required this.totalMatches,
    required this.totalPoints,
    required this.exactHits,
    required this.resultHits,
    required this.superPalpitesUsed,
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
      .select('username, full_name, display_preference, avatar_url, super_palpites_used')
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
    fullName: profileData['full_name'] as String?,
    displayPreference: profileData['display_preference'] as String? ?? 'username',
    avatarUrl: profileData['avatar_url'] as String?,
    email: user.email ?? '',
    totalBets: totalBets,
    totalMatches: totalMatches,
    totalPoints: totalPoints,
    exactHits: exactHits,
    resultHits: resultHits,
    superPalpitesUsed: (profileData['super_palpites_used'] as num?)?.toInt() ?? 0,
  );
});
