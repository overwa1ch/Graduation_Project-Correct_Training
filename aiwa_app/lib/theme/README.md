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
- **阴影**: `surfaceSecondary.withOpacity(0.25)` (深灰色半透明)

### 3. 静态颜色系统
不再支持主题切换，所有颜色使用静态常量。

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

// 使用语义颜色
Container(
  color: SemanticColors.success,  // 等同于 brandPrimaryVariant
  child: Text('Success'),
)

Container(
  color: SemanticColors.error,    // 等同于 surfaceSecondary
  child: Text('Error'),
)
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
// 正确的阴影使用方式
BoxShadow(
  color: AppColors.surfaceSecondary.withOpacity(0.25),
  offset: const Offset(0, 4),
  blurRadius: 4,
)
```

### 使用字体

```dart
import 'package:aiwa_app/theme/typography.dart';

Text(
  'Heading',
  style: AppTypography.h1,
)

// 或使用 Theme.of(context)
Text(
  'Heading',
  style: Theme.of(context).textTheme.displayLarge,
)
```

### 使用间距和圆角

```dart
import 'package:aiwa_app/theme/spacing.dart';

Container(
  padding: AppSpacing.cardInsets,
  margin: AppSpacing.pageInsets,
  decoration: BoxDecoration(
    borderRadius: AppRadius.cardRadius,
    boxShadow: [AppShadows.standard],
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

### 字体 (typography.json)

- **Font Family**: Inter
- **H1**: 48px, ExtraBold (800)
- **H2**: 32px, ExtraBold (800)
- **Heading**: 24px, SemiBold (600)
- **Body Base**: 16px, Regular (400)
- **Button**: 20px, ExtraBold (800)

### 间距 (spacing.json)

- **xs**: 4px
- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **xl**: 24px
- **xxl**: 32px

### 圆角 (radius.json)

- **sm**: 8px
- **md**: 12px
- **lg**: 16px
- **full**: 999px

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
3. **阴影统一使用surfaceSecondary**: 不再使用 `Colors.black`
4. **静态颜色系统**: 不再支持主题切换，所有颜色为静态常量
5. **不要直接修改 tokens/*.json**: 这些文件应该从 Figma 自动生成
6. **保持 Dart 常量与 JSON 同步**: 更新 JSON 后需要手动更新对应的 Dart 常量

## 示例组件

### 分数卡片

```dart
Widget buildScoreCard(String label, int score) {
  final Color scoreColor = score >= 80 
    ? AppColors.brandPrimaryVariant  // 高分 - 绿色
    : AppColors.surfaceSecondary;    // 低分/中分 - 灰色
    
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: scoreColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.surfaceSecondary.withOpacity(0.25),
          offset: const Offset(0, 4),
          blurRadius: 4,
        ),
      ],
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
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.surfaceSecondary.withOpacity(0.2),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.surfaceSecondary, width: 1),
  ),
  child: Row(
    children: [
      Icon(Icons.warning, color: AppColors.surfaceSecondary, size: 20),
      const SizedBox(width: 8),
      Text(
        'Warning message',
        style: TextStyle(color: AppColors.surfaceSecondary),
      ),
    ],
  ),
)
```

### 错误框

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.surfaceSecondary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.surfaceSecondary, width: 1),
  ),
  child: Row(
    children: [
      Icon(Icons.error, color: AppColors.surfaceSecondary, size: 24),
      const SizedBox(width: 8),
      Text(
        'Error message',
        style: TextStyle(color: AppColors.surfaceSecondary),
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
