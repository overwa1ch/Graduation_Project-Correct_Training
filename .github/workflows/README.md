# GitHub Actions CI/CD 配置

## 工作流概览

### 1. `flutter-ci.yml` - 主 CI 流水线

**触发条件：**
- Push 到 `main`/`master`/`develop` 分支
- 创建或更新 Pull Request
- 手动触发 (workflow_dispatch)

**包含的 Jobs：**

| Job | 描述 | 超时 |
|-----|------|------|
| 📊 Static Analysis | Flutter analyze (0 警告) | 10 分钟 |
| 🧪 Unit Tests | 所有单元测试 + 覆盖率 | 15 分钟 |
| 🎨 Theme Tests | 主题映射测试 (31 tests) | 10 分钟 |
| 📝 Tokens Schema Tests | Tokens 结构验证 (8 tests) | 10 分钟 |
| 🖼️ Widget Tests | Widget 冒烟测试 | 10 分钟 |
| 🔄 Tokens Sync | Tokens 同步验证 | 10 分钟 |
| 🏗️ Build Validation | APK 构建验证 | 15 分钟 |
| 📋 Final Report | 最终验收报告 | 5 分钟 |

**CI 门槛：**
- ✅ `flutter analyze` 必须 0 警告
- ✅ 所有测试必须 100% 通过
- ✅ Tokens 必须同步
- ✅ 构建必须成功
- ❌ 任一失败即阻止合并

### 2. `tokens-sync-check.yml` - Tokens 同步检查

**触发条件：**
- Tokens 文件被修改时
- 手动触发

**功能：**
- 验证 `lib/theme/tokens/` 和 `assets/tokens/` 同步
- 运行 sync_tokens.dart 验证
- 文件内容对比

## 使用方法

### 本地开发流程

```bash
# 1. 创建新分支
git checkout -b feature/my-feature

# 2. 进行开发
# ... 修改代码 ...

# 3. 运行本地测试（CI 会运行的所有检查）
cd aiwa_app

# 静态分析
flutter analyze

# 所有测试
flutter test

# 主题测试
flutter test test/theme_test.dart

# Schema 测试
flutter test test/tokens_schema_test.dart

# Widget 测试
flutter test test/widget_test.dart

# 4. 如果修改了 Tokens，同步到 assets
dart tool/sync_tokens.dart

# 5. 提交代码
git add .
git commit -m "feat: add new feature"
git push origin feature/my-feature

# 6. 创建 Pull Request
# CI 会自动运行所有检查
```

### Pull Request 流程

1. **创建 PR**
   - 填写 PR 模板
   - 描述改动内容
   - 勾选相关检查项

2. **等待 CI 完成**
   - 查看 GitHub Actions 标签页
   - 确保所有检查通过（绿色 ✅）

3. **修复问题（如有）**
   ```bash
   # 查看 CI 日志找出问题
   # 修复后重新提交
   git add .
   git commit -m "fix: resolve CI issues"
   git push
   ```

4. **合并 PR**
   - 所有检查通过后
   - 获得代码审查批准
   - 点击 "Merge" 按钮

### 手动触发 CI

1. 进入 GitHub Actions 页面
2. 选择工作流
3. 点击 "Run workflow"
4. 选择分支
5. 点击 "Run workflow" 按钮

## CI 输出示例

### ✅ 成功输出

```
============================================================
           AIWA APP - CI/CD VALIDATION REPORT
============================================================

📊 Static Analysis:        success
🧪 Unit Tests:             success
🎨 Theme Tests:            success
📝 Tokens Schema Tests:    success
🖼️  Widget Tests:          success
🔄 Tokens Sync:            success
🏗️  Build Validation:      success

============================================================

🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉

   ✅ All theme & tokens tests passed!

   • Static analysis: 0 warnings
   • Unit tests: 100% passed
   • Theme tests: 31/31 passed
   • Schema tests: 8/8 passed
   • Widget tests: All passed
   • Tokens sync: Validated
   • Build: Success

   Ready to merge! 🚀

🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉🎉
```

### ❌ 失败输出

```
============================================================
           AIWA APP - CI/CD VALIDATION REPORT
============================================================

📊 Static Analysis:        success
🧪 Unit Tests:             failure
🎨 Theme Tests:            success
📝 Tokens Schema Tests:    failure
🖼️  Widget Tests:          success
🔄 Tokens Sync:            success
🏗️  Build Validation:      skipped

============================================================

❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌

   ❌ CI validation failed!

   Please fix the following issues:

   • Unit tests failed
   • Tokens schema tests failed

   Cannot merge until all checks pass.

❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌
```

## 常见问题

### Q: CI 失败了怎么办？

1. **查看日志**
   - 点击失败的 Job
   - 查看详细错误信息

2. **本地复现**
   ```bash
   # 运行相同的命令
   flutter analyze
   flutter test
   ```

3. **修复并重新提交**
   ```bash
   git add .
   git commit -m "fix: resolve CI issues"
   git push
   ```

### Q: 如何跳过 CI？

**不建议跳过 CI！** 但如果确实需要：

```bash
git commit -m "docs: update README [skip ci]"
```

### Q: CI 运行太慢？

- 使用 cache 加速（已配置）
- 并发运行多个 Jobs（已配置）
- 只在必要时触发（已配置 paths 过滤）

### Q: 如何添加新的测试？

1. 在 `aiwa_app/test/` 中添加测试文件
2. CI 会自动运行所有测试
3. 无需修改 CI 配置

### Q: 如何更新 Flutter 版本？

修改 `.github/workflows/flutter-ci.yml`:

```yaml
- name: 🔧 Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'  # 修改这里
    channel: 'stable'
```

## 最佳实践

1. **提交前本地测试**
   ```bash
   flutter analyze && flutter test
   ```

2. **小步提交**
   - 每个 PR 专注一个功能
   - 更容易通过 CI

3. **及时修复**
   - CI 失败立即修复
   - 不要积累问题

4. **查看覆盖率**
   - Codecov 报告
   - 保持高覆盖率

5. **遵循规范**
   - 使用 PR 模板
   - 填写完整信息

## 维护

### 更新依赖

```yaml
# 定期更新 GitHub Actions
uses: actions/checkout@v4  # 检查最新版本
uses: subosito/flutter-action@v2
uses: dart-lang/setup-dart@v1
uses: codecov/codecov-action@v4
```

### 监控性能

- 查看 Actions 使用时间
- 优化慢速 Jobs
- 使用 cache 加速

### 安全性

- 不在 CI 中暴露敏感信息
- 使用 GitHub Secrets 存储密钥
- 定期审查权限

## 相关文档

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)
- [项目测试文档](../../aiwa_app/test/README.md)
- [Tokens 同步文档](../../aiwa_app/tool/README.md)

