# AIWA Theme System

## 概述

本主题系统基于 Figma 设计文件 (q3hgTOdVGt42WkOfDixtsp) 的 Variables，使用简化的黑白+绿色配色方案。

## 文件结构

```
lib/theme/
├── tokens/              # 原始设计 tokens (JSON)
│   ├── colors.json      # 颜色变量
│   ├── typography.json  # 字体变量
│   ├── spacing.json     # 间距变量
│   └── radius.json      # 圆角变量
├── colors.dart          # 颜色常量
├── typography.dart      # 字体常量 + TextTheme 映射
├── spacing.dart         # 间距/圆角/阴影常量
└── theme.dart           # ThemeData 汇总
```

## 设计原则

### 1. 无硬编码
所有颜色、字体、间距值都来自 tokens 常量，不允许硬编码。

```dart
// ❌ 错误示例
Container(
  color: Color(0xFF70AB34),
  padding: EdgeInsets.all(16),
)

// ✅ 正确示例
Container(
  color: AppColors.brandPrimaryVariant,
  padding: AppSpacing.pageInsets,
)
```

### 2. 简化配色方案
使用黑白+绿色的简化配色：
- **成功/高分**: `brandPrimaryVariant = #4A7220` (深绿色)
- **错误/警告/中分**: `surfaceSecondary = #2B2B2B` (深灰色)
- **阴影**: 使用 `AppShadows.standard` 预设（深灰色半透明）

### 3. 主题系统
虽然代码中保留了 `createLightTheme()` 和 `createDarkTheme()` 两个函数，但实际应用使用固定的深色主题（`createDarkTheme()`）。所有颜色常量都是静态的，不支持运行时主题切换。

**主题相关函数**：
- `createLightTheme()` - 创建浅色主题 ThemeData（未使用）
- `createDarkTheme()` - 创建深色主题 ThemeData（实际使用）
- `createLightColorScheme()` - 创建浅色 ColorScheme
- `createDarkColorScheme()` - 创建深色 ColorScheme
- `createTextTheme({Color? color})` - 创建 TextTheme，将设计 tokens 映射到 Material Design 文本样式

## 使用方法

### 使用颜色

```dart
import 'package:aiwa_app/theme/colors.dart';

// 直接使用颜色常量
Container(
  color: AppColors.brandPrimaryVariant,  // 成功状态
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textInvert),
  ),
)

// 使用语义颜色（推荐用于业务逻辑）
Container(
  color: SemanticColors.success,  // 成功/高分 - 等同于 brandPrimaryVariant
  child: Text('Success'),
)

Container(
  color: SemanticColors.warning,  // 警告/中分 - 等同于 surfaceSecondary
  child: Text('Warning'),
)

Container(
  color: SemanticColors.error,    // 错误/低分 - 等同于 surfaceSecondary
  child: Text('Error'),
)

// 数据可视化颜色
Container(
  color: SemanticColors.dataHighlight,  // 数据高亮
)

// 云端增强指示器
Icon(Icons.cloud, color: SemanticColors.cloudEnhanced)  // 云端增强
Icon(Icons.sync, color: SemanticColors.cloudProcessing) // 处理中
```

### 分数颜色逻辑

```dart
// 正确的分数颜色使用方式
Color getScoreColor(int score) {
  if (score < 60) {
    return AppColors.surfaceSecondary;      // 低分 - 深灰色
  } else if (score < 80) {
    return AppColors.surfaceSecondary;      // 中分 - 深灰色
  } else {
    return AppColors.brandPrimaryVariant;   // 高分 - 深绿色
  }
}
```

### 阴影使用

```dart
import 'package:aiwa_app/theme/spacing.dart';

// ✅ 推荐：使用预设阴影
Container(
  decoration: BoxDecoration(
    boxShadow: [AppShadows.standard],  // 标准阴影
  ),
)

// 或使用 elevation 预设
Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.elevation2,  // Material elevation 2
  ),
)

// ❌ 不推荐：手动创建阴影（应使用预设）
// BoxShadow(
//   color: AppColors.surfaceSecondary.withOpacity(0.25),
//   offset: const Offset(0, 4),
//   blurRadius: 4,
// )
```

### 使用字体

```dart
import 'package:aiwa_app/theme/typography.dart';

// 直接使用预设文本样式
Text(
  'Heading',
  style: AppTypography.h1,
)

// 使用字体粗细常量
Text(
  'Custom Text',
  style: TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontWeight: AppTypography.extraBold,
    fontSize: 18,
  ),
)

// 或使用 Theme.of(context) 访问 TextTheme
Text(
  'Heading',
  style: Theme.of(context).textTheme.displayLarge,
)

// createTextTheme 函数用于创建 TextTheme，通常由 createLightTheme/createDarkTheme 内部调用
// 如需自定义文本主题，可以直接调用：
final customTextTheme = createTextTheme(color: AppColors.textPrimary);
```

