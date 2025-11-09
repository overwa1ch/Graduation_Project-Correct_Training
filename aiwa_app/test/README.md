# AIWA App 测试目录

本文档说明测试目录的组织结构、分类方式和测试规范。

## 📁 目录结构

```
test/
├── adapters/          # 适配器层测试（数据转换、适配）
├── services/          # 服务层测试（业务逻辑、核心功能）
├── ui/               # UI 层测试（页面、组件、交互）
├── theme/            # 主题层测试（样式、设计令牌）
├── e2e/              # 端到端测试（完整用户流程）
├── performance/       # 性能测试（基准测试、性能分析）
├── helpers/          # 测试辅助工具（Mock、Fake 数据）
├── fixtures/         # 测试数据文件（JSON、JSONL、示例数据）
├── test_helpers.dart # 统一测试基础设施
└── README.md         # 本文档
```

## 📂 分类说明

### 1. `adapters/` - 适配器层测试

**职责**：测试数据适配和转换逻辑

**测试内容**：
- 数据格式转换（如 JSON → Dart 对象）
- 数据验证和契约检查
- 错误处理和降级策略

**文件列表**：
- `result_adapter_test.dart` - 结果数据适配器测试
- `evidence_resolver_test.dart` - 证据解析器测试

**命名规范**：`{adapter_name}_test.dart`

**示例**：
```dart
// result_adapter_test.dart
// 单元测试：result_adapter.dart 与 evidence_resolver.dart
// 验收条件（DoD）：
// 1. happy path: 完整 result.json 正确映射
// 2. snapshot 缺失: 降级到 window
// 3. scores 缺字段: 抛 SchemaMismatch
```

---

### 2. `services/` - 服务层测试

**职责**：测试核心业务逻辑和服务功能

**测试内容**：
- 服务的基本功能
- 边界情况和错误处理
- 集成测试（多个服务协作）

**文件列表**：
- `config_sync_test.dart` 系列 - 配置同步服务
  - `config_sync_edge_test.dart` - 边界情况测试
  - `config_sync_merge_test.dart` - 配置合并测试
- `event_bus_test.dart` 系列 - 事件总线服务
  - `event_bus_basic_test.dart` - 基本功能测试
  - `event_bus_boundary_test.dart` - 边界情况测试
  - `event_bus_jsonl_test.dart` - JSONL 特定功能测试
- `session_manager_test.dart` 系列 - 会话管理
  - `session_manager_test.dart` - 基本功能测试
  - `session_manager_boundary_test.dart` - 边界情况测试
- `services_integration_test.dart` - 服务集成测试
- `diagnostics_logger_test.dart` - 诊断日志服务
- `support_bundle_test.dart` - 支持包服务

**命名规范**：
- 基本功能：`{service_name}_test.dart`
- 边界情况：`{service_name}_boundary_test.dart`
- 特定功能：`{service_name}_{feature}_test.dart`
- 集成测试：`services_integration_test.dart`

**测试分类原则**：
- **基本测试**：覆盖主要功能路径（Happy Path）
- **边界测试**：覆盖边界条件、错误处理、异常情况
- **特定功能测试**：针对某个特定功能或场景的深入测试
- **集成测试**：测试多个服务之间的协作

---

### 3. `ui/` - UI 层测试

**职责**：测试用户界面和交互逻辑

**测试内容**：
- Widget 渲染和显示
- 用户交互（点击、输入、导航）
- 状态管理和更新
- 错误处理和加载状态

**文件列表**：
- **页面测试**：
  - `widget_test.dart` - 应用入口和导航测试
  - `welcome_page_test.dart` - 欢迎页测试
  - `home_page_test.dart` - 主页测试
  - `camera_page_*.dart` - 相机页测试（多个文件）
    - `camera_page_flow_test.dart` - 流程测试
    - `camera_page_state_test.dart` - 状态测试
    - `camera_page_error_loading_test.dart` - 错误和加载状态测试
  - `result_popup_page_test.dart` - 结果弹窗页测试
  - `result_popup_view_test.dart` - 结果视图测试
  - `settings_page_form_test.dart` - 设置页表单测试
  - `app_shell_test.dart` - 应用外壳测试
