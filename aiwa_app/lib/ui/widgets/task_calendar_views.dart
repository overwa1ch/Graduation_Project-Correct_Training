import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';

class YearSection extends StatefulWidget {
  const YearSection({
    super.key,
    required this.year,
    required this.markerRevision,
    required this.loadLogDays,
    required this.onOpenMonth,
  });

  final int year;
  final int markerRevision;
  final Future<Set<String>> Function(int year) loadLogDays;
  final void Function(int month) onOpenMonth;

  @override
  State<YearSection> createState() => _YearSectionState();
}

class _YearSectionState extends State<YearSection> {
  late Future<Set<String>> _logDaysFuture;

  @override
  void initState() {
    super.initState();
    _logDaysFuture = widget.loadLogDays(widget.year);
  }

  @override
  void didUpdateWidget(covariant YearSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year ||
        oldWidget.markerRevision != widget.markerRevision) {
      _logDaysFuture = widget.loadLogDays(widget.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Set<String>>(
      future: _logDaysFuture,
      builder: (context, snapshot) => _YearSectionView(
        year: widget.year,
        logDays: snapshot.data ?? const <String>{},
        onOpenMonth: widget.onOpenMonth,
      ),
    );
  }
}

class _YearSectionView extends StatelessWidget {
  const _YearSectionView({
    required this.year,
    required this.logDays,
    required this.onOpenMonth,
  });

