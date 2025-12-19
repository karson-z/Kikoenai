import 'package:flutter/material.dart';
import '../../../../core/constants/app_use_explain.dart';

class ImportExplainDialog extends StatelessWidget {
  const ImportExplainDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 500, // 👈 统一高度限制
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1), // 顶部经分割线

            // 中间内容区，自适应高度
            Expanded(
              child: _buildBody(context),
            ),

            const Divider(height: 1), // 底部经分割线
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // --- 1. 头部 ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: Colors.blue),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "导入规则说明",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // --- 2. 内容区 (保留了你原本漂亮的 Card 设计) ---
  Widget _buildBody(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16), // 内容区的内边距
      shrinkWrap: true, // 允许内容少时收缩
      itemCount: AppUseExplain.importRules.length,
      itemBuilder: (context, index) {
        final section = AppUseExplain.importRules[index];
        final rules = section['rules'] as List<Map<String, String>>;
        final color = section['color'] as Color;

        return Card(
          elevation: 0,
          color: color.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 卡片标题
                Row(
                  children: [
                    Icon(section['icon'] as IconData, size: 20, color: color),
                    const SizedBox(width: 8),
                    Text(
                      section['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Divider(height: 16, color: color.withOpacity(0.1)),

                // 规则列表
                ...rules.map((rule) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: color.withOpacity(0.5),
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: "${rule['label']}：\n",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: rule['content'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 3. 底部 ---
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("明白了"),
        ),
      ),
    );
  }
}