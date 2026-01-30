import 'package:flutter/material.dart';

class GuestPlaceholderView extends StatelessWidget {
  /// 点击登录按钮的回调
  final VoidCallback onLoginTap;

  /// 自定义标题（可选）
  final String title;

  /// 自定义副标题（可选）
  final String message;

  /// 按钮文字（可选）
  final String buttonText;

  const GuestPlaceholderView({
    super.key,
    required this.onLoginTap,
    this.title = "需要登录",
    this.message = "请登录账号以查看此内容并同步您的数据",
    this.buttonText = "立即登录",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 动态颜色定义 (保持与 DownloadPage 一致的设计语言)
    final Color cTextMain = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final Color cTextSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color cIconBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color cIconColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
    final Color cButtonBg = isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 图标区域
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cIconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_outlined, // 或者 Icons.account_circle_outlined
                size: 48,
                color: cIconColor,
              ),
            ),
            const SizedBox(height: 24),

            // 2. 文本区域
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cTextMain,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: cTextSub,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 3. 按钮区域
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton(
                onPressed: onLoginTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cButtonBg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23), // 圆角按钮
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 15,
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
        ),
      ),
    );
  }
}