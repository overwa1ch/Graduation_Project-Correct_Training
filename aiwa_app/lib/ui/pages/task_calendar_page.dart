import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/services/fit/fit_scope.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/models/repeat_config.dart';
import 'package:aiwa_app/ui/widgets/aiwa_inline_rich_text_codec.dart';
import 'package:aiwa_app/ui/widgets/appflowy_block_dto_codec.dart';
import 'package:aiwa_app/ui/widgets/log_search_delegate.dart';
import 'package:aiwa_app/ui/widgets/task_calendar_views.dart';
import 'package:aiwa_app/ui/widgets/task_calendar_overlays.dart';
import 'package:aiwa_app/ui/widgets/template_manager_bottom_sheet.dart';

enum _ViewMode { year, month }

enum _SortMode { asc, desc }

class TaskCalendarPage extends StatefulWidget {
  const TaskCalendarPage({super.key});

  @override
  State<TaskCalendarPage> createState() => _TaskCalendarPageState();
}

class _TaskCalendarPageState extends State<TaskCalendarPage>
    with TickerProviderStateMixin {
  static const int _kBaseYear = 2000;
  static const int _kYearCount = 300; // 2000闂?299

  _ViewMode _mode = _ViewMode.year;
  _SortMode _sort = _SortMode.desc;
  bool _loading = false; // show UI immediately; data loads in background
  bool _expanded = false;

  late int _year;
  late DateTime _month;
  DateOnly? _selected;

  // Year view 闂?continuous scroll, no snap
  late ScrollController _yearScrollCtrl;
  // Month normal view 闂?vertical PageView, snaps per month
  late PageController _monthPageCtrl;
  // Month expanded view 闂?continuous scroll, no snap
  late ScrollController _expandedScrollCtrl;

  // Drives the year 闂?month page transition (0 = year, 1 = month).
  late AnimationController _pageTransCtrl;
  late CurvedAnimation _pageCurve;
  // Pre-computed animations for year闂備焦鍓氶崑鍛村绩缁屾獢th 闂?no per-frame computation needed.
  late Animation<double> _yearExitOpacity; // 1.0 闂?0.0
  late Animation<double> _monthEntryOpacity; // 0.0 闂?1.0
  late Animation<double> _monthEntryScale; // 0.80 闂?1.0

  // Drives the normal 闂?expanded month transition (0 = normal, 1 = expanded).
  late AnimationController _expandTransCtrl;
  late Animation<double> _normalMonthOpacity; // 1.0 闂?0.0
  late Animation<double> _expandedViewOpacity; // 0.0 闂?1.0

  List<LogEditorDTO> _yearLogs = [];
  List<LogEditorDTO> _monthLogs = [];
  Timer? _reloadDebounce;
  int _markerRevision = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = DateTime(now.year, now.month, 1);
    _selected = DateOnly(now.year, now.month, now.day);
    // Pre-position the year list close to the current year so the first
    // frame does not briefly show year 2000 before jumping.
    final view = PlatformDispatcher.instance.implicitView;
    final logicalWidth = view != null
        ? view.physicalSize.width / view.devicePixelRatio
        : 390.0; // safe default width
    final initialYearOffset =
        (_year - _kBaseYear) * _estimateYearSectionHeight(logicalWidth);
    _yearScrollCtrl = ScrollController(initialScrollOffset: initialYearOffset);
    _monthPageCtrl = PageController(
      initialPage: (_year - _kBaseYear) * 12 + (now.month - 1),
      keepPage: true,
    );
    _expandedScrollCtrl = ScrollController();

    _pageTransCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageCurve = CurvedAnimation(
      parent: _pageTransCtrl,
      curve: Curves.easeInOutCubic,
    );
    // Pre-compute derived animations once 闂?FadeTransition/ScaleTransition
    // use these directly without rebuilding widgets on each frame.
    _yearExitOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _pageTransCtrl, curve: Curves.easeIn));
    _monthEntryOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _pageTransCtrl, curve: Curves.easeOut));
    _monthEntryScale = Tween<double>(begin: 0.80, end: 1.0).animate(
        CurvedAnimation(parent: _pageTransCtrl, curve: Curves.easeOutCubic));

    _expandTransCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _normalMonthOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _expandTransCtrl, curve: Curves.easeIn));
    _expandedViewOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _expandTransCtrl, curve: Curves.easeOut));

    // Sync _year as the user scrolls the year list
    _yearScrollCtrl.addListener(_onYearScroll);
    // Sync _month/_year as the user scrolls the expanded month list
    _expandedScrollCtrl.addListener(_onExpandedScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fine-tune scroll position once layout is complete, then load data.
      _jumpToCurrentYear();
      await _syncVisibleTaskOccurrences();
      if (!mounted) {
        return;
      }
      await _reload();
    });
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _yearScrollCtrl.dispose();
    _monthPageCtrl.dispose();
    _expandedScrollCtrl.dispose();
    _pageTransCtrl.dispose();
    _pageCurve.dispose();
    _expandTransCtrl.dispose();
    super.dispose();
  }

  DateOnly get _yearStart => DateOnly(_year, 1, 1);
  DateOnly get _yearEnd => DateOnly(_year, 12, 31);
  DateOnly get _monthStart => DateOnly(_month.year, _month.month, 1);
  DateOnly get _monthEnd => _lastDayOfMonth(_month);

  DateOnly _lastDayOfMonth(DateTime month) {
    final lastDay = DateTime.utc(month.year, month.month + 1, 0);
    return DateOnly(lastDay.year, lastDay.month, lastDay.day);
  }

  Future<void> _syncVisibleTaskOccurrences() async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    await scope.hub.taskTemplateOccurrenceSyncService.syncVisibleYear(
      yearFrom: _yearStart,
      yearTo: _yearEnd,
    );
  }

  Future<void> _reload() async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final snapshot = await scope.hub.getCalendarSnapshotUseCase.execute(
        CalendarSnapshotQuery(
          yearFrom: _yearStart,
          yearTo: _yearEnd,
          monthFrom: _monthStart,
          monthTo: _monthEnd,
        ),
      );
      if (!mounted) return;
      setState(() {
        _yearLogs = snapshot.yearLogs;
        _monthLogs = snapshot.monthLogs;
        _markerRevision += 1;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('TaskCalendarPage _reload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _scheduleReload({Duration delay = const Duration(milliseconds: 180)}) {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(delay, () async {
      if (!mounted) {
        return;
      }
      await _syncVisibleTaskOccurrences();
      if (!mounted) {
        return;
      }
      await _reload();
    });
  }

  Map<String, dynamic> _parseTaskTemplatePayload(TaskTemplate template) {
    try {
      final raw = jsonDecode(template.description ?? '{}');
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _activateTaskTemplate(TaskTemplate template) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    final payload = _parseTaskTemplatePayload(template);
    final repeatJson = payload['repeatConfig'];
    final repeatConfig = repeatJson is Map<String, dynamic>
        ? RepeatConfig.fromJson(repeatJson)
        : repeatJson is Map
            ? RepeatConfig.fromJson(Map<String, dynamic>.from(repeatJson))
            : RepeatConfig();
    final startDate = repeatConfig.startDate;
    await scope.hub.ensureTaskActivationUseCase.execute(
      EnsureTaskActivationInput(
        templateId: template.id,
        startDate: DateOnly(startDate.year, startDate.month, startDate.day),
      ),
    );
    await _syncVisibleTaskOccurrences();
  }

  String _logTitle(LogEditorDTO log) {
    for (final b in log.blocks) {
      if (b is HeadingBlockDTO) {
        final heading = plainTextFromAiwaRichText(b.text).trim();
        if (heading.isNotEmpty) {
          return heading;
        }
      }
      final summary = describeBlockDto(b).trim();
      if (summary.isNotEmpty) return summary;
      if (b is ExerciseBlockDTO && b.exerciseNameSnapshot.trim().isNotEmpty) {
        return b.exerciseNameSnapshot.trim();
      }
    }
    return '\u8bad\u7ec3\u65e5\u5fd7';
  }

  String _logDateLabel(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return rawDate;
    }
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  Future<void> _openLogEditor(String logId) async {
    await Navigator.pushNamed(
      context,
      '/editor',
      arguments: <String, dynamic>{'logId': logId},
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _deleteLogFromCalendar(LogEditorDTO log) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    await scope.hub.deleteTaskLogUseCase.execute(
      DeleteTaskLogInput(
        logId: log.id,
        taskOccurrenceId: log.boundTaskOccurrenceId,
      ),
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openSearch() async {
    final logs = _mode == _ViewMode.year ? _yearLogs : _monthLogs;
    final selected = await showLogSearch(
      context: context,
      logs: logs,
      titleOf: _logTitle,
    );
    if (selected != null && mounted) {
      await _openLogEditor(selected.id);
    }
  }

  // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?helpers 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹?
  /// Estimated height of one YearSection in the year ListView.
  double _estimateYearSectionHeight(double screenWidth) {
    final gridWidth = screenWidth - AppSpacing.pagePadding * 2;
    final cardH = (gridWidth / 3) / 0.82; // childAspectRatio 0.82
    return 52.0 + 4 * cardH + AppSpacing.sm; // label + 4 rows + bottom gap
  }

  /// Estimated height of one ExpandedMonthSection in the expanded ListView.
  /// Actual layout: label padding(top 16 + bottom 4) + text(~31, measured) +
  ///   CalendarGrid(7 rows 闂?gridWidth/7 = gridWidth) + bottom gap(8).
  /// Total = gridWidth + 59, +5 safety buffer = gridWidth + 64.
  double _estimateExpandedItemHeight(double screenWidth) {
    return expandedMonthSectionHeight(screenWidth);
  }

  /// Jump the year ListView to the current year (no animation 闂?used on init).
  void _jumpToCurrentYear() {
    if (!mounted || !_yearScrollCtrl.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final sectionH = _estimateYearSectionHeight(screenWidth);
    // Don't clamp 闂?ListView.builder handles out-of-range offsets by lazy-rendering
    _yearScrollCtrl.jumpTo((_year - _kBaseYear) * sectionH);
  }

  /// Updates [_year] while the user scrolls the year-view ListView.
  void _onYearScroll() {
    if (!mounted || !_yearScrollCtrl.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final sectionH = _estimateYearSectionHeight(screenWidth);
    if (sectionH <= 0) return;
    final y = (_yearScrollCtrl.offset / sectionH).round() + _kBaseYear;
    final clamped = y.clamp(_kBaseYear, _kBaseYear + _kYearCount - 1);
    if (_year != clamped) {
      setState(() => _year = clamped);
      _scheduleReload();
    }
  }

  /// Updates [_month] and [_year] while the user scrolls the expanded-month list.
  void _onExpandedScroll() {
    if (!mounted || !_expandedScrollCtrl.hasClients) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemH = _estimateExpandedItemHeight(screenWidth);
    if (itemH <= 0) return;
    final idx = (_expandedScrollCtrl.offset / itemH)
        .round()
        .clamp(0, _kYearCount * 12 - 1);
    final y = idx ~/ 12 + _kBaseYear;
    final m = idx % 12 + 1;
    if (_month.year != y || _month.month != m) {
      setState(() {
        _month = DateTime(y, m, 1);
        _year = y;
      });
      _scheduleReload();
    }
  }

  // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?navigation 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻?
  void _goToday() {
    final n = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;

    if (_mode == _ViewMode.year) {
      // Stay in year view 闂?scroll to current year
      setState(() {
        _year = n.year;
        _selected = DateOnly(n.year, n.month, n.day);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_yearScrollCtrl.hasClients) {
          final sectionH = _estimateYearSectionHeight(screenWidth);
          final target = (n.year - _kBaseYear) * sectionH;
          _yearScrollCtrl.animateTo(
            target,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
      _scheduleReload(delay: Duration.zero);
    } else if (_expanded) {
      // Stay in expanded view 闂?scroll to current month
      setState(() {
        _year = n.year;
        _month = DateTime(n.year, n.month, 1);
        _selected = DateOnly(n.year, n.month, n.day);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_expandedScrollCtrl.hasClients) {
          final itemH = _estimateExpandedItemHeight(screenWidth);
          final idx = (n.year - _kBaseYear) * 12 + (n.month - 1);
          _expandedScrollCtrl.animateTo(
            idx * itemH,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
      _scheduleReload(delay: Duration.zero);
    } else {
      // Normal month view 闂?animate PageView to current month
      final targetPage = (n.year - _kBaseYear) * 12 + (n.month - 1);
      setState(() {
        _year = n.year;
        _month = DateTime(n.year, n.month, 1);
        _selected = DateOnly(n.year, n.month, n.day);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthPageCtrl.hasClients) {
          _monthPageCtrl.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
        }
      });
      _scheduleReload(delay: Duration.zero);
    }
  }

  // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?View-transition helpers 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕?

  /// Opens [month] of [year] in the month view with a zoom-in animation.
  /// Data reload is deferred until after the animation completes to avoid
  /// setState rebuilds dropping animation frames.
  void _openMonth(int y, int m) {
    final page = (y - _kBaseYear) * 12 + (m - 1);
    // Reset expand state so normal month view is shown on entry.
    _expandTransCtrl.value = 0.0;
    setState(() {
      _year = y;
      _month = DateTime(y, m, 1);
      _mode = _ViewMode.month;
      _expanded = false;
    });
    _pageTransCtrl.forward(from: 0.0).then((_) {
      if (mounted) _scheduleReload(delay: Duration.zero);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthPageCtrl.hasClients) _monthPageCtrl.jumpToPage(page);
    });
  }

  /// Returns to the year view with a zoom-out animation.
  void _backToYear() {
    // Immediately collapse expanded view (no animation needed while page exits).
    _expandTransCtrl.value = 0.0;
    _pageTransCtrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _mode = _ViewMode.year;
          _expanded = false;
        });
      }
    });
  }

  /// Toggles between normal-month and expanded-month views.
  void _toggleExpand() {
    if (_expanded) {
      // Collapse: animate out, then update state and restore PageView position.
      _expandTransCtrl.reverse().then((_) {
        if (!mounted) return;
        final page = (_month.year - _kBaseYear) * 12 + (_month.month - 1);
        setState(() => _expanded = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_monthPageCtrl.hasClients) _monthPageCtrl.jumpToPage(page);
        });
      });
    } else {
      // Expand: jump expanded list to current month (always mounted), then fade in.
      final screenWidth = MediaQuery.of(context).size.width;
      final itemH = _estimateExpandedItemHeight(screenWidth);
      final idx = (_month.year - _kBaseYear) * 12 + (_month.month - 1);
      if (_expandedScrollCtrl.hasClients) {
        _expandedScrollCtrl.jumpTo(idx * itemH);
      }
      setState(() => _expanded = true);
      _expandTransCtrl.forward(from: 0.0);
    }
  }

  Future<void> _showCreateDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => TemplateManagerBottomSheet(
        onActivateTask: (template) async {
          await _activateTaskTemplate(template);
          if (mounted) {
            await _reload();
          }
        },
      ),
    );
  }

  Future<void> _showDayView(DateOnly date) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }

    final logs = await scope.hub.getWorkoutLogsByDateRangeUseCase.execute(
      DateRangeQuery(from: date, to: date),
    );
    if (!mounted) {
      return;
    }

    await showDayViewSheet(
      context: context,
      date: date,
      logs: logs,
      titleOf: _logTitle,
      onOpenLog: (log) => _openLogEditor(log.id),
      onDeleteLog: _deleteLogFromCalendar,
    );
  }

  Future<Set<String>> _loadYearLogDays(int year) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return const <String>{};
    }
    final rows = await scope.hub.workoutLogRepository.countByDateRangeCursor(
      from: DateOnly(year, 1, 1),
      to: DateOnly(year, 12, 31),
      pageSize: 366,
    );
    final days = rows.items.map((row) => row.date.toString()).toSet();
    if (year == DateTime.now().year) {
      debugPrint('TaskCalendar year markers $year => ${days.length} days');
    }
    return days;
  }

  Future<Map<String, int>> _loadMonthLogCountByDay(DateTime month) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return const <String, int>{};
    }
    final rows = await scope.hub.workoutLogRepository.countByDateRangeCursor(
      from: DateOnly(month.year, month.month, 1),
      to: _lastDayOfMonth(month),
      pageSize: 31,
    );
    final counts = <String, int>{
      for (final row in rows.items) row.date.toString(): row.count,
    };
    final now = DateTime.now();
    if (month.year == now.year && month.month == now.month) {
      final todayKey = DateOnly(now.year, now.month, now.day).toString();
      debugPrint(
        'TaskCalendar month markers ${month.year}-${month.month} => '
        '${counts.length} days, today=$todayKey count=${counts[todayKey] ?? 0}',
      );
    }
    return counts;
  }

  // Build helpers
  // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍?

  Widget _buildMonthHeader({double cellSize = 40.0}) {
    return Row(children: [
      // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?"< 2026婵? iOS-style back button 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
      TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          foregroundColor: Theme.of(context).colorScheme.primary,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _backToYear,
        icon: const Icon(Icons.chevron_left, size: 26),
        label: Text(
          '$_year\u5e74',
          style: AppTypography.bodyBase
              .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      const Spacer(),
      // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?month/year label (compact) 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
      Text(
        '${_month.month}\u6708',
        style: AppTypography.bodyBase.copyWith(fontWeight: FontWeight.w700),
      ),
      const Spacer(),
      // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?expand/collapse 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
      IconButton(
        onPressed: _toggleExpand,
        icon:
            Icon(_expanded ? Icons.calendar_today : Icons.calendar_view_month),
      ),
      IconButton(onPressed: _openSearch, icon: const Icon(Icons.search)),
      IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
    ]);
  }

  Widget _buildYearView() {
    return PageContainer(
      child: Column(children: [
        Row(children: [
          const Spacer(),
          IconButton(onPressed: _openSearch, icon: const Icon(Icons.search)),
          IconButton(onPressed: _showCreateDialog, icon: const Icon(Icons.add)),
        ]),
        Expanded(
          child: ListView.builder(
            key: const PageStorageKey<String>('year-list'),
            controller: _yearScrollCtrl,
            itemCount: _kYearCount,
            itemBuilder: (ctx, i) {
              final y = _kBaseYear + i;
              return YearSection(
                year: y,
                markerRevision: _markerRevision,
                loadLogDays: _loadYearLogDays,
                onOpenMonth: (m) => _openMonth(y, m),
              );
            },
          ),
        ),
      ]),
    );
  }

  List<LogEditorDTO> _sortedMonthLogs() {
    final logs = _monthLogs.toList()..sort((a, b) => a.date.compareTo(b.date));
    return _sort == _SortMode.desc
        ? logs.reversed.toList(growable: false)
        : logs;
  }

  /// Shared month area used for both normal and expanded states.
  Widget _buildMonthViewArea(double calendarHeight, double cellSize) {
    final sorted = _sortedMonthLogs();
    final screenWidth = MediaQuery.of(context).size.width;
    final expandedItemH = _estimateExpandedItemHeight(screenWidth);
    return PageContainer(
      child: Column(children: [
        _buildMonthHeader(cellSize: cellSize),
        const SizedBox(height: AppSpacing.xs),
        // Both sub-views live permanently in the tree so their controllers
        // (PageController, ScrollController) are never disposed mid-session.
        // FadeTransition + RepaintBoundary = GPU texture swap, zero repaint.
        Expanded(
          child: Stack(children: [
            // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?Expanded month list 闂?fades in as _expandTransCtrl 闂?1 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
            FadeTransition(
              opacity: _expandedViewOpacity,
              child: IgnorePointer(
                ignoring: !_expanded,
                child: RepaintBoundary(
                  child: ListView.builder(
                    key: const PageStorageKey<String>('expanded-list'),
                    controller: _expandedScrollCtrl,
                    // itemExtent: every item is the same height 闂?exact offsets
                    itemExtent: expandedItemH,
                    itemCount: _kYearCount * 12,
                    itemBuilder: (ctx, i) {
                      final y = i ~/ 12 + _kBaseYear;
                      final m = i % 12 + 1;
                      return ExpandedMonthSection(
                        month: DateTime(y, m, 1),
                        selected: _selected,
                        markerRevision: _markerRevision,
                        loadLogCountByDay: _loadMonthLogCountByDay,
                        onDayTap: (d) {
                          setState(() {
                            _selected = d;
                            _month = DateTime(y, m, 1);
                            _year = y;
                          });
                          _showDayView(d);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?Normal month view 闂?fades out as _expandTransCtrl 闂?1 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
            FadeTransition(
              opacity: _normalMonthOpacity,
              child: IgnorePointer(
                ignoring: _expanded,
                child: RepaintBoundary(
                  child: Column(children: [
                    // Calendar snaps vertically to each month
                    SizedBox(
                      height: calendarHeight,
                      child: PageView.builder(
                        key: const PageStorageKey<String>('month-pv'),
                        controller: _monthPageCtrl,
                        scrollDirection: Axis.vertical,
                        physics: const BouncingScrollPhysics(
                            parent: PageScrollPhysics()),
                        itemCount: _kYearCount * 12,
                        onPageChanged: (page) {
                          final y = page ~/ 12 + _kBaseYear;
                          final m = page % 12 + 1;
                          setState(() {
                            _month = DateTime(y, m, 1);
                            _year = y;
                          });
                          _reload();
                        },
                        itemBuilder: (ctx, page) {
                          final y = page ~/ 12 + _kBaseYear;
                          final m = page % 12 + 1;
                          return CalendarGrid(
                            month: DateTime(y, m, 1),
                            selected: _selected,
                            logCountByDay: const <String, int>{},
                            expanded: false,
                            onTap: (d) {
                              // Tapping a date expands into the full list.
                              final idx =
                                  (d.year - _kBaseYear) * 12 + (d.month - 1);
                              setState(() {
                                _selected = d;
                                _month = DateTime(d.year, d.month, 1);
                                _year = d.year;
                                _expanded = true;
                              });
                              // ListView is always mounted; jump immediately.
                              if (_expandedScrollCtrl.hasClients) {
                                _expandedScrollCtrl.jumpTo(idx * expandedItemH);
                              }
                              _expandTransCtrl.forward(from: 0.0);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: Text('\u8bad\u7ec3\u8bb0\u5f55',
                            style: AppTypography.caption
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _sort =
                            _sort == _SortMode.asc
                                ? _SortMode.desc
                                : _SortMode.asc),
                        child: Text(_sort == _SortMode.asc
                            ? '\u6b63\u5e8f'
                            : '\u5012\u5e8f'),
                      ),
                    ]),
                    Expanded(
                      child: sorted.isEmpty
                          ? const Center(
                              child: Text('\u6682\u65e0\u65e5\u5fd7'))
                          : ListView.builder(
                              itemCount: sorted.length,
                              itemBuilder: (ctx, i) => ListTile(
                                title: Text(_logTitle(sorted[i])),
                                subtitle: Text(_logDateLabel(sorted[i].date)),
                                onTap: () => _openLogEditor(sorted[i].id),
                              ),
                            ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = (screenWidth - AppSpacing.pagePadding * 2) / 7;
    final calendarHeight = cellSize * 7; // 1 weekday-header row + 6 date rows

    return AppShell(
      showAppBar: false,
      showBottomNav: false,
      currentNavIndex: 1,
      child: Stack(children: [
        // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?Year view: fades out (no scale = one fewer compositing op) 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
        FadeTransition(
          opacity: _yearExitOpacity,
          child: RepaintBoundary(
            child: IgnorePointer(
              ignoring: _pageTransCtrl.isCompleted,
              child: _buildYearView(),
            ),
          ),
        ),

        // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?Month view: scales up + fades in 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?
        FadeTransition(
          opacity: _monthEntryOpacity,
          child: ScaleTransition(
            scale: _monthEntryScale,
            child: RepaintBoundary(
              child: IgnorePointer(
                ignoring: _pageTransCtrl.isDismissed,
                child: _buildMonthViewArea(calendarHeight, cellSize),
              ),
            ),
          ),
        ),

        // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?subtle loading bar 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸
        if (_loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),

        // 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴?today button 闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍楣冩⒑閸愭彃甯ㄩ柛瀣崌閺屽秹宕楁径濠佸闂備礁鍟块崢婊堝磻閹剧粯鐓冮柛蹇擃槸娴滈箖姊洪崘鎻掑辅闁稿鎹囬弻宥夊礂婢跺﹣澹曢梻浣稿暱閸樻粓宕戦幘缁樼厓闁稿繐顦禍?
        Positioned(
          left: AppSpacing.md,
          bottom: AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
          child: FilledButton(
              onPressed: _goToday, child: const Text('\u4eca\u5929')),
        ),
      ]),
    );
  }
}
