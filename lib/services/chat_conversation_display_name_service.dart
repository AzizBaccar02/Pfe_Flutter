import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only conversation title (nickname) per chat id — shown in list and header.
class ChatConversationDisplayNameService {
  ChatConversationDisplayNameService._();
  static final ChatConversationDisplayNameService instance =
      ChatConversationDisplayNameService._();

  static const _prefsKey = 'chat_conversation_custom_title_v1';

  final Map<int, String> _map = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final e in decoded.entries) {
            final id = int.tryParse(e.key.toString());
            final v = e.value?.toString().trim() ?? '';
            if (id != null && id > 0 && v.isNotEmpty) {
              _map[id] = v;
            }
          }
        }
      } catch (_) {}
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, String>{};
    for (final e in _map.entries) {
      out['${e.key}'] = e.value;
    }
    await prefs.setString(_prefsKey, jsonEncode(out));
  }

  /// Custom title if set; otherwise [serverDefault] (e.g. peer full name).
  String resolve(int chatId, String serverDefault) {
    final c = _map[chatId];
    if (c != null && c.trim().isNotEmpty) return c.trim();
    return serverDefault;
  }

  String? overrideOnly(int chatId) {
    final c = _map[chatId];
    if (c == null || c.trim().isEmpty) return null;
    return c.trim();
  }

  /// Empty or identical to [serverDefault] clears the override.
  Future<void> setOverride(int chatId, String? raw, String serverDefault) async {
    await ensureLoaded();
    final t = raw?.trim() ?? '';
    if (t.isEmpty || t == serverDefault.trim()) {
      _map.remove(chatId);
    } else {
      _map[chatId] = t;
    }
    await _persist();
  }

  Future<void> clearOverride(int chatId) async {
    await ensureLoaded();
    _map.remove(chatId);
    await _persist();
  }
}
