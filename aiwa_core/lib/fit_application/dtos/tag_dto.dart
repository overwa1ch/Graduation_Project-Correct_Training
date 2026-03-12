class TagDTO {
  final String id;
  final String name;

  const TagDTO({
    required this.id,
    required this.name,
  });

  factory TagDTO.fromJson(Map<String, dynamic> json) => TagDTO(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
      };
}
