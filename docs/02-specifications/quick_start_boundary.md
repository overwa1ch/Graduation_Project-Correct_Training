# 主题边界约定 - 快速开始指南

## 🎯 目标

确保主题系统与业务逻辑清晰分离：
- **Theme 层**：只管"怎么显示"（颜色、字体、圆角）
- **UI 层**：决定"显示什么"（业务逻辑选择语义色）
- **Config 层**：管理业务配置（strict/relaxed, engine 等）

---

## 🚀 本地验证步骤

### 1. 安装依赖
```bash
cd aiwa_app
flutter pub get
```

### 2. 运行静态分析
```bash
flutter analyze
```
✅ 预期结果：0 warnings, 0 errors

### 3. 运行所有测试
```bash
flutter test
```
✅ 预期结果：所有测试通过

### 4. 运行边界测试（单独）
```bash
# 主题边界测试
flutter test test/theme_boundary_test.dart -r expanded

# UI 语义色测试
flutter test test/ui_semantic_color_test.dart -r expanded
```
✅ 预期结果：
- ✅ Theme 层无业务逻辑
- ✅ UI 层无硬编码颜色

### 5. 构建验证
```bash
flutter build apk --debug
```
✅ 预期结果：构建成功

---

## 📚 使用指南

### ✅ 正确：在 UI 组件中使用语义色

```dart
import 'package:aiwa_app/theme/colors.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final score = 85.0;
    
    // ✅ 业务逻辑在 UI 层
    final scoreColor = score >= 90 
      ? SemanticColors.success 
      : SemanticColors.warning;
    
    return Container(
      color: scoreColor, // ✅ 使用语义色
      child: Text(
        'Score: $score',
        style: Theme.of(context).textTheme.bodyLarge, // ✅ 使用 Theme
      ),
    );
  }
}
```

### ❌ 错误：硬编码颜色

```dart
// ❌ 错误！不要这样做
return Container(
  color: Color(0xFF70AB34), // ❌ 硬编码颜色
  child: Text(
    'Score: $score',
    style: TextStyle(fontSize: 16, color: Colors.white), // ❌ 硬编码样式
  ),
);
```

### ✅ 正确：使用配置服务

```dart
import 'package:aiwa_app/services/config_sync.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final configService = ConfigSyncService();
    
    // ✅ 从配置服务读取业务配置
    final config = await configService.loadConfig();
    
    // ✅ 根据配置决定业务逻辑
    final threshold = config.thresholdProfile == 'strict' ? 90.0 : 70.0;
    
    // ✅ 根据业务逻辑选择语义色
    final color = score >= threshold 
      ? SemanticColors.success 
      : SemanticColors.error;
    
    return ScoreCard(score: score, threshold: threshold);
  }
}
```

---

## 🎨 可用的语义色

### 状态色
- `SemanticColors.success` - 成功/优秀（绿色）
- `SemanticColors.warning` - 警告/中等（橙色）
- `SemanticColors.error` - 错误/差（红色）
- `SemanticColors.info` - 信息（蓝色）

### 云端/AI 增强
- `SemanticColors.cloudEnhanced` - AI 增强特性（紫色）
- `SemanticColors.cloudProcessing` - 处理中（灰色）

### 动作色
- `SemanticColors.actionPrimary` - 主要动作
- `SemanticColors.actionSecondary` - 次要动作
- `SemanticColors.actionDisabled` - 禁用状态

### 数据可视化
- `SemanticColors.dataHighlight` - 高亮数据
- `SemanticColors.dataSecondary` - 次要数据
- `SemanticColors.dataTertiary` - 第三数据
- `SemanticColors.dataBackground` - 数据背景

---

## 🧪 示例组件

项目提供了三个示例组件，展示了正确的使用模式：

### 1. ScoreCard
```dart
import 'package:aiwa_app/ui/widgets/score_card.dart';

ScoreCard(
  title: '深蹲评分',
  score: 85.5,
  isCloudEnhanced: true, // 显示 AI 增强徽标
  subtitle: '本次训练',
)
```

