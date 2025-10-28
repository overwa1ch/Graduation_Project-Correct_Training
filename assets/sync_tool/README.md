# Tokens 同步脚本

## 功能

实现 "Tokens 同步与只读副本策略"，确保设计 Tokens 的一致性和安全性。

### 核心特性

1. **双副本策略**
   - `lib/theme/tokens/` - 开发期源文件（可由 MCP/AI 更新）
   - `assets/tokens/` - 运行期只读副本（打包进 App）

2. **事务式同步**
   - 拉取 → 验证 → 测试 → 落地
   - 测试通过才覆盖，失败自动回滚

3. **完整验证**
   - JSON Schema 验证
   - 结构完整性检查
   - 自动化测试验证

4. **安全保障**
   - 原子更新（全部成功或全部失败）
   - 自动备份与恢复
   - 详细的变更报告

## 安装

```bash
cd tool
dart pub get
```

## 使用方法

### 1. 从 Figma MCP 同步（推荐）

```bash
# 设置环境变量
export FIGMA_TOKEN=your_figma_token
export FIGMA_FILE_KEY=q3hgTOdVGt42WkOfDixtsp

# 运行同步
dart tool/sync_tokens.dart
```

**注意**：由于 Dart 脚本无法直接调用 MCP，请先使用 Cursor/AI 更新 `lib/theme/tokens/`，然后运行此脚本同步到 `assets/`。

### 2. 从本地目录同步

```bash
dart tool/sync_tokens.dart --tokens-dir=/path/to/tokens
```

### 3. 预演模式（不修改文件）

```bash
dart tool/sync_tokens.dart --dry-run
```

### 4. 详细日志

```bash
dart tool/sync_tokens.dart --verbose
```

### 5. 组合使用

```bash
dart tool/sync_tokens.dart --tokens-dir=./backup/tokens --dry-run --verbose
```

## 命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--tokens-dir=PATH` | 从本地目录读取 Tokens | - |
| `--dry-run` | 预演模式，不修改文件 | false |
| `--verbose` | 输出详细日志 | false |
| `--no-fail-fast` | 出错后继续执行 | false |

## 环境变量

| 变量 | 说明 | 必需 |
|------|------|------|
| `FIGMA_TOKEN` | Figma API Token | 使用 MCP 时必需 |
| `FIGMA_FILE_KEY` | Figma 文件 ID | 使用 MCP 时必需 |
| `FIGMA_PAGE` | Figma 页面名称 | 可选 |

## 工作流程

```
┌─────────────────┐
│  1. 拉取 Tokens  │
│  - MCP / 本地   │
│  - 写入临时目录  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. 验证结构    │
│  - JSON Schema  │
│  - 字段完整性   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. 计算变更    │
│  - SHA256 哈希  │
│  - 文件对比     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. 预演模式？  │
│  - 是：退出     │
│  - 否：继续     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. 运行测试    │
│  - 临时替换文件 │
│  - flutter test │
│  - 自动回滚     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  6. 原子更新    │
│  - lib/theme/   │
│  - assets/      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  7. 生成报告    │
│  - 变更摘要     │
│  - 测试结果     │
│  - 文件清单     │
└─────────────────┘
```

## 文件结构

```
lib/theme/tokens/           # 源文件（开发期可改）
├── colors.json
├── typography.json
├── spacing.json
└── radius.json

assets/tokens/              # 只读副本（打包进 App）
├── colors.json
├── typography.json
├── spacing.json
└── radius.json

.tmp/                       # 临时目录（自动清理）
├── tokens/                 # 拉取的新 Tokens
└── backup/                 # 测试期备份

SYNC_TOKENS_REPORT.md       # 同步报告
```

## 验证规则

### colors.json
- 必需字段：`brand`, `surface`, `text`, `error`
- 颜色格式：`#RRGGBB`（6 位十六进制）

### typography.json
- 必需字段：`fontFamily`, `styles`
- 必需样式：`h1`, `h2`, `bodyBase`, `button`
- 每个样式必需：`fontSize`, `fontWeight`
- `letterSpacing` 允许负值

