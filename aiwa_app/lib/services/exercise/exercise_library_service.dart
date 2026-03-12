import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrRecord {
  const PrRecord({
    required this.date,
    required this.value,
  });

  final DateTime date;
  final double value;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date.toIso8601String(),
        'value': value,
      };

  factory PrRecord.fromJson(Map<String, dynamic> json) => PrRecord(
        date: DateTime.parse(json['date'] as String),
        value: (json['value'] as num?)?.toDouble() ?? 0,
      );
}

class ExerciseTemplateActionConfig {
  const ExerciseTemplateActionConfig({
    required this.exerciseId,
    required this.targetWeightKg,
    required this.startingWeightKg,
    required this.endingWeightKg,
    required this.incrementWeightKg,
  });

  final String exerciseId;
  final double targetWeightKg;
  final double startingWeightKg;
  final double endingWeightKg;
  final double incrementWeightKg;

  factory ExerciseTemplateActionConfig.defaultsFor(ExerciseEntry entry) {
    final target = normalizeExerciseWeight(
      deriveTargetWeightFromRecords(entry.records),
    );
    return ExerciseTemplateActionConfig(
      exerciseId: entry.id,
      targetWeightKg: target,
      startingWeightKg: defaultStartingWeight(target),
      endingWeightKg: defaultEndingWeight(target),
      incrementWeightKg: 2.5,
    );
  }

  ExerciseTemplateActionConfig copyWith({
    String? exerciseId,
    double? targetWeightKg,
    double? startingWeightKg,
    double? endingWeightKg,
    double? incrementWeightKg,
  }) {
    return ExerciseTemplateActionConfig(
      exerciseId: exerciseId ?? this.exerciseId,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      startingWeightKg: startingWeightKg ?? this.startingWeightKg,
      endingWeightKg: endingWeightKg ?? this.endingWeightKg,
      incrementWeightKg: incrementWeightKg ?? this.incrementWeightKg,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exerciseId': exerciseId,
        'targetWeightKg': targetWeightKg,
        'startingWeightKg': startingWeightKg,
        'endingWeightKg': endingWeightKg,
        'incrementWeightKg': incrementWeightKg,
      };

  factory ExerciseTemplateActionConfig.fromJson(Map<String, dynamic> json) {
    final target = normalizeExerciseWeight(
      (json['targetWeightKg'] as num?)?.toDouble() ?? 0,
    );
    final starting = normalizeExerciseWeight(
      (json['startingWeightKg'] as num?)?.toDouble() ??
          defaultStartingWeight(target),
    );
    final ending = normalizeExerciseWeight(
      (json['endingWeightKg'] as num?)?.toDouble() ??
          defaultEndingWeight(target),
    );
    final increment = normalizeExerciseWeight(
      (json['incrementWeightKg'] as num?)?.toDouble() ?? 2.5,
    );
    return ExerciseTemplateActionConfig(
      exerciseId: json['exerciseId'] as String? ?? '',
      targetWeightKg: target,
      startingWeightKg: starting,
      endingWeightKg: ending,
      incrementWeightKg: increment <= 0 ? 2.5 : increment,
    );
  }
}

class ExerciseEntry {
  const ExerciseEntry({
    required this.id,
    required this.name,
    this.tagIds = const <String>[],
    this.records = const <PrRecord>[],
    this.notes = '',
    this.templateActionConfigs = const <ExerciseTemplateActionConfig>[],
  });

  final String id;
  final String name;
  final List<String> tagIds;
  final List<PrRecord> records;
  final String notes;
  final List<ExerciseTemplateActionConfig> templateActionConfigs;

