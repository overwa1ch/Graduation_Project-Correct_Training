import 'exercise_pr_dto.dart';

class PRSummaryDTO {
  final List<ExercisePRDTO> prs;
  final DateTime computedAtUtc;

  PRSummaryDTO({
    required List<ExercisePRDTO> prs,
    required this.computedAtUtc,
  }) : prs = List<ExercisePRDTO>.unmodifiable(prs);

  factory PRSummaryDTO.fromJson(Map<String, dynamic> json) => PRSummaryDTO(
        prs: (json['prs'] as List<dynamic>)
            .map((e) =>
                ExercisePRDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        computedAtUtc: DateTime.parse(json['computedAtUtc'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'prs': prs.map((e) => e.toJson()).toList(),
        'computedAtUtc': computedAtUtc.toUtc().toIso8601String(),
      };
}
