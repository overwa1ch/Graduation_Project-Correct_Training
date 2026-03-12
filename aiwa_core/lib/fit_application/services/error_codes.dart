/// 固定 errorCode 常量（Spec §5.1）
///
/// 全部使用大写下划线格式，与规范保持一致。
class AppErrorCodes {
  static const String workoutLogNotFound = 'WORKOUT_LOG_NOT_FOUND';
  static const String exerciseNotFound = 'EXERCISE_NOT_FOUND';
  static const String tagNotFound = 'TAG_NOT_FOUND';
  static const String taskTemplateNotFound = 'TASK_TEMPLATE_NOT_FOUND';
  static const String taskActivationNotFound = 'TASK_ACTIVATION_NOT_FOUND';
  static const String taskOccurrenceNotFound = 'TASK_OCCURRENCE_NOT_FOUND';
  static const String changedLogNotFound = 'WORKOUT_LOG_NOT_FOUND';

  // Range query errors（Range Queries V1.1+）
  static const String invalidRange = 'INVALID_RANGE';
  static const String invalidUtcRange = 'INVALID_UTC_RANGE';

  // Cursor pagination errors（Cursor Pagination V1.1+）
  static const String invalidCursor = 'INVALID_CURSOR';
  static const String invalidCursorVersion = 'INVALID_CURSOR_VERSION';
  static const String cursorMismatch = 'CURSOR_MISMATCH';
}