### 使用间距和圆角

```dart
import 'package:aiwa_app/theme/spacing.dart';

// 基础间距
Container(
  padding: AppSpacing.cardInsets,  // EdgeInsets.all(12)
  margin: AppSpacing.pageInsets,   // EdgeInsets.all(16)
  child: Column(
    children: [
      Text('Item 1'),
      SizedBox(height: AppSpacing.md),  // 12px
      Text('Item 2'),
    ],
  ),
)

// 组件间距（Gap）
Row(
  children: [
    Text('Label'),
    SizedBox(width: AppSpacing.gapMd),  // 8px gap
    Text('Value'),
  ],
)

// 圆角和阴影
Container(
  decoration: BoxDecoration(
    borderRadius: AppRadius.cardRadius,  // BorderRadius.all(Radius.circular(8))
    boxShadow: [AppShadows.standard],
  ),
)

// 使用预设的 BorderRadius
Container(
  decoration: BoxDecoration(
    borderRadius: AppRadius.circularLg,  // 16px 圆角
  ),
)
```

## 设计 Tokens 说明

### 颜色 (colors.json)

- **Brand Primary Variant**: `#4A7220` - 深绿色（成功/高分状态）
- **Surface Primary**: `#212121` - 深色背景
- **Surface Secondary**: `#2B2B2B` - 次级背景（错误/警告/中分状态）
- **Surface Tertiary**: `#F4F0EB` - 浅色背景
- **Text Primary**: `#FFFFFF` - 白色文本
- **Text Invert**: `#FFFFFF` - 白色文本（反色）
- **Text On Surface**: `#000000` - 黑色文本
- **Neutral Light**: `#D9D9D9` - 浅灰色（用于UI组件）

### 字体 (typography.json)

**字体家族**：
- `AppTypography.fontFamily` - "Inter"

**字体粗细常量**：
- `AppTypography.regular` - FontWeight.w400
- `AppTypography.semiBold` - FontWeight.w600
- `AppTypography.bold` - FontWeight.w700
- `AppTypography.extraBold` - FontWeight.w800

**预设文本样式**：
- **H1**: 48px, ExtraBold (800)
- **H2**: 32px, ExtraBold (800)
- **Heading**: 24px, SemiBold (600)
- **Subheading**: 20px, Regular (400)
- **Body Base**: 16px, Regular (400)
- **Body Bold**: 16px, Bold (700)
- **Button**: 20px, ExtraBold (800)
- **Caption**: 14px, Regular (400)

**辅助函数**：
- `createTextTheme({Color? color})` - 创建 Material 3 TextTheme，将设计 tokens 映射到 Material Design 文本样式

### 间距 (spacing.json)

- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 24px
- **xxl**: 32px
- **xxxl**: 40px
- **huge**: 64px

**Padding 预设**（用于组件内边距）：
- **buttonPadding**: 8px
- **cardPadding**: 12px
- **pagePadding**: 16px
- **sectionPadding**: 64px

**EdgeInsets 预设**：
- `AppSpacing.buttonInsets` - EdgeInsets.all(8)
- `AppSpacing.cardInsets` - EdgeInsets.all(12)
- `AppSpacing.pageInsets` - EdgeInsets.all(16)
- `AppSpacing.sectionInsets` - EdgeInsets.all(64)

**Gap 间距**（用于组件间距）：
- **gapXs**: 2px
- **gapSm**: 4px
- **gapMd**: 8px
- **gapLg**: 10px
- **gapXl**: 20px
- **gapXxl**: 28px
- **gapXxxl**: 30px
- **gapHuge**: 40px

**方向性间距**：
- `AppSpacing.horizontalSm/Md/Lg/Xl` - 水平方向间距
- `AppSpacing.verticalSm/Md/Lg/Xl` - 垂直方向间距

### 圆角 (radius.json)

**基础圆角值**：
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 24px
- **full**: 999px

**组件专用圆角**：
- **button**: 8px
- **card**: 8px
- **input**: 8px
- **dialog**: 12px

**预设 BorderRadius**：
- `AppRadius.buttonRadius` - 按钮圆角
- `AppRadius.cardRadius` - 卡片圆角
- `AppRadius.inputRadius` - 输入框圆角
- `AppRadius.dialogRadius` - 对话框圆角
- `AppRadius.circularSm` - 8px 圆角
- `AppRadius.circularMd` - 12px 圆角
- `AppRadius.circularLg` - 16px 圆角
- `AppRadius.circularXl` - 24px 圆角
- `AppRadius.circularFull` - 999px 圆角（圆形/半圆形）

