import 'exercise_dto.dart';
import 'tag_dto.dart';

/// Exercise Catalog 游标分页结果（Catalog/Search V1.1+）。
class ExerciseCatalogPageDTO {
  final List<ExerciseDTO> items;
  final String? nextCursor;

  const ExerciseCatalogPageDTO({
    required this.items,
    this.nextCursor,
  });

  factory ExerciseCatalogPageDTO.fromJson(Map<String, dynamic> json) =>
      ExerciseCatalogPageDTO(
        items: (json['items'] as List<dynamic>)
            .map((e) => ExerciseDTO.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'items': items.map((e) => e.toJson()).toList(),
        'nextCursor': nextCursor,
      };
}

/// Tag Catalog 游标分页结果（Catalog/Search V1.1+）。
class TagCatalogPageDTO {
  final List<TagDTO> items;
  final String? nextCursor;

  const TagCatalogPageDTO({
    required this.items,
    this.nextCursor,
  });

  factory TagCatalogPageDTO.fromJson(Map<String, dynamic> json) =>
      TagCatalogPageDTO(
        items: (json['items'] as List<dynamic>)
            .map((e) => TagDTO.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'items': items.map((e) => e.toJson()).toList(),
        'nextCursor': nextCursor,
      };
}
