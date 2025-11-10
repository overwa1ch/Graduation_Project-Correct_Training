# 代码漂移检测工具

本目录包含用于检测代码漂移的自动化工具。

## 📋 工具列表

### 1. `check_drift.dart` - 代码漂移快速扫描

**目的**：检测 `aiwa_app` 中是否重新实现了 `aiwa_core` 已有的功能。

**运行方式**：
```bash
dart scripts/check_drift.dart
```

**检测内容**：
- 角度计算、平滑算法、计数逻辑
- 质量评估、Schema 验证
- 关键点名称常量、结果模型解析

**输出**：
- 如果发现问题，会列出可疑文件和关键词
- 如果未发现问题，返回成功退出码

**使用场景**：
- 完成功能实现后运行检查
- 提交代码前验证
- 定期审计代码库

---

## 💡 使用建议

### 开发流程

1. **实现功能前**：查阅 `docs/00-project/ARCHITECTURE_BOUNDARIES.md`
2. **实现功能后**：运行 `dart scripts/check_drift.dart`
3. **发现问题时**：使用 `docs/00-project/AI_CODE_REVIEW_PROMPT.md` 让 AI 详细检查

### 集成到工作流

**手动运行**（推荐）：
```bash
# 完成功能后运行
dart scripts/check_drift.dart
```

**IDE 集成**：
- 在 VS Code 中创建任务（`.vscode/tasks.json`）
- 在 Android Studio 中配置运行配置

---

## 🔗 相关文档

- [架构边界决策规则](../docs/00-project/ARCHITECTURE_BOUNDARIES.md)
- [AI 代码检查提示词](../docs/00-project/AI_CODE_REVIEW_PROMPT.md)
- [合约回归测试](../aiwa_app/test/integration/core_contract_test.dart)

