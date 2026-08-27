import 'package:flutter/material.dart';

class GuestPlaceholderView extends StatelessWidget {
  /// 点击登录按钮的回调
  final VoidCallback? onLoginTap;

  /// 自定义标题（可选）
  final String title;

  /// 自定义副标题（可选）
  final String message;

  /// 按钮文字（可选）
  final String buttonText;

  const GuestPlaceholderView({
    super.key,
    this.onLoginTap,
    this.title = "需要登录",
    this.message = "请登录账号以查看此内容并同步您的数据",
    this.buttonText = "立即登录",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.14 : 0.09,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.22 : 0.12,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 32,
                    color: colorScheme.primary,
                    semanticLabel: title,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
                    height: 1.55,
                  ),
                ),
                if (onLoginTap != null) ...[
                  const SizedBox(height: 26),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: onLoginTap,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(
                          buttonText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
