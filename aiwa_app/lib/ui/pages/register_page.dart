import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/services/auth/auth_state.dart';

/// 注册页面
///
/// 基于 Figma 设计和现有主题实现
/// 功能：
/// - 用户注册
/// - 表单验证
/// - 密码确认
/// - 错误提示
/// - 跳转登录页面
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 表单验证 - 邮箱
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '请输入正确的邮箱';
    }

    return null;
  }

  /// 表单验证 - 密码
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }

    if (value.length < 8) {
      return '密码至少 8 位';
    }

    // 可选：添加更多密码强度验证
    // if (!RegExp(r'[A-Z]').hasMatch(value)) {
    //   return 'Password must contain at least one uppercase letter';
    // }
    // if (!RegExp(r'[a-z]').hasMatch(value)) {
    //   return 'Password must contain at least one lowercase letter';
    // }
    // if (!RegExp(r'[0-9]').hasMatch(value)) {
    //   return 'Password must contain at least one number';
    // }

    return null;
  }

  /// 表单验证 - 确认密码
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }

    if (value != _passwordController.text) {
      return '两次密码不一致';
    }

    return null;
  }

  /// 处理注册
  Future<void> _handleRegister() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = AuthState();
      final success = await authState.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // 注册成功，跳转到首页
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // 显示错误信息
        _showErrorSnackBar(authState.errorMessage ?? '注册失败');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('发生错误：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: AppSpacing.pageInsets,
      ),
    );
  }

  /// 返回登录页面
  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('注册'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pageInsets,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 标题
                    Text(
                      '创建账号',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: AppTypography.extraBold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // 副标题
                    Text(
                      '注册后开始训练',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // 邮箱输入框
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        hintText: '请输入邮箱',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 密码输入框
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        hintText: '至少 8 位',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      enabled: !_isLoading,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 确认密码输入框
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: '确认密码',
                        hintText: '再次输入密码',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // 注册按钮
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text('注册'),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 已有账号提示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '已有账号？',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _navigateToLogin,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                          ),
                          child: const Text('登录'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
