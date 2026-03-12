class ExerciseDTO {
  final String id;
  final String name;
  final List<String> tagIds;
  final bool deprecated;

  ExerciseDTO({
    required this.id,
    required this.name,
    required List<String> tagIds,
    required this.deprecated,
  }) : tagIds = List<String>.unmodifiable(tagIds);

  factory ExerciseDTO.fromJson(Map<String, dynamic> json) => ExerciseDTO(
        id: json['id'] as String,
        name: json['name'] as String,
        tagIds:
            (json['tagIds'] as List<dynamic>).map((e) => e as String).toList(),
        deprecated: json['deprecated'] as bool,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'tagIds': tagIds,
        'deprecated': deprecated,
      };
}
