/// UTC 时间范围查询参数（闭区间 [fromUtc, toUtc]）。
///
/// fromUtc / toUtc 必须是 UTC；否则 UseCase 应抛
/// ApplicationException(INVALID_UTC_RANGE)。
class UtcRangeQuery {
  final DateTime fromUtc;
  final DateTime toUtc;
  final int? limit;
  final int? offset;

  const UtcRangeQuery({
    required this.fromUtc,
    required this.toUtc,
    this.limit,
    this.offset,
  });
}
