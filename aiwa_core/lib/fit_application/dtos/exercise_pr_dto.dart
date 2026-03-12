import 'package:aiwa_core/fit_domain/fit_domain.dart';

class ExercisePRDTO {
  final ExerciseId exerciseId;
  final double prWeightKg;
  final DateOnly achievedOnDate;
  final LogId achievedInLogId;

  const ExercisePRDTO({
    required this.exerciseId,
    required this.prWeightKg,
    required this.achievedOnDate,
    required this.achievedInLogId,
  });

  factory ExercisePRDTO.fromJson(Map<String, dynamic> json) => ExercisePRDTO(
        exerciseId: json['exerciseId'] as String,
        prWeightKg: (json['prWeightKg'] as num).toDouble(),
        achievedOnDate: DateOnly.parse(json['achievedOnDate'] as String),
        achievedInLogId: json['achievedInLogId'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exerciseId': exerciseId,
        'prWeightKg': prWeightKg,
        'achievedOnDate': achievedOnDate.toString(),
        'achievedInLogId': achievedInLogId,
      };
}