### 2. AngleLineChart
```dart
import 'package:aiwa_app/ui/widgets/angle_line_chart.dart';

AngleLineChart(
  title: '膝盖角度变化',
  dataPoints: [90, 85, 92, 88, 95],
  threshold: 90.0,
  showThreshold: true,
)
```

### 3. EvidenceFrameCard
```dart
import 'package:aiwa_app/ui/widgets/evidence_frame_card.dart';

EvidenceFrameCard(
  frameName: '底部姿态',
  imageUrl: 'https://example.com/frame.jpg',
  state: EvidenceState.correct,
  stateMessage: '姿势正确',
  isCloudProcessed: true,
)
```

---

## 🔍 CI/CD 验证

项目配置了完整的 CI 流程，每次提交都会自动验证：

### CI Jobs（共 9 个）
1. ✅ **Static Analysis** - `flutter analyze`
2. ✅ **Unit Tests** - `flutter test`
3. ✅ **Theme Tests** - 主题映射测试
4. ✅ **Theme Boundary Tests** - 主题边界验证（**新增**）
5. ✅ **UI Semantic Color Tests** - UI 语义色验证（**新增**）
6. ✅ **Tokens Schema Tests** - Token 结构测试
7. ✅ **Widget Tests** - Widget 冒烟测试
8. ✅ **Tokens Sync** - Token 同步验证
9. ✅ **Build Validation** - 构建验证

### 失败条件
- ❌ 主题文件包含业务逻辑（`if (strict)` 等）
- ❌ UI 文件包含硬编码颜色（`Color(0xFFxxxxxx)`）
- ❌ UI 文件使用裸 Colors（`Colors.red` 等）
- ❌ `flutter analyze` 有警告
- ❌ 任何测试失败
- ❌ 构建失败

---

## 📋 检查清单

在提交代码前，请确认：

- [ ] 我没有在 `lib/theme/**` 中写业务逻辑
- [ ] 我没有在 `lib/ui/**` 中使用 `Color(0xFFxxxxxx)`
- [ ] 我没有在 `lib/ui/**` 中使用裸 `Colors.red` 等
- [ ] 我使用了 `SemanticColors` 或 `Theme.of(context)`
- [ ] 我运行了 `flutter analyze` 且 0 warnings
- [ ] 我运行了 `flutter test` 且全部通过
- [ ] 我运行了边界测试且通过

---

## 🆘 常见问题

### Q: 我需要一个新的业务颜色怎么办？

**A:** 在 `lib/theme/colors.dart` 的 `SemanticColors` 类中添加：
```dart
static const Color myNewSemantic = Color(0xFFxxxxxx);
```
然后在 UI 层使用 `SemanticColors.myNewSemantic`。

### Q: 我需要根据配置改变样式怎么办？

**A:** 在 UI 层读取配置，然后选择对应的语义色：
```dart
final config = await ConfigSyncService().loadConfig();
final color = config.thresholdProfile == 'strict' 
  ? SemanticColors.error 
  : SemanticColors.warning;
```

### Q: 云端返回了颜色数据怎么办？

**A:** ❌ 不要直接使用云端颜色！云端应该返回语义状态，UI 根据状态选择颜色：
```dart
// 云端返回
{"status": "excellent", "score": 95}

// UI 层映射
final color = switch (result.status) {
  'excellent' => SemanticColors.success,
  'good' => SemanticColors.warning,
  'poor' => SemanticColors.error,
};
```

### Q: 测试报告说我违反了边界怎么办？

**A:** 查看测试输出，找到具体违规的文件和行号，然后：
- 如果在 theme 层：移除业务逻辑，改为纯样式定义
- 如果在 UI 层：移除硬编码颜色，改用 SemanticColors

---

## 📚 相关文档

- **验收清单**：`THEME_BOUNDARY_COMPLIANCE.md`
- **主题 README**：`lib/theme/README.md`
- **架构说明**：`../ARCHITECTURE.md`
- **CI 配置**：`../.github/workflows/flutter-ci.yml`

---

**最后更新**: 2025-10-26

