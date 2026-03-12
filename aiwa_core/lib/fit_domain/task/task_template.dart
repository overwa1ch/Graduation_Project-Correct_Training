import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';

class TaskTemplate {
  TaskTemplateId _id;
  String _title;
  String? _description;

  TaskTemplate({
    required TaskTemplateId id,
    required String title,
    String? description,
  })  : _id = id,
        _title = title,
        _description = description {
    requireNonEmpty(id, 'id');
    requireNonEmpty(title, 'title');
  }

  TaskTemplateId get id => _id;
  String get title => _title;
  String? get description => _description;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': _id,
        'title': _title,
        'description': _description,
      };

  factory TaskTemplate.fromJson(Map<String, dynamic> json) => TaskTemplate(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
      );

  void updateTitle(String title) {
    requireNonEmpty(title, 'title');
    _title = title;
  }

  void updateDescription(String? description) {
    _description = description;
  }
}
