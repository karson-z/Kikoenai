import 'package:flutter/material.dart';

/// 统一的加载错误 / 重试组件。
///
/// 用于异步加载（如字幕内容）失败时展示错误信息，并提供「重试」按钮。
/// 使用方式：
///   KikoenaiErrorRetryView(
///     message: '字幕加载失败',
///     onRetry: () => ref.invalidate(lyricsContentProvider(url)),
///   )
///
/// [onRetry] 通常需要让对应的 provider 重新请求（如 ref.invalidate），
/// 因为 Riverpod 的 family provider 会把错误缓存下来，只有 invalidate
/// 才会触发真正的重新拉取。
class KikoenaiErrorRetryView extends StatelessWidget {
  /// 错误说明文案（为空时使用默认文案）
  final String? message;

  /// 点击「重试」时的回调
  final VoidCallback onRetry;

  /// 是否紧凑模式（用于空间较小的区域）
  final bool compact;

  /// 重试按钮文案
  final String retryLabel;

  /// 前景色（图标 + 文案颜色）；为空时跟随主题
  final Color? foregroundColor;

  const KikoenaiErrorRetryView({
    super.key,
    this.message,
    required this.onRetry,
    this.compact = false,
    this.retryLabel = '重试',
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fg = foregroundColor ?? colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 12 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: compact ? 28 : 40,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? '加载失败',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
