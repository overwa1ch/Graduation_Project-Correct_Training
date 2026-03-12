/// 最小 Milestone DTO（供 UI 消费，不泄漏 Domain 对象）。
class MilestoneDTO {
  final String id;
  final String type;
  final String exerciseId;
  final String logId;
  final double metricValue;
  final String dedupKey;
  final String createdAtUtc; // ISO-8601 UTC string
  final String? deletedAtUtc; // ISO-8601 UTC string or null

  const MilestoneDTO({
    required this.id,
    required this.type,
    required this.exerciseId,
    required this.logId,
    required this.metricValue,
    required this.dedupKey,
    required this.createdAtUtc,
    this.deletedAtUtc,
  });

  factory MilestoneDTO.fromJson(Map<String, dynamic> json) => MilestoneDTO(
        id: json['id'] as String,
        type: json['type'] as String,
        exerciseId: json['exerciseId'] as String,
        logId: json['logId'] as String,
        metricValue: (json['metricValue'] as num).toDouble(),
        dedupKey: json['dedupKey'] as String,
        createdAtUtc: json['createdAtUtc'] as String,
        deletedAtUtc: json['deletedAtUtc'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'exerciseId': exerciseId,
        'logId': logId,
        'metricValue': metricValue,
        'dedupKey': dedupKey,
        'createdAtUtc': createdAtUtc,
        'deletedAtUtc': deletedAtUtc,
      };
}
