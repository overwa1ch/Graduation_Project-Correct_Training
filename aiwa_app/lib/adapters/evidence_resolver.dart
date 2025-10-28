// evidence_resolver.dart
// Version: v2.0
// Purpose: 证据降级策略解析器
//
// 契约依据：
// - docs/protocols/schemas/analysis_result_v2.schema.json
// - docs/protocols/ui_contracts.md (证据降级策略)
//
// 降级策略优先级：
// 1. snapshotPath (快照路径)
// 2. window (时间窗: startMs, endMs)
// 3. null (无证据)
//
// 使用示例：
// ```dart
// final raw = await readResultJson(sessionRoot);
//
// // 优先获取快照路径
// final snapshot = resolveSnapshotPath(raw);
// if (snapshot != null) {
//   showSnapshot(snapshot);
// } else {
//   // 降级到时间窗
//   final window = resolveEvidenceWindow(raw);
//   if (window != null) {
//     playbackSegment(window.startMs, window.endMs);
//   } else {
//     showPlaceholder();
//   }
// }
// ```

// ============================================================================
// 公开接口 1: 解析快照路径
// ============================================================================

/// 解析证据快照路径（优先级最高）
///
/// 规则（参见 docs/protocols/ui_contracts.md 证据降级策略）：
/// - 若 evidence 缺失/空 → null
/// - 若 evidence[0].snapshotPath 为空/全空白 → null
/// - 否则返回 snapshotPath（保持原始相对路径）
///
/// 参数:
/// - [raw]: 原始 result.json Map
///
/// 返回: 快照路径（相对于 sessionRoot）或 null
///
/// 注意:
/// - 不抛异常（降级策略）
/// - 返回的路径是相对路径（例如: "evidence/frame_612.jpg"）
/// - 路径拼接应在 UI 层完成
String? resolveSnapshotPath(Map<String, dynamic> raw) {
  // 检查 evidence 数组
  if (!raw.containsKey('evidence') || raw['evidence'] is! List) {
    return null;
  }

  final evidence = raw['evidence'] as List;
  if (evidence.isEmpty) {
    return null;
  }

  // 获取第一个证据项
  final first = evidence[0];
  if (first is! Map) {
    return null;
  }

  // 检查 snapshotPath
  final snapshot = first['snapshotPath'];
  if (snapshot is! String || snapshot.trim().isEmpty) {
    return null;
  }

  return snapshot.trim();
}

// ============================================================================
// 公开接口 2: 解析证据时间窗
// ============================================================================

/// 解析证据时间窗（优先级次于 snapshotPath）
///
/// 规则：
/// - 若 evidence 缺失/空 → null
/// - 若 evidence[0].window.startMs 或 endMs 缺失 → null
/// - 若 endMs <= startMs → null（非法窗口）
/// - 若 startMs < 0 → null（非法时间）
/// - 否则返回 (startMs, endMs)
///
/// 参数:
/// - [raw]: 原始 result.json Map
///
/// 返回: 时间窗记录 (startMs, endMs) 或 null
///
/// 注意:
/// - 不抛异常（降级策略）
/// - 时间单位: 毫秒（ms）
/// - 用于视频回放片段定位
({int startMs, int endMs})? resolveEvidenceWindow(Map<String, dynamic> raw) {
  // 检查 evidence 数组
  if (!raw.containsKey('evidence') || raw['evidence'] is! List) {
    return null;
  }

  final evidence = raw['evidence'] as List;
  if (evidence.isEmpty) {
    return null;
  }

  // 获取第一个证据项
  final first = evidence[0];
  if (first is! Map) {
    return null;
  }

  // 检查 window 对象
  if (!first.containsKey('window') || first['window'] is! Map) {
    return null;
  }

  final window = first['window'] as Map<String, dynamic>;

  // 检查 startMs
  if (!window.containsKey('startMs') || window['startMs'] is! num) {
    return null;
  }

  // 检查 endMs
  if (!window.containsKey('endMs') || window['endMs'] is! num) {
    return null;
  }

  final startMs = (window['startMs'] as num).round();
  final endMs = (window['endMs'] as num).round();

  // 校验合法性
  if (startMs < 0) {
    return null; // 时间不能为负
  }

  if (endMs <= startMs) {
    return null; // 结束时间必须大于开始时间
  }

  return (startMs: startMs, endMs: endMs);
}

