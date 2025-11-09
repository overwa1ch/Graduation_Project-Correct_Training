# assets/ 目录依赖分析报告

**生成时间**: 2025-01-XX  
**最后更新**: 2025-01-XX（二次核查）  
**分析范围**: 根目录下的 `assets/` 目录及其所有子目录

## 执行摘要

经过全面扫描代码库，**确认根目录下的 `assets/` 目录可以安全删除**。所有引用都指向 `aiwa_app/assets/`，而非根目录的 `assets/`。

## 目录结构

```
assets/
├── C-test_and_examples/     # 测试样本和示例数据
├── sync_tool/               # Tokens 同步工具（已废弃）
├── build/                   # 构建输出（不应提交）
└── configs/                # 配置文件（未使用）
```

## 详细分析

### 1. `assets/C-test_and_examples/` - ✅ 可删除

**内容**:
- 测试样本（squat_normal, squat_occlusion, squat_short 等）
- 示例 JSON 文件
- Schema 定义（evidence_data_contract.json, result_C_augment.json）
- 规则文件（cue_advice_map.json）
- 工具脚本（compare_result.py）

**引用情况**:
- ❌ **代码引用**: 无
- ❌ **脚本引用**: 无
- ⚠️ **文档引用**: 
  - `docs/01-design/evidence_design.md` 提到 `configs/evidence_config.json`、`schemas/evidence_data_contract.json`、`rules/cue_advice_map.json`
  - 但这些是**相对路径引用**，文档位于 `docs/01-design/`，路径不明确指向 `assets/`
  - `assets/C-test_and_examples/squat_normal/README.md` 提到 `validate_examples.py`，但该脚本不存在

**结论**: 文档中的引用是**概念性引用**，不是实际文件路径。这些文件未被代码或脚本使用。

### 2. `assets/sync_tool/` - ✅ 可删除

**内容**:
- `sync_tokens.dart` - Tokens 同步脚本
- `README.md` - 使用说明
- `pubspec.yaml` 和 `pubspec.lock` - 依赖配置

**引用情况**:
- ❌ **代码引用**: 无
- ❌ **脚本引用**: 无
- ✅ **实际使用版本**: `aiwa_app/tool/sync_tokens.dart`（功能相同，已在使用）

**注意**: `assets/sync_tool/sync_tokens.dart` 中的 `assetsTokensPath = 'assets/tokens'` 是相对路径，期望在 `aiwa_app/` 目录下运行，引用的是 `aiwa_app/assets/tokens/`，而非根目录的 `assets/`。

**结论**: 这是废弃的副本，实际使用的是 `aiwa_app/tool/sync_tokens.dart`。

### 3. `assets/build/` - ✅ 可删除

**内容**:
- 测试运行结果（logs、frames、result.json 等）
- 性能报告（perf.json, perf_report.md）

**引用情况**:
- ❌ **代码引用**: 无
- ❌ **脚本引用**: 无
- ⚠️ **工具脚本**: `assets/C-test_and_examples/tools/compare_result.py` 使用相对路径 `build/offline_out/`，但该脚本本身未被使用

**结论**: 这是构建输出目录，**不应提交到版本控制**。应加入 `.gitignore`。

### 4. `assets/configs/` - ✅ 可删除

**内容**:
- `evidence_config.json`
- `evidence_config_debug.json`
- `hybrid_policy.json`

**引用情况**:
- ❌ **代码引用**: 无
- ❌ **脚本引用**: 无
- ⚠️ **文档引用**: 
  - `docs/01-design/hybrid_design.md` 提到 `hybrid_policy.json`（未指定路径）
  - `docs/01-design/evidence_design.md` 提到 `configs/evidence_config.json`（相对路径，不明确）

**结论**: 文档中的引用是**概念性引用**，不是实际文件路径。这些配置文件未被代码使用。

## 实际使用的 assets 目录

项目实际使用的是 **`aiwa_app/assets/`**，包含：
- `config/` - 角度配置文件（`angles_vB1.json`）
- `models/` - ML 模型文件（`movenet_lightning.tflite`, `movenet_thunder.tflite`）
- `rules/` - 规则文件（`squat.v1.json`）
- `tokens/` - 设计 tokens（由 `aiwa_app/tool/sync_tokens.dart` 同步）

**所有对 `assets/` 的代码引用都指向 `aiwa_app/assets/`**，而非根目录的 `assets/`。

## 文档引用说明

以下文档中的路径引用是**概念性引用**，不是实际文件路径：

1. `docs/01-design/evidence_design.md`:
   - `configs/evidence_config.json` - 概念性引用
   - `schemas/evidence_data_contract.json` - 概念性引用
   - `rules/cue_advice_map.json` - 概念性引用

