import 'package:sqlite3/sqlite3.dart';

bool isConstraintViolation(Object error) {
  if (error is SqliteException) {
    // Use SQLite result code instead of message text for cross-platform stability.
    // SQLITE_CONSTRAINT = 19, with extended codes like 1555/2067.
    return error.resultCode == 19;
  }
  return false;
}
