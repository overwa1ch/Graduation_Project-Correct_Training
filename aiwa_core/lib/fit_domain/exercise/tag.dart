import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';

class Tag {
  TagId _id;
  String _name;

  Tag({
    required TagId id,
    required String name,
  })  : _id = id,
        _name = name {
    requireNonEmpty(id, 'id');
    requireNonEmpty(name, 'name');
  }

  TagId get id => _id;
  String get name => _name;

  Map<String, dynamic> toJson() => {
        'id': _id,
        'name': _name,
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  void rename(String newName) {
    requireNonEmpty(newName, 'name');
    _name = newName;
  }
}