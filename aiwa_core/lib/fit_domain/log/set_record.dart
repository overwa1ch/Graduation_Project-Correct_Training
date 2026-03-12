import 'package:freezed_annotation/freezed_annotation.dart';

part 'set_record.freezed.dart';
part 'set_record.g.dart';

@freezed
class SetRecord with _$SetRecord {
  const SetRecord._();

  @Assert('weightKg >= 0')
  @Assert('reps >= 0')
  @Assert('restSec == null || restSec >= 0')
  factory SetRecord({
    required double weightKg,
    required int reps,
    int? restSec,
  }) = _SetRecord;

  factory SetRecord.fromJson(Map<String, dynamic> json) =>
      _$SetRecordFromJson(json);

  bool get isValid => reps >= 1;

  double get volume => weightKg * reps;

  double get estimated1RM => weightKg * (1 + reps / 30.0);
}
