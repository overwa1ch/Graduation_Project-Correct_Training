import 'package:aiwa_core/fit_domain/fit_domain.dart';

/// 日期范围查询参数（闭区间 [from, to]）。
///
/// 若 from > to，UseCase 应抛 ApplicationException(INVALID_RANGE)。
class DateRangeQuery {
  final DateOnly from;
  final DateOnly to;
  final int? limit;
  final int? offset;

  const DateRangeQuery({
    required this.from,
    required this.to,
    this.limit,
    this.offset,
  });
}
