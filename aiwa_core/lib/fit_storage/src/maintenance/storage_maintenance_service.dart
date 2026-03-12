import 'dart:io';

import 'package:path/path.dart' as p;

import '../db/fit_database.dart';
import '../db/fit_storage_paths.dart';

/// 修复模式（Maintenance/Integrity V1.1+）。
enum RepairMode {
  /// 仅报告，不修改。
  dryRun,

  /// 删除"索引存在但文件缺失"的 attachment rows。
  deleteBrokenIndexRows,
}

/// 完整性检查报告（Maintenance/Integrity V1.1+）。
class IntegrityReport {
  /// 索引存在但文件缺失的 attachment IDs。
  final List<String> missingFiles;

  /// relative_path 不符合规则的 attachment IDs。
  final List<String> relativePathViolations;

  const IntegrityReport({
    required this.missingFiles,
    required this.relativePathViolations,
  });
}

/// 修复报告（Maintenance/Integrity V1.1+）。
class RepairReport {
  final RepairMode mode;

  /// 已删除的索引行 IDs（dryRun 模式下为空列表）。
  final List<String> deletedIndexRows;

  const RepairReport({
    required this.mode,
    required this.deletedIndexRows,
  });
}

/// 存储维护服务（Maintenance/Integrity V1.1+）。
///
/// 提供索引与文件一致性检查、修复功能。
class StorageMaintenanceService {
  final FitDatabase db;
  final FitStoragePaths paths;

  const StorageMaintenanceService({required this.db, required this.paths});

  /// 检查完整性。
  ///
  /// 返回 [IntegrityReport]，包含：
  /// - missingFiles: attachments 表中存在但文件不存在的行
  /// - relativePathViolations: relative_path 不符合规则的行
  Future<IntegrityReport> checkIntegrity() async {
    final allRows = await db.select(db.attachments).get();

    final missingFiles = <String>[];
    final relativePathViolations = <String>[];

    for (final row in allRows) {
      // Check file existence
      final objectFile = File(p.join(paths.rootDir.path, row.relativePath));
      if (!await objectFile.exists()) {
        missingFiles.add(row.id);
      }

      // Check relative_path rule
      if (!_isValidRelativePath(row.relativePath)) {
        relativePathViolations.add(row.id);
      }
    }

    return IntegrityReport(
      missingFiles: missingFiles,
      relativePathViolations: relativePathViolations,
    );
  }

  /// 执行修复。
  ///
  /// [mode] 为 [RepairMode.dryRun] 时只报告不修改。
  /// [mode] 为 [RepairMode.deleteBrokenIndexRows] 时删除 missingFiles 对应的行。
  ///
  /// 操作幂等：重复调用不会产生副作用。
  Future<RepairReport> repair({required RepairMode mode}) async {
    final report = await checkIntegrity();
    final deletedIndexRows = <String>[];

    if (mode == RepairMode.deleteBrokenIndexRows) {
      for (final attachmentId in report.missingFiles) {
        try {
          await (db.delete(db.attachments)
                ..where((t) => t.id.equals(attachmentId)))
              .go();
          deletedIndexRows.add(attachmentId);
        } catch (_) {
          // Best-effort: continue with other deletions
        }
      }
    }

    return RepairReport(
      mode: mode,
      deletedIndexRows: deletedIndexRows,
    );
  }

  /// 验证 relative_path 是否符合规则（与 media_store._assertRelativePath 一致）。
  ///
  /// 规则：
  /// - 必须是相对路径（不能是绝对路径）
  /// - 不能包含驱动器冒号（Windows）
  /// - 不能以 / 或 \ 开头
  bool _isValidRelativePath(String value) {
    final hasDriveColon = value.contains(':');
    final startsWithRootSlash = value.startsWith('/') || value.startsWith('\\');
    return !p.isAbsolute(value) && !hasDriveColon && !startsWithRootSlash;
  }
}