### spacing.json
- 必需字段：`spacing`, `padding`, `gap`
- 所有数值必须非负

### radius.json
- 必需字段：`radius`, `borderRadius`
- 所有数值必须非负

## 错误处理

### 缺少环境变量
```
❌ 同步失败: 缺少 Tokens 来源！
请设置环境变量：
  FIGMA_TOKEN=your_token
  FIGMA_FILE_KEY=your_file_key
或使用本地目录：
  --tokens-dir=/path/to/tokens
```

### JSON 验证失败
```
❌ 同步失败: colors.json 验证失败: 缺少必需字段: brand
```

### 测试失败
```
❌ 同步失败: 测试失败 (2/31):
test/theme_test.dart: Brand colors should match Figma tokens [E]
test/theme_test.dart: Surface colors should match Figma tokens [E]
```

## 示例输出

### 成功同步

```
============================================================
🔄 AIWA Tokens 同步
============================================================
模式: 正式同步

📥 拉取 Tokens
------------------------------------------------------------
从本地目录拉取: lib/theme/tokens
  ✓ colors.json
  ✓ typography.json
  ✓ spacing.json
  ✓ radius.json

✅ 验证 Tokens
------------------------------------------------------------
验证 colors.json...
  ✓ colors.json 结构正确
验证 typography.json...
  ✓ typography.json 结构正确
验证 spacing.json...
  ✓ spacing.json 结构正确
验证 radius.json...
  ✓ radius.json 结构正确

📊 计算变更
------------------------------------------------------------
📝 colors.json: 439 → 445 bytes (modified)
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

### 预演模式

```
============================================================
🔄 AIWA Tokens 同步
============================================================
模式: 预演 (dry-run)

📥 拉取 Tokens
------------------------------------------------------------
从本地目录拉取: lib/theme/tokens

✅ 验证 Tokens
------------------------------------------------------------
所有文件验证通过

📊 计算变更
------------------------------------------------------------
📝 colors.json: 439 → 445 bytes (modified)
  旧哈希: a1b2c3d4...
  新哈希: e5f6g7h8...

✅ 预演完成，未修改任何文件
```

## CI/CD 集成

### GitHub Actions

```yaml
name: Sync Tokens

on:
  workflow_dispatch:
  schedule:
    - cron: '0 0 * * *'  # 每天同步

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      
      - name: Install dependencies
        run: |
          cd tool
          dart pub get
      
      - name: Sync tokens
        env:
          FIGMA_TOKEN: ${{ secrets.FIGMA_TOKEN }}
          FIGMA_FILE_KEY: ${{ secrets.FIGMA_FILE_KEY }}
        run: dart tool/sync_tokens.dart
      
      - name: Commit changes
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add assets/tokens/ SYNC_TOKENS_REPORT.md
          git commit -m "chore: sync tokens from Figma" || echo "No changes"
          git push
```

## 最佳实践

1. **定期同步**：建议每周或每次设计更新后同步
2. **先预演**：使用 `--dry-run` 查看变更再正式同步
3. **版本控制**：将 `SYNC_TOKENS_REPORT.md` 纳入版本控制
4. **自动化**：在 CI/CD 中集成自动同步
5. **备份**：重要更新前手动备份 `lib/theme/tokens/`

## 故障排查

### 问题：flutter 命令不存在
**解决**：安装 Flutter SDK 或在 CI 中跳过测试

### 问题：测试失败但 Tokens 正确
**解决**：检查 `test/theme_test.dart` 是否需要更新

### 问题：权限错误
**解决**：确保脚本有读写权限：`chmod +x tool/sync_tokens.dart`

### 问题：MCP 无法调用
**解决**：先用 Cursor/AI 更新 `lib/theme/tokens/`，再运行脚本

## 维护

- **版本**：1.0.0
- **作者**：AIWA Team
- **更新日期**：2025-10-26
- **依赖**：crypto ^3.0.3, path ^1.8.3

## 许可

与主项目保持一致