- **组件测试**（`widgets/` 子目录）：
  - `score_card_test.dart` - 分数卡片组件
  - `evidence_frame_card_test.dart` - 证据帧卡片组件
  - `angle_line_chart_test.dart` - 角度折线图组件
- **UI 规范测试**：
  - `ui_semantic_color_test.dart` - 语义颜色使用规范测试

**命名规范**：
- 页面测试：`{page_name}_test.dart` 或 `{page_name}_{aspect}_test.dart`
- 组件测试：`{widget_name}_test.dart`
- 规范测试：`ui_{aspect}_test.dart`

---

### 4. `theme/` - 主题层测试

**职责**：测试主题、样式和设计令牌

**测试内容**：
- 主题创建和配置
- 设计令牌（颜色、字体、间距、圆角）
- 主题边界检查（确保不包含业务逻辑）

**文件列表**：
- `theme_test.dart` - 主题基本功能测试
- `theme_boundary_test.dart` - 主题边界测试（确保无业务逻辑）
- `tokens_schema_test.dart` - 设计令牌 Schema 验证

**命名规范**：`{aspect}_test.dart` 或 `{aspect}_boundary_test.dart`

---

### 5. `e2e/` - 端到端测试

**职责**：测试完整的用户流程

**测试内容**：
- 从用户操作到结果展示的完整流程
- 跨多个页面的交互
- 真实场景模拟

**文件列表**：
- `complete_flow_test.dart` - 完整流程测试（配置 → 捕获 → 结果）

**命名规范**：`{flow_name}_test.dart` 或 `complete_flow_test.dart`

---

### 6. `performance/` - 性能测试

**职责**：性能基准测试和分析

**测试内容**：
- 性能基准测试
- 内存使用分析
- 渲染性能测试

**文件列表**：
- `benchmark_test.dart` - 性能基准测试

**命名规范**：`{aspect}_test.dart` 或 `benchmark_test.dart`

---

### 7. `helpers/` - 测试辅助工具

**职责**：提供测试用的辅助函数和 Mock 对象

**文件列表**：
- `fake_analysis.dart` - 假分析数据生成器（用于 E2E 测试）

**使用说明**：
```dart
import '../helpers/fake_analysis.dart';

// 使用假分析数据生成器
final fakeStream = createFakeAnalysisStream(...);
```

---

### 8. `fixtures/` - 测试数据文件

**职责**：存储测试用的示例数据和配置文件

**文件列表**：
- `e2e_scenarios/` - E2E 测试场景数据
  - `scenario_success.jsonl` - 成功场景
  - `scenario_error_timeout.jsonl` - 超时错误场景
  - `scenario_missing_evidence.jsonl` - 缺失证据场景
  - `artifacts/` - 测试用的输出文件示例

**使用说明**：
```dart
final sourceFile = File('test/fixtures/e2e_scenarios/scenario_success.jsonl');
```

---

## 📝 测试文件命名规范

### 基本规则

1. **所有测试文件必须以 `_test.dart` 结尾**
2. **文件名应清晰描述测试内容**
3. **使用下划线分隔单词**

### 命名模式

| 测试类型 | 命名模式 | 示例 |
|---------|---------|------|
| 基本功能测试 | `{module}_test.dart` | `session_manager_test.dart` |
| 边界情况测试 | `{module}_boundary_test.dart` | `session_manager_boundary_test.dart` |
| 特定功能测试 | `{module}_{feature}_test.dart` | `event_bus_jsonl_test.dart` |
| 集成测试 | `{module}_integration_test.dart` | `services_integration_test.dart` |
| 页面测试 | `{page}_test.dart` 或 `{page}_{aspect}_test.dart` | `camera_page_flow_test.dart` |
| 组件测试 | `{widget}_test.dart` | `score_card_test.dart` |
| 规范测试 | `{aspect}_test.dart` | `ui_semantic_color_test.dart` |

---

## ➕ 如何添加新测试

### 1. 确定测试分类

根据被测试代码的位置，选择对应的测试目录：

- `lib/adapters/` → `test/adapters/`
- `lib/services/` → `test/services/`
- `lib/ui/` → `test/ui/`
- `lib/theme/` → `test/theme/`

### 2. 创建测试文件

