import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aiwa_core/fit_application/fit_application.dart';

// ---------------------------------------------------------------------------
//  Data model
// ---------------------------------------------------------------------------

/// A single note entry.
class NoteEntry {
  NoteEntry({
    required this.id,
    required this.title,
    required this.blocksJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String title;
  /// JSON-encoded List<BlockDTO> blocks.
  String blocksJson;
  final DateTime createdAt;
  DateTime updatedAt;

  // ---- serialization ----
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'blocksJson': blocksJson,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteEntry.fromJson(Map<String, dynamic> json) => NoteEntry(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        blocksJson: json['blocksJson'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  // ---- helper: extract plain-text preview from blocksJson ----
  String get previewText {
    if (blocksJson.isEmpty) return '';
    try {
      final list = jsonDecode(blocksJson) as List;
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        final dto = BlockDTO.fromJson(map);
        if (dto is TextBlockDTO && dto.text.isNotEmpty) {
          // Strip the internal rich-text JSON format; take raw text if it's plain.
          final raw = dto.text.length > 120 ? dto.text.substring(0, 120) : dto.text;
          return raw;
        }
        if (dto is HeadingBlockDTO && dto.text.isNotEmpty) {
          return dto.text.length > 120 ? dto.text.substring(0, 120) : dto.text;
        }
      }
    } catch (_) {}
    return '';
  }

  // ---- helper: decode to BlockDTO list ----
  List<BlockDTO> get blocks {
    if (blocksJson.isEmpty) return const [];
    try {
      final list = jsonDecode(blocksJson) as List;
      return list
          .map((e) => BlockDTO.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encodeBlocks(List<BlockDTO> blocks) =>
      jsonEncode(blocks.map((b) => b.toJson()).toList());
}

// ---------------------------------------------------------------------------
//  Service
// ---------------------------------------------------------------------------

/// Persists notes in [SharedPreferences] as a JSON list.
/// Call [load()] once at startup, then use [save], [delete], [recent].
class NoteService extends ChangeNotifier {
  static const _key = 'aiwa_notes_v1';

  NoteService();

  List<NoteEntry> _notes = [];

  /// All notes sorted by [updatedAt] descending.
  List<NoteEntry> get notes => _notes;

  /// Returns the [n] most recently updated notes.
  List<NoteEntry> recent(int n) {
    final count = math.min(n, _notes.length);
    return _notes.sublist(0, count);
  }

  // ---- persistence ----

  /// Load notes from SharedPreferences. Call once at app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _notes = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _notes = list
          .map((e) => NoteEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _sortNotes();
    } catch (_) {
      _notes = [];
    }
    notifyListeners();
  }

  /// Save (create or update) a note. Uses [entry.id] as key.
  Future<void> save(NoteEntry entry) async {
    final index = _notes.indexWhere((n) => n.id == entry.id);
    if (index == -1) {
      _notes.add(entry);
    } else {
      _notes[index] = entry;
    }
    _sortNotes();
    notifyListeners();
    await _persist();
  }

  /// Delete the note with the given [id].
  Future<void> delete(String id) async {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _persist();
  }

  // ---- internal ----

  void _sortNotes() {
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static String generateId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final rand = math.Random().nextInt(9999);
    return 'note_${stamp}_$rand';
  }
}
