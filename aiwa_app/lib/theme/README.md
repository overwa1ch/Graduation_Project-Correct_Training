# AIWA Theme System

## 概述

本主题系统基于 Figma 设计文件 (q3hgTOdVGt42WkOfDixtsp) 的 Variables，使用 Material 3 设计规范，通过 figma-developer-mcp 自动提取设计 tokens。

## 文件结构

```
lib/theme/
├── tokens/              # 原始设计 tokens (JSON)
│   ├── colors.json      # 颜色变量
│   ├── typography.json  # 字体变量
│   ├── spacing.json     # 间距变量
│   └── radius.json      # 圆角变量
├── colors.dart          # 颜色常量 + ColorScheme 映射
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
  color: AppColors.brandPrimary,
  padding: AppSpacing.pageInsets,
)
```

### 2. Material 3 映射
所有 tokens 都映射到 Material 3 的语义化角色：

- **Brand Primary** → `ColorScheme.primary`
- **Surface Primary** → `ColorScheme.surface`
- **Text Invert** → `ColorScheme.onPrimary`

### 3. 明暗主题一致性
Light 和 Dark 主题使用相同的 primary、error 等关键颜色，仅调整 surface 颜色。

## 使用方法

### 在 main.dart 中应用主题

```dart
import 'package:flutter/material.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIWA App',
      theme: createLightTheme(),
      darkTheme: createDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
```

### 使用颜色

```dart
import 'package:aiwa_app/theme/colors.dart';

// 直接使用颜色常量
Container(
  color: AppColors.brandPrimary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textInvert),
  ),
)

// 或使用 Theme.of(context)
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
  ),
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

- **Brand Primary**: `#70AB34` - 主品牌色（绿色）
- **Surface Primary**: `#212121` - 深色背景
- **Surface Secondary**: `#2B2B2B` - 次级背景
- **Surface Tertiary**: `#F4F0EB` - 浅色背景
- **Error Primary**: `#FF5252` - 错误色（红色）

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
- ✅ Material 3 合规性
- ✅ 明暗主题一致性
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

1. **不要直接修改 tokens/*.json**：这些文件应该从 Figma 自动生成
2. **保持 Dart 常量与 JSON 同步**：更新 JSON 后需要手动更新对应的 Dart 常量
3. **使用语义化命名**：优先使用 `Theme.of(context)` 而不是直接引用常量
4. **测试覆盖**：修改主题后务必运行测试

## 示例组件

### 按钮

```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Get Started'),
)
// 自动应用 AppColors.brandPrimary 和 AppRadius.buttonRadius
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

### 输入框

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Username',
    hintText: 'Enter your username',
  ),
)
// 自动应用 AppRadius.inputRadius 和主题颜色
```

## 参考资料

- [Material 3 Design](https://m3.material.io/)
- [Flutter ThemeData](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [Figma Variables](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma)


