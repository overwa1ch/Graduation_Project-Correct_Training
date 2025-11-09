// lib/services/cancellation_token.dart
//
// CancellationToken - 统一取消令牌实现
//
// 用途：
// - 在分析任务的所有层中共享取消状态
// - 提供统一的取消检查点
// - 为后续原生层集成（Phase 2）做准备
//
// 使用示例：
// ```dart
// final token = CancellationToken(id: 'session_123', sessionId: 'session_123');
// 
// // 在任务中检查
// if (token.isCancelling) {
//   return; // 提前退出
// }
//
// // 取消任务
// token.cancel();
// ```

/// 取消令牌 - 用于跨层统一取消机制
class CancellationToken {
  /// 令牌唯一标识（通常等于 sessionId）
  final String id;
  
  /// 关联的会话 ID
  final String sessionId;
  
  /// 内部取消标志（使用私有字段保证封装）
  bool _isCancelling = false;
  
  /// 获取取消状态
  /// 
  /// 返回 true 表示任务已被标记为取消，应该尽快退出
  bool get isCancelling => _isCancelling;
  
  /// 创建取消令牌
  CancellationToken({
    required this.id,
    required this.sessionId,
  });
  
  /// 标记任务为取消状态
  /// 
  /// 调用后，所有检查 `isCancelling` 的地方都会返回 true
  /// 此操作不可逆（一旦取消，无法恢复）
  void cancel() {
    _isCancelling = true;
  }
  
  @override
  String toString() => 'CancellationToken(id=$id, sessionId=$sessionId, isCancelling=$_isCancelling)';
}

