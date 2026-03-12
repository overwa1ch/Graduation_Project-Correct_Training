import '../common/date_only.dart';
import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';

class TaskOccurrence {
  final TaskOccurrenceId id;
  final DateOnly date;
  final LogId? boundLogId;
  final bool suppressed;

  const TaskOccurrence({
    required this.id,
    required this.date,
    this.boundLogId,
    this.suppressed = false,
  })  : assert(id != ''),
        assert(boundLogId == null || boundLogId != '');

  bool get materialized => !suppressed && boundLogId != null;

  TaskOccurrence copyWith({
    TaskOccurrenceId? id,
    DateOnly? date,
    Object? boundLogId = _sentinel,
    bool? suppressed,
  }) {
    return TaskOccurrence(
      id: id ?? this.id,
      date: date ?? this.date,
      boundLogId: identical(boundLogId, _sentinel)
          ? this.boundLogId
          : boundLogId as LogId?,
      suppressed: suppressed ?? this.suppressed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toJson(),
        'boundLogId': boundLogId,
        'suppressed': suppressed,
      };

  factory TaskOccurrence.fromJson(Map<String, dynamic> json) {
    requireNonEmpty(json['id'] as String, 'id');
    final boundLogId = json['boundLogId'] as String?;
    if (boundLogId != null) {
      requireNonEmpty(boundLogId, 'boundLogId');
    }
    return TaskOccurrence(
      id: json['id'] as String,
      date: DateOnly.fromJson(json['date'] as String),
      boundLogId: boundLogId,
      suppressed: json['suppressed'] as bool? ?? false,
    );
  }
}

const Object _sentinel = Object();