2. `docs/01-design/hybrid_design.md`:
   - `hybrid_policy.json` - 概念性引用（未指定路径）

这些引用用于说明设计意图，不表示实际文件位置。

## 验证结果

### 代码搜索
- ✅ 搜索 `assets/C-test_and_examples` - 无匹配
- ✅ 搜索 `assets/sync_tool` - 无匹配
- ✅ 搜索 `assets/build` - 无匹配
- ✅ 搜索 `assets/configs` - 无匹配
- ✅ 搜索 `evidence_config.json` - 仅在文档中提及
- ✅ 搜索 `hybrid_policy.json` - 仅在文档中提及

### 脚本搜索
- ✅ 搜索所有 `.py` 文件 - 无引用
- ✅ 搜索所有 `.sh` 文件 - 无引用
- ✅ 搜索所有 `.ps1` 文件 - 无引用
- ✅ 搜索所有 `.bat` 文件 - 无引用

### 测试文件搜索
- ✅ `aiwa_app/test/e2e/complete_flow_test.dart` - 在临时目录中创建 `assets/config/`，不引用根目录的 `assets/`
- ✅ `aiwa_app/test/tokens_schema_test.dart` - 引用 `assets/tokens/`，但测试在 `aiwa_app/` 目录运行，指向 `aiwa_app/assets/tokens/`

### 构建配置搜索
- ✅ Dockerfile - 无引用
- ✅ docker-compose.yml - 无引用
- ✅ CI/CD 工作流 - 无配置文件

### 文档搜索
- ✅ 搜索所有 `.md` 文件 - 仅概念性引用，无实际路径引用
- ⚠️ `AGENTS.md` 和 `docs/00-project/agents.md` 提到 `assets/、docs/`，但这是目录结构说明，不是实际引用

## 建议操作

### 1. 删除整个 `assets/` 目录

```bash
# Windows PowerShell
Remove-Item -Recurse -Force assets

# Linux/macOS
rm -rf assets/
```

### 2. 更新 `.gitignore`（如果尚未包含）

```gitignore
# 构建输出（如果将来需要）
assets/build/
```

### 3. 更新文档中的目录结构说明

删除 `assets/` 后，需要更新以下文档：
- `AGENTS.md` (第 75 行) - 删除 `assets/、docs/` 中的 `assets/`
- `docs/00-project/agents.md` (第 75 行) - 相同更新

### 4. 可选：归档重要文档

如果需要保留作为参考，可以：
- 将 `assets/C-test_and_examples/` 移动到 `docs/archive/test_examples/`
- 将 `assets/configs/` 移动到 `docs/archive/configs/`

## 额外发现

### 测试文件中的路径

以下测试文件使用了 `assets/` 路径，但**不引用根目录的 `assets/`**：

1. **`aiwa_app/test/e2e/complete_flow_test.dart`** (第 34, 50 行):
   ```dart
   await Directory('assets/config').create(recursive: true);
   await File('assets/config/default_config.json').writeAsString(...);
   ```
   - **上下文**: 测试会改变工作目录到临时目录（`Directory.current = tempDir.path`）
   - **结论**: 这些路径是相对于临时测试目录的，不引用根目录的 `assets/`

2. **`aiwa_app/test/tokens_schema_test.dart`** (第 136 行):
   ```dart
   final assetsColors = File('assets/tokens/colors.json');
   ```
   - **上下文**: 测试在 `aiwa_app/` 目录下运行
   - **结论**: 引用的是 `aiwa_app/assets/tokens/`，不是根目录的 `assets/`

### 文档中的目录结构说明

以下文档提到了 `assets/`，但只是**目录结构说明**，不是实际引用：

- `AGENTS.md` (第 75 行): `├── assets/、docs/            # 设计资产与说明文档`
- `docs/00-project/agents.md` (第 75 行): 相同内容

这些只是项目结构描述，删除根目录的 `assets/` 后需要更新这些文档。

## 风险评估

**风险等级**: 🟢 **低风险**

- ✅ 无代码依赖
- ✅ 无脚本依赖
- ✅ 无构建配置依赖
- ✅ 测试文件中的路径不引用根目录的 `assets/`
- ✅ 文档引用仅为概念性引用或结构说明
- ✅ 有实际使用的替代版本（`aiwa_app/tool/sync_tokens.dart`）
- ⚠️ 需要更新 `AGENTS.md` 和 `docs/00-project/agents.md` 中的目录结构说明

## 结论

**根目录下的 `assets/` 目录可以安全删除**。所有实际使用的资源都在 `aiwa_app/assets/` 目录下，根目录的 `assets/` 是历史遗留的未使用文件。

---

**报告生成工具**: Cursor AI  
**验证方法**: 全代码库搜索、文档扫描、路径分析

