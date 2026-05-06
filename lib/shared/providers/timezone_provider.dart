import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final timezoneProvider = StateNotifierProvider<TimezoneNotifier, Duration>((ref) {
  return TimezoneNotifier();
});

class TimezoneNotifier extends StateNotifier<Duration> {
  TimezoneNotifier() : super(const Duration(hours: -3)) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final offsetHours = prefs.getInt('timezone_offset') ?? -3;
    state = Duration(hours: offsetHours);
  }

  Future<void> setTimezone(int offsetHours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timezone_offset', offsetHours);
    state = Duration(hours: offsetHours);
  }
}
