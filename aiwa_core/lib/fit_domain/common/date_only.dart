import 'package:json_annotation/json_annotation.dart';

import 'domain_exception.dart';

class DateOnly implements Comparable<DateOnly> {
  final int year;
  final int month;
  final int day;

  DateOnly(this.year, this.month, this.day) {
    _validate();
  }

  factory DateOnly.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw ValidationException(
        'validation.date_only_format',
        'DateOnly must be in YYYY-MM-DD format',
        {'value': value},
      );
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateOnly(year, month, day);
  }

  factory DateOnly.fromJson(String value) => DateOnly.parse(value);

  String toJson() => toString();

  DateTime toDateTimeUtc() => DateTime.utc(year, month, day);

  static DateOnly fromDateTimeUtc(DateTime value) {
    requireUtc(value, 'value');
    return DateOnly(value.year, value.month, value.day);
  }

  void _validate() {
    if (year < 1 || year > 9999) {
      throw ValidationException(
        'validation.date_only_year',
        'Year out of range for DateOnly',
        {'year': year},
      );
    }
    if (month < 1 || month > 12) {
      throw ValidationException(
        'validation.date_only_month',
        'Month out of range for DateOnly',
        {'month': month},
      );
    }
    final dt = DateTime.utc(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) {
      throw ValidationException(
        'validation.date_only_day',
        'Day out of range for DateOnly',
        {'year': year, 'month': month, 'day': day},
      );
    }
  }

  @override
  String toString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  int compareTo(DateOnly other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return other is DateOnly &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}

class DateOnlyJsonConverter implements JsonConverter<DateOnly, String> {
  const DateOnlyJsonConverter();

  @override
  DateOnly fromJson(String json) => DateOnly.parse(json);

  @override
  String toJson(DateOnly object) => object.toString();
}

class UtcDateTimeConverter implements JsonConverter<DateTime, String> {
  const UtcDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    final parsed = DateTime.parse(json);
    // Require the incoming value itself to be UTC (e.g. with a trailing 'Z' or +00:00).
    // We deliberately do NOT silently convert local/offset times to UTC to avoid
    // hiding upstream time zone bugs.
    if (!parsed.isUtc) {
      throw ValidationException(
        'validation.not_utc',
        'DateTime must be UTC',
        {'value': json},
      );
    }
    return parsed;
  }

  @override
  String toJson(DateTime object) {
    final utc = object.toUtc();
    if (!utc.isUtc) {
      throw ValidationException(
        'validation.not_utc',
        'DateTime must be UTC',
        {'value': object.toIso8601String()},
      );
    }
    return utc.toIso8601String();
  }
}