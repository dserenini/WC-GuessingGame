import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:copa2026/core/constants.dart';

final maxGoalsProvider =
    StateNotifierProvider<MaxGoalsNotifier, int>((ref) {
  return MaxGoalsNotifier();
});

class MaxGoalsNotifier extends StateNotifier<int> {
  MaxGoalsNotifier() : super(kDefaultMaxGoals) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('max_goals') ?? kDefaultMaxGoals;
    state = value;
  }

  Future<void> setMaxGoals(int maxGoals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_goals', maxGoals);
    state = maxGoals;
  }
}