**模板**：
```dart
// {module}_test.dart
// Purpose: 测试 {module} 的功能
// Coverage: {列出测试覆盖的内容}

import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/{path_to_module}.dart';

void main() {
  group('{Module} Tests', () {
    test('Should {expected behavior}', () {
      // Arrange
      
      // Act
      
      // Assert
      expect(actual, expected);
    });
  });
}
```

### 3. 使用测试辅助工具

**导入测试辅助工具**：
```dart
import '../test_helpers.dart';

void main() {
  setupTestEnvironment();
  
  testWidgets('My widget test', (WidgetTester tester) async {
    await tester.pumpWidget(TestHarness(
      child: MyWidget(),
    ));
  });
}
```

### 4. 添加测试数据

如果需要测试数据文件：
1. 将数据文件放在 `fixtures/` 目录
2. 在测试中使用相对路径引用：`File('test/fixtures/my_data.json')`

---

## 🚀 运行测试

### 运行所有测试

```bash
flutter test
```

### 运行特定目录的测试

```bash
# 运行服务层测试
flutter test test/services/

# 运行 UI 测试
flutter test test/ui/

# 运行适配器测试
flutter test test/adapters/
```

### 运行单个测试文件

```bash
flutter test test/services/event_bus_basic_test.dart
```

### 运行测试并生成覆盖率报告

```bash
flutter test --coverage
dart tool/check_coverage.dart --threshold=85
```

### 运行测试（详细输出）

```bash
flutter test --reporter expanded
```

---

## 📊 测试覆盖率

### 查看覆盖率

```bash
# 生成覆盖率报告
flutter test --coverage

# 检查覆盖率（要求 >= 85%）
dart tool/check_coverage.dart --threshold=85
```

### 覆盖率目标

- **总体覆盖率**：≥ 85%
- **核心服务**：≥ 90%
- **适配器层**：≥ 95%
- **UI 层**：≥ 80%

覆盖率报告文件：`coverage/lcov.info`

---

## ✅ 测试最佳实践

### 1. 测试组织

- ✅ 每个测试文件只测试一个模块或功能
- ✅ 使用 `group()` 组织相关测试
- ✅ 测试名称清晰描述测试内容
- ✅ 遵循 AAA 模式（Arrange-Act-Assert）

### 2. 测试独立性

- ✅ 每个测试应该独立运行，不依赖其他测试
- ✅ 使用 `setUp()` 和 `tearDown()` 管理测试环境
- ✅ 清理临时文件和资源

### 3. 测试数据

- ✅ 使用 `fixtures/` 目录存储测试数据
- ✅ 避免硬编码测试数据，使用常量或工厂函数
- ✅ 使用 `helpers/` 中的辅助工具生成测试数据

### 4. 测试命名

- ✅ 测试名称应该描述"应该做什么"（Should...）
- ✅ 使用清晰的中文或英文描述
- ✅ 避免使用缩写

### 5. 避免重复

- ✅ 基本功能测试放在 `{module}_test.dart`
- ✅ 边界情况放在 `{module}_boundary_test.dart`
- ✅ 特定功能放在 `{module}_{feature}_test.dart`
- ✅ 避免在多个文件中重复测试相同功能

---

## 🔍 测试分类决策树

```
新功能需要测试？
├─ 是数据转换/适配？ → test/adapters/
├─ 是业务逻辑/服务？ → test/services/
│  ├─ 基本功能？ → {service}_test.dart
│  ├─ 边界情况？ → {service}_boundary_test.dart
│  └─ 特定功能？ → {service}_{feature}_test.dart
├─ 是 UI/页面？ → test/ui/
│  ├─ 完整页面？ → {page}_test.dart
│  ├─ 页面特定方面？ → {page}_{aspect}_test.dart
│  └─ 组件？ → ui/widgets/{widget}_test.dart
├─ 是主题/样式？ → test/theme/
├─ 是完整流程？ → test/e2e/
└─ 是性能测试？ → test/performance/
```

---

## 📚 相关文档

- [Flutter 测试文档](https://docs.flutter.dev/testing)
- [项目 README](../README.md)
- [测试覆盖率工具](../tool/check_coverage.dart)

---

## 🐛 问题反馈

如果发现测试相关问题：
1. 检查测试文件是否放在正确的目录
2. 确认测试命名符合规范
3. 运行 `flutter test` 确保所有测试通过
4. 检查覆盖率是否达标

---

**最后更新**：2024年（根据实际日期更新）