### 阴影 (AppShadows)

**预设阴影**：
- `AppShadows.standard` - 标准阴影 (0px 4px 4px rgba(0,0,0,0.25))
- `AppShadows.inset` - 内阴影
- `AppShadows.textShadow` - 文本阴影

**Material Elevation 预设**：
- `AppShadows.elevation1` - Material elevation 1
- `AppShadows.elevation2` - Material elevation 2
- `AppShadows.elevation3` - Material elevation 3 (等同于 standard)
- `AppShadows.elevation4` - Material elevation 4

## 测试

运行主题测试以验证映射一致性：

```bash
flutter test test/theme_test.dart
flutter test test/tokens_schema_test.dart
```

测试覆盖：
- ✅ 颜色映射正确性
- ✅ 字体映射正确性
- ✅ 间距/圆角值正确性
- ✅ Tokens JSON 结构验证

## 更新流程

当 Figma 设计更新时：

1. 使用 MCP 重新提取 tokens：
   ```bash
   # 通过 Cursor 或其他 MCP 客户端
   请从 Figma 文件 q3hgTOdVGt42WkOfDixtsp 更新 tokens
   ```

2. 更新 Dart 常量以匹配新的 tokens

3. 运行测试验证：
   ```bash
   flutter test
   ```

4. 同步 assets/tokens/ 目录：
   ```bash
   cp lib/theme/tokens/* assets/tokens/
   ```

## 注意事项

1. **不要使用Material原生颜色**: 禁止使用 `Colors.red`、`Colors.green`、`Colors.orange`、`Colors.black` 等
2. **统一使用AppColors常量**: 所有颜色都通过 `AppColors.*` 或 `SemanticColors.*` 引用
3. **阴影统一使用预设**: 使用 `AppShadows.standard` 或 `AppShadows.elevation*`，不再手动创建阴影或使用 `Colors.black`
4. **静态颜色系统**: 不再支持主题切换，所有颜色为静态常量
5. **不要直接修改 tokens/*.json**: 这些文件应该从 Figma 自动生成
6. **保持 Dart 常量与 JSON 同步**: 更新 JSON 后需要手动更新对应的 Dart 常量

## 示例组件

### 分数卡片

```dart
Widget buildScoreCard(String label, int score) {
  final Color scoreColor = score >= 80 
    ? SemanticColors.success  // 高分 - 绿色
    : SemanticColors.error;  // 低分/中分 - 灰色
    
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: AppRadius.cardRadius,  // 使用预设圆角
      border: Border.all(color: scoreColor, width: 2),
      boxShadow: [AppShadows.standard],  // 使用预设阴影
    ),
    child: Text(
      score.toString(),
      style: TextStyle(color: scoreColor),
    ),
  );
}
```

### 警告框

```dart
Container(
  padding: AppSpacing.cardInsets,  // 使用预设内边距
  decoration: BoxDecoration(
    color: SemanticColors.warning.withOpacity(0.2),
    borderRadius: AppRadius.cardRadius,  // 使用预设圆角
    border: Border.all(color: SemanticColors.warning, width: 1),
  ),
  child: Row(
    children: [
      Icon(Icons.warning, color: SemanticColors.warning, size: 20),
      SizedBox(width: AppSpacing.gapSm),  // 使用预设间距
      Text(
        'Warning message',
        style: TextStyle(color: SemanticColors.warning),
      ),
    ],
  ),
)
```

### 错误框

```dart
Container(
  padding: AppSpacing.pageInsets,  // 使用预设内边距
  decoration: BoxDecoration(
    color: SemanticColors.error.withOpacity(0.1),
    borderRadius: AppRadius.cardRadius,  // 使用预设圆角
    border: Border.all(color: SemanticColors.error, width: 1),
  ),
  child: Row(
    children: [
      Icon(Icons.error, color: SemanticColors.error, size: 24),
      SizedBox(width: AppSpacing.gapSm),  // 使用预设间距
      Text(
        'Error message',
        style: TextStyle(color: SemanticColors.error),
      ),
    ],
  ),
)
```

### 按钮

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Get Started'),
)
// 自动应用 AppColors.brandPrimaryVariant 和 AppRadius.buttonRadius
```

### 卡片

```dart
Card(
  child: Padding(
    padding: AppSpacing.cardInsets,
    child: Text('Content'),
  ),
)
// 自动应用 AppRadius.cardRadius 和阴影
```

## 参考资料

- [Material 3 Design](https://m3.material.io/)
- [Flutter ThemeData](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [Figma Variables](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma)
