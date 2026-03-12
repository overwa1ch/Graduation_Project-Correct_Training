import 'dart:collection';

import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';

class Exercise {
  ExerciseId _id;
  String _name;
  final List<TagId> _tagIds;
  bool _deprecated;

  Exercise({
    required ExerciseId id,
    required String name,
    List<TagId>? tagIds,
    bool deprecated = false,
  })  : _id = id,
        _name = name,
        _tagIds = List<TagId>.from(tagIds ?? <TagId>[]),
        _deprecated = deprecated {
    requireNonEmpty(id, 'id');
    requireNonEmpty(name, 'name');
    _dedupeTags();
  }

  ExerciseId get id => _id;
  String get name => _name;
  UnmodifiableListView<TagId> get tagIds =>
      UnmodifiableListView<TagId>(_tagIds);
  bool get deprecated => _deprecated;

  Map<String, dynamic> toJson() => {
        'id': _id,
        'name': _name,
        'tagIds': List<String>.from(_tagIds),
        'deprecated': _deprecated,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        tagIds: (json['tagIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            <TagId>[],
        deprecated: json['deprecated'] as bool? ?? false,
      );

  void rename(String newName) {
    requireNonEmpty(newName, 'name');
    _name = newName;
  }

  void setDeprecated(bool value) {
    _deprecated = value;
  }

  void replaceTags(List<TagId> tagIds) {
    for (final tagId in tagIds) {
      requireNonEmpty(tagId, 'tagId');
    }
    _tagIds
      ..clear()
      ..addAll(tagIds);
    _dedupeTags();
  }

  void addTag(TagId tagId) {
    requireNonEmpty(tagId, 'tagId');
    if (!_tagIds.contains(tagId)) {
      _tagIds.add(tagId);
    }
  }

  void removeTag(TagId tagId) {
    requireNonEmpty(tagId, 'tagId');
    _tagIds.removeWhere((t) => t == tagId);
  }

  void _dedupeTags() {
    final seen = <TagId>{};
    _tagIds.retainWhere((tagId) => seen.add(tagId));
  }
}