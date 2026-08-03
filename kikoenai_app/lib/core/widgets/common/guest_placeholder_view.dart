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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 图标区域 (极简柔和底色)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                // 使用我们在设置卡片中用过的底层亮色，保持视觉语言统一
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_outlined,
                size: 40,
                // 图标使用次级文本色，避免过度抢眼
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // 2. 文本区域
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            if (onLoginTap != null) ...[
              const SizedBox(height: 32),
              // 3. 按钮区域 (使用 Material 3 规范的主按钮 FilledButton)
              SizedBox(
                height: 48,
                width: 200,
                child: FilledButton(
                  onPressed: onLoginTap,
                  style: FilledButton.styleFrom(
                    elevation: 0, // 扁平化，去阴影
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
