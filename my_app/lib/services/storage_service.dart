import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_session.dart';

class StorageService {
  static const String _key = 'class_sessions';

  Future<List<ClassSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => ClassSession.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveSession(ClassSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_key, raw);
  }

  /// Replace an existing session (matched by id) with an updated version.
  Future<void> updateSession(ClassSession updated) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final newList = raw.map((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == updated.id
          ? jsonEncode(updated.toJson())
          : s;
    }).toList();
    await prefs.setStringList(_key, newList);
  }

  Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return m['id'] == id;
    });
    await prefs.setStringList(_key, raw);
  }
}
