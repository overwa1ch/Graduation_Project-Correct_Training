class RepeatConfig {
  int interval = 1;
  String unit = 'Days'; // Days, Weeks, Months, Years
  List<int> daysOfWeek = []; // 1..7
  String ordinal = '1st'; // 1st, 2nd, 3rd, 4th, Last
  String dayType =
      'Day'; // Day, Weekday, Weekend day, Mo, Tu, We, Th, Fr, Sa, Su
  DateTime startDate = _dateOnly(DateTime.now());
  DateTime? endDate = _dateOnly(DateTime.now());
  bool neverEnds = false;

  RepeatConfig();

  factory RepeatConfig.fromJson(Map<String, dynamic> json) {
    final cfg = RepeatConfig();
    cfg.interval = json['interval'] as int? ?? 1;
    cfg.unit = json['unit'] as String? ?? 'Days';
    cfg.daysOfWeek =
        (json['daysOfWeek'] as List<dynamic>?)?.map((e) => e as int).toList() ??
            [];
    cfg.ordinal = json['ordinal'] as String? ?? '1st';
    cfg.dayType = json['dayType'] as String? ?? 'Day';
    final rawStartDate = json['startDate'] as String?;
    if (rawStartDate != null && rawStartDate.trim().isNotEmpty) {
      cfg.startDate =
          _dateOnly(DateTime.tryParse(rawStartDate) ?? DateTime.now());
    }
    final rawEndDate = json['endDate'] as String?;
    if (rawEndDate != null && rawEndDate.trim().isNotEmpty) {
      cfg.endDate = _dateOnly(DateTime.tryParse(rawEndDate) ?? cfg.startDate);
    }
    cfg.neverEnds = json['neverEnds'] as bool? ?? false;
    if (cfg.neverEnds) {
      cfg.endDate = null;
    } else {
      cfg.endDate ??= cfg.startDate;
    }
    return cfg;
  }

  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'unit': unit,
      'daysOfWeek': daysOfWeek,
      'ordinal': ordinal,
      'dayType': dayType,
      'startDate': _dateOnly(startDate).toIso8601String(),
      'endDate':
          neverEnds ? null : _dateOnly(endDate ?? startDate).toIso8601String(),
      'neverEnds': neverEnds,
    };
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool matchesRepeat(DateTime current, DateTime start, RepeatConfig cfg) {
  final normalizedCurrent = _dateOnly(current);
  final normalizedStart = _dateOnly(start);
  if (normalizedCurrent.isBefore(normalizedStart)) {
    return false;
  }
  if (!cfg.neverEnds && cfg.endDate != null) {
    final normalizedEnd = _dateOnly(cfg.endDate!);
    if (normalizedCurrent.isAfter(normalizedEnd)) {
      return false;
    }
  }
  final daysDiff = normalizedCurrent.difference(normalizedStart).inDays;
  if (cfg.unit == 'Days') {
    return (daysDiff % cfg.interval) == 0;
  }

  if (cfg.unit == 'Weeks') {
    if (!cfg.daysOfWeek.contains(normalizedCurrent.weekday)) return false;
    final startMonday =
        normalizedStart.subtract(Duration(days: normalizedStart.weekday - 1));
    final currentMonday = normalizedCurrent
        .subtract(Duration(days: normalizedCurrent.weekday - 1));
    final weeksDiff = currentMonday.difference(startMonday).inDays ~/ 7;
    return (weeksDiff % cfg.interval) == 0;
  }

  if (cfg.unit == 'Months' || cfg.unit == 'Years') {
    int monthDiff = (normalizedCurrent.year - normalizedStart.year) * 12 +
        (normalizedCurrent.month - normalizedStart.month);
    if (cfg.unit == 'Months') {
      if ((monthDiff % cfg.interval) != 0) return false;
    } else {
      if ((normalizedCurrent.year - normalizedStart.year) % cfg.interval != 0)
        return false;
      if (normalizedCurrent.month != normalizedStart.month) return false;
    }

    bool typeMatch = false;
    if (cfg.dayType == 'Day')
      typeMatch = true;
    else if (cfg.dayType == 'Weekday')
      typeMatch =
          normalizedCurrent.weekday >= 1 && normalizedCurrent.weekday <= 5;
    else if (cfg.dayType == 'Weekend day')
      typeMatch = normalizedCurrent.weekday >= 6;
    else if (cfg.dayType == 'Mo')
      typeMatch = normalizedCurrent.weekday == 1;
    else if (cfg.dayType == 'Tu')
      typeMatch = normalizedCurrent.weekday == 2;
    else if (cfg.dayType == 'We')
      typeMatch = normalizedCurrent.weekday == 3;
    else if (cfg.dayType == 'Th')
      typeMatch = normalizedCurrent.weekday == 4;
    else if (cfg.dayType == 'Fr')
      typeMatch = normalizedCurrent.weekday == 5;
    else if (cfg.dayType == 'Sa')
      typeMatch = normalizedCurrent.weekday == 6;
    else if (cfg.dayType == 'Su') typeMatch = normalizedCurrent.weekday == 7;

    if (!typeMatch) return false;

    int matchCount = 0;
    for (int day = 1; day <= normalizedCurrent.day; day++) {
      DateTime check =
          DateTime(normalizedCurrent.year, normalizedCurrent.month, day);
      bool checkMatch = false;
      if (cfg.dayType == 'Day')
        checkMatch = true;
      else if (cfg.dayType == 'Weekday')
        checkMatch = check.weekday >= 1 && check.weekday <= 5;
      else if (cfg.dayType == 'Weekend day')
        checkMatch = check.weekday >= 6;
      else if (cfg.dayType == 'Mo')
        checkMatch = check.weekday == 1;
      else if (cfg.dayType == 'Tu')
        checkMatch = check.weekday == 2;
      else if (cfg.dayType == 'We')
        checkMatch = check.weekday == 3;
      else if (cfg.dayType == 'Th')
        checkMatch = check.weekday == 4;
      else if (cfg.dayType == 'Fr')
        checkMatch = check.weekday == 5;
      else if (cfg.dayType == 'Sa')
        checkMatch = check.weekday == 6;
      else if (cfg.dayType == 'Su') checkMatch = check.weekday == 7;

      if (checkMatch) matchCount++;
    }

    if (cfg.ordinal == '1st' && matchCount == 1) return true;
    if (cfg.ordinal == '2nd' && matchCount == 2) return true;
    if (cfg.ordinal == '3rd' && matchCount == 3) return true;
    if (cfg.ordinal == '4th' && matchCount == 4) return true;

    if (cfg.ordinal == 'Last') {
      int daysInMonth =
          DateTime(normalizedCurrent.year, normalizedCurrent.month + 1, 0).day;
      for (int day = normalizedCurrent.day + 1; day <= daysInMonth; day++) {
        DateTime check =
            DateTime(normalizedCurrent.year, normalizedCurrent.month, day);
        bool checkMatch = false;
        if (cfg.dayType == 'Day')
          checkMatch = true;
        else if (cfg.dayType == 'Weekday')
          checkMatch = check.weekday >= 1 && check.weekday <= 5;
        else if (cfg.dayType == 'Weekend day')
          checkMatch = check.weekday >= 6;
        else if (cfg.dayType == 'Mo')
          checkMatch = check.weekday == 1;
        else if (cfg.dayType == 'Tu')
          checkMatch = check.weekday == 2;
        else if (cfg.dayType == 'We')
          checkMatch = check.weekday == 3;
        else if (cfg.dayType == 'Th')
          checkMatch = check.weekday == 4;
        else if (cfg.dayType == 'Fr')
          checkMatch = check.weekday == 5;
        else if (cfg.dayType == 'Sa')
          checkMatch = check.weekday == 6;
        else if (cfg.dayType == 'Su') checkMatch = check.weekday == 7;
        if (checkMatch) return false;
      }
      return true;
    }
    return false;
  }
  return false;
}