  ExerciseEntry copyWith({
    String? id,
    String? name,
    List<String>? tagIds,
    List<PrRecord>? records,
    String? notes,
    List<ExerciseTemplateActionConfig>? templateActionConfigs,
  }) {
    return ExerciseEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      tagIds: tagIds ?? this.tagIds,
      records: records ?? this.records,
      notes: notes ?? this.notes,
      templateActionConfigs:
          templateActionConfigs ?? this.templateActionConfigs,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'tagIds': tagIds,
        'records': records.map((record) => record.toJson()).toList(),
        'notes': notes,
        'templateActionConfigs':
            templateActionConfigs.map((config) => config.toJson()).toList(),
      };

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) => ExerciseEntry(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        tagIds: (json['tagIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .toList(growable: false),
        records: (json['records'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((item) => PrRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        notes: json['notes'] as String? ?? '',
        templateActionConfigs:
            (json['templateActionConfigs'] as List<dynamic>? ??
                    const <dynamic>[])
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (item) => ExerciseTemplateActionConfig.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false),
      );
}

class ExerciseLibraryService extends ChangeNotifier {
  ExerciseLibraryService();

  static const String _key = 'aiwa_exercise_library_v1';

  List<ExerciseEntry> _entries = <ExerciseEntry>[];
  List<String> _allTags = <String>[];

  List<ExerciseEntry> get entries => List<ExerciseEntry>.unmodifiable(_entries);
  List<String> get allTags => List<String>.unmodifiable(_allTags);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      _entries = <ExerciseEntry>[];
      _allTags = <String>[];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _entries = (decoded['entries'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((item) =>
                ExerciseEntry.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: true);
        _allTags = _normalizeTags(
          (decoded['allTags'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(growable: false),
        );
      } else if (decoded is List) {
        _entries = decoded
            .whereType<Map<dynamic, dynamic>>()
            .map((item) =>
                ExerciseEntry.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: true);
        _allTags = _collectTags(_entries);
      } else {
        _entries = <ExerciseEntry>[];
        _allTags = <String>[];
      }
    } catch (_) {
      _entries = <ExerciseEntry>[];
      _allTags = <String>[];
    }
    notifyListeners();
  }

  ExerciseEntry? findById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  Future<void> save(ExerciseEntry entry) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    final normalized = entry.copyWith(
      name: entry.name.trim(),
      tagIds: _normalizeTags(entry.tagIds),
    );
    if (index == -1) {
      _entries.add(normalized);
    } else {
      _entries[index] = normalized;
    }
    _allTags = _normalizeTags(<String>[
      ..._allTags,
      ...normalized.tagIds,
    ]);
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _entries.removeWhere((item) => item.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> updateEntryTags({
    required String entryId,
    required List<String> activeTags,
    required List<String> allTags,
  }) async {
    final index = _entries.indexWhere((item) => item.id == entryId);
    if (index == -1) {
      return;
    }
    _entries[index] = _entries[index].copyWith(
      tagIds: _normalizeTags(activeTags),
    );
    _allTags = _normalizeTags(allTags);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(<String, dynamic>{
      'entries': _entries.map((entry) => entry.toJson()).toList(),
      'allTags': _allTags,
    });
    await prefs.setString(_key, payload);
  }

  List<String> _collectTags(Iterable<ExerciseEntry> entries) {
    final tags = <String>[];
    for (final entry in entries) {
      tags.addAll(entry.tagIds);
    }
    return _normalizeTags(tags);
  }

  List<String> _normalizeTags(List<String> source) {
    final seen = <String>{};
    final values = <String>[];
    for (final raw in source) {
      final tag = raw.trim();
      if (tag.isEmpty) {
        continue;
      }
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        values.add(tag);
      }
    }
    return values;
  }

  static String generateId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = math.Random().nextInt(9999);
    return 'ex_${stamp}_$suffix';
  }
}

const String exerciseLibraryLinkScheme = 'aiwa-exercise';

Uri buildExerciseLibraryLinkUri(String exerciseId) {
  return Uri(
    scheme: exerciseLibraryLinkScheme,
    host: 'entry',
    pathSegments: <String>[exerciseId],
  );
}

String? parseExerciseLibraryLinkId(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) {
    return null;
  }
  if (uri.scheme != exerciseLibraryLinkScheme || uri.host != 'entry') {
    return null;
  }
  if (uri.pathSegments.isEmpty) {
    return null;
  }
  return uri.pathSegments.first.trim().isEmpty ? null : uri.pathSegments.first;
}

double deriveTargetWeightFromRecords(Iterable<PrRecord> records) {
  var target = 0.0;
  for (final record in records) {
    if (record.value > target) {
      target = record.value;
    }
  }
  return target;
}

double defaultStartingWeight(double targetWeightKg) {
  return normalizeExerciseWeight(targetWeightKg * 0.65);
}

double defaultEndingWeight(double targetWeightKg) {
  return normalizeExerciseWeight(targetWeightKg * 0.95);
}

double normalizeExerciseWeight(double value) {
  return double.parse(value.toStringAsFixed(1));
}

List<double> buildWeightProgression({
  required double startWeightKg,
  required double endWeightKg,
  required double incrementWeightKg,
}) {
  final start = normalizeExerciseWeight(startWeightKg);
  final end = normalizeExerciseWeight(endWeightKg);
  final step = normalizeExerciseWeight(incrementWeightKg.abs());
  if (start <= 0 || end <= 0 || step <= 0 || start > end) {
    return const <double>[];
  }

  final values = <double>[];
  var current = start;
  while (current <= end + 0.0001 && values.length < 200) {
    values.add(normalizeExerciseWeight(current));
    current = normalizeExerciseWeight(current + step);
  }

  if (values.isEmpty) {
    return <double>[end];
  }
  if ((values.last - end).abs() > 0.0001) {
    values.add(end);
  }
  return values;
}
