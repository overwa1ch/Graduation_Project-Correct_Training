# Tokens 同步脚本 - 快速开始

## 安装

```bash
cd tool
dart pub get
```

## 使用场景

### 场景 1: 从 Figma 更新后同步到 assets

1. 使用 Cursor/AI 通过 MCP 更新 `lib/theme/tokens/`
2. 运行同步脚本：

```bash
cd aiwa_app
dart tool/sync_tokens.dart
```

### 场景 2: 预览变更（不修改文件）

```bash
dart tool/sync_tokens.dart --dry-run
```

### 场景 3: 从备份恢复

```bash
dart tool/sync_tokens.dart --tokens-dir=/path/to/backup
```

### 场景 4: 详细日志

```bash
dart tool/sync_tokens.dart --verbose
```

## 工作流程

```
1. MCP 更新 lib/theme/tokens/
   ↓
2. 运行 dart tool/sync_tokens.dart
   ↓
3. 脚本验证 JSON 结构
   ↓
4. 脚本运行测试 (flutter test)
   ↓
5. 测试通过后同步到 assets/tokens/
   ↓
6. 生成 SYNC_TOKENS_REPORT.md
```

## 输出示例

```
============================================================
🔄 AIWA Tokens 同步
============================================================
模式: 正式同步

📥 拉取 Tokens
------------------------------------------------------------
从现有 lib/theme/tokens/ 拉取

✅ 验证 Tokens
------------------------------------------------------------
验证 colors.json...
验证 typography.json...
验证 spacing.json...
验证 radius.json...

📊 计算变更
------------------------------------------------------------
📝 colors.json: 439 → 441 bytes (modified)
📋 无变更

🧪 运行测试
------------------------------------------------------------
运行 flutter test test/theme_test.dart...
✓ 测试通过 (31 个测试)

💾 更新文件
------------------------------------------------------------
✓ 更新 lib/theme/tokens
✓ 更新 assets/tokens

📝 生成报告
------------------------------------------------------------
✓ 生成报告: SYNC_TOKENS_REPORT.md

✅ 同步完成！
```

## 常见问题

### Q: 为什么不能直接从 MCP 拉取？
A: Dart 脚本无法直接调用 MCP。请先用 Cursor/AI 更新 `lib/theme/tokens/`，再运行脚本同步。

### Q: 测试失败怎么办？
A: 脚本会自动回滚，不会覆盖现有文件。检查 tokens 是否正确，或更新测试用例。

### Q: 如何在 CI/CD 中使用？
A: 参考 `tool/README.md` 中的 GitHub Actions 示例。

## 文件结构

```
lib/theme/tokens/      # 源文件（开发期可改）
assets/tokens/         # 只读副本（打包进 App）
SYNC_TOKENS_REPORT.md  # 同步报告
```

## 更多信息

详细文档请参考 `tool/README.md`