  final int year;
  final Set<String> logDays;
  final void Function(int month) onOpenMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Text(
            '$year年',
            style: AppTypography.bodyBase
                .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) => InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => onOpenMonth(index + 1),
            child: MiniMonthCard(
              year: year,
              month: index + 1,
              logDays: logDays,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class MiniMonthCard extends StatelessWidget {
  const MiniMonthCard({
    super.key,
    required this.year,
    required this.month,
    required this.logDays,
  });

  final int year;
  final int month;
  final Set<String> logDays;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    final lead = first.weekday % 7;
    final now = DateTime.now();
    final cellCount = lead + totalDays;

    return Card(
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$month月',
              textAlign: TextAlign.center,
              style: AppTypography.caption
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                ),
                itemCount: cellCount,
                itemBuilder: (context, index) {
                  if (index < lead) {
                    return const SizedBox.shrink();
                  }
                  final day = index - lead + 1;
                  final key = DateOnly(year, month, day).toString();
                  final hasLog = logDays.contains(key);
                  final isToday =
                      now.year == year && now.month == month && now.day == day;
                  return Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.red.shade400
                          : hasLog
                              ? const Color(0xFF3FD17A)
                              : AppColors.textPrimary.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandedMonthSection extends StatefulWidget {
  const ExpandedMonthSection({
    super.key,
    required this.month,
    required this.selected,
    required this.markerRevision,
    required this.loadLogCountByDay,
    required this.onDayTap,
  });

  final DateTime month;
  final DateOnly? selected;
  final int markerRevision;
  final Future<Map<String, int>> Function(DateTime month) loadLogCountByDay;
  final void Function(DateOnly) onDayTap;

  @override
  State<ExpandedMonthSection> createState() => _ExpandedMonthSectionState();
}

class _ExpandedMonthSectionState extends State<ExpandedMonthSection> {
  late Future<Map<String, int>> _logCountFuture;

  @override
  void initState() {
    super.initState();
    _logCountFuture = widget.loadLogCountByDay(widget.month);
  }

  @override
  void didUpdateWidget(covariant ExpandedMonthSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year != widget.month.year ||
        oldWidget.month.month != widget.month.month ||
        oldWidget.markerRevision != widget.markerRevision) {
      _logCountFuture = widget.loadLogCountByDay(widget.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _logCountFuture,
      builder: (context, snapshot) => _ExpandedMonthSectionView(
        month: widget.month,
        selected: widget.selected,
        logCountByDay: snapshot.data ?? const <String, int>{},
        onDayTap: widget.onDayTap,
      ),
    );
  }
}

class _ExpandedMonthSectionView extends StatelessWidget {
  const _ExpandedMonthSectionView({
    required this.month,
    required this.selected,
    required this.logCountByDay,
    required this.onDayTap,
  });

  final DateTime month;
  final DateOnly? selected;
  final Map<String, int> logCountByDay;
  final void Function(DateOnly) onDayTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Text(
            '${month.year}年${month.month}月',
            style: AppTypography.bodyBase
                .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        CalendarGrid(
          month: month,
          selected: selected,
          logCountByDay: logCountByDay,
          expanded: true,
          shrinkWrap: true,
          onTap: onDayTap,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.logCountByDay,
    required this.expanded,
    required this.onTap,
    this.shrinkWrap = false,
  });

  final DateTime month;
  final DateOnly? selected;
  final Map<String, int> logCountByDay;
  final bool expanded;
  final bool shrinkWrap;
  final void Function(DateOnly d) onTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7;
    final now = DateTime.now();

    final children = <Widget>[
      for (final weekday in const ['日', '一', '二', '三', '四', '五', '六'])
        Center(
          child: Text(
            weekday,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
    ];

    for (var i = 0; i < lead; i++) {
      children.add(const SizedBox());
    }

    for (var day = 1; day <= days; day++) {
      final date = DateOnly(month.year, month.month, day);
      final key = date.toString();
      final logCount = logCountByDay[key] ?? 0;
      final visibleLogLines = logCount > 3 ? 3 : logCount;
      final isSelected = selected == date;
      final isToday = now.year == date.year &&
          now.month == date.month &&
          now.day == date.day;
      children.add(
        InkWell(
          onTap: () => onTap(date),
          child: _CalendarDayCell(
            day: day,
            expanded: expanded,
            isSelected: isSelected,
            isToday: isToday,
            visibleLogLines: visibleLogLines,
          ),
        ),
      );
    }

    while (children.length < 49) {
      children.add(const SizedBox());
    }

    if (shrinkWrap) {
      final aspectRatio = expanded
          ? calendarExpandedAspectRatio(MediaQuery.of(context).size.width)
          : 1.0;
      return GridView.count(
        crossAxisCount: 7,
        childAspectRatio: aspectRatio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: expanded ? 2 : 0,
        crossAxisSpacing: expanded ? 2 : 0,
        children: children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        const rows = 7;
        final cellHeight = constraints.maxHeight > 0
            ? constraints.maxHeight / rows
            : cellWidth;
        final ratio = cellHeight > 0 ? cellWidth / cellHeight : 0.88;
        return GridView.count(
          crossAxisCount: 7,
          childAspectRatio: ratio.clamp(0.4, 1.6),
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.expanded,
    required this.isSelected,
    required this.isToday,
    required this.visibleLogLines,
  });

  final int day;
  final bool expanded;
  final bool isSelected;
  final bool isToday;
  final int visibleLogLines;

  @override
  Widget build(BuildContext context) {
    final markerBlockHeight = expanded && visibleLogLines > 0
        ? (visibleLogLines * 2.0) + ((visibleLogLines - 1) * 2.0) + 6.0
        : 0.0;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandPrimaryVariant.withValues(alpha: 0.35)
            : (isToday
                ? Colors.red.withValues(alpha: 0.18)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: markerBlockHeight * 0.35),
                child: Text(
                  '$day',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyBase.copyWith(
                    fontSize: expanded ? 17 : 13,
                    color: isToday ? Colors.red.shade300 : null,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w400,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          if (expanded && visibleLogLines > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _CalendarLogMarkers(count: visibleLogLines),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CalendarLogMarkers extends StatelessWidget {
  const _CalendarLogMarkers({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        count,
        (index) => Container(
          width: 26,
          height: 2,
          margin: EdgeInsets.only(bottom: index == count - 1 ? 0 : 2),
          decoration: BoxDecoration(
            color: const Color(0xFF3FD17A),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

double calendarExpandedAspectRatio(double screenWidth) {
  if (screenWidth < 380) {
    return 0.66;
  }
  if (screenWidth < 430) {
    return 0.74;
  }
  return 0.82;
}

double expandedMonthSectionHeight(double screenWidth) {
  final gridWidth = screenWidth - AppSpacing.pagePadding * 2;
  final cellWidth = gridWidth / 7;
  final cellHeight = cellWidth / calendarExpandedAspectRatio(screenWidth);
  const headerHeight = 52.0;
  const rowSpacing = 2.0;
  const rowCount = 7;
  final gridHeight = cellHeight * rowCount + rowSpacing * (rowCount - 1);
  return headerHeight + gridHeight + AppSpacing.sm;
}
