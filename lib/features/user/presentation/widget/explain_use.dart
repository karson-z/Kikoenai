import 'package:flutter/material.dart';

import '../../../../core/constants/app_use_explain.dart';

class ImportExplainDialog extends StatelessWidget {
  const ImportExplainDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text("导入规则说明", style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SizedBox(
        // 限制高度，防止内容过长溢出
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppUseExplain.importRules.length,
          itemBuilder: (context, index) {
            final section = AppUseExplain.importRules[index];
            final rules = section['rules'] as List<Map<String, String>>;
            final color = section['color'] as Color;

            return Card(
              elevation: 0,
              color: color.withOpacity(0.05), // 浅色背景
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
                    // --- 标题部分 ---
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
                    const Divider(height: 16),

                    // --- 规则列表部分 ---
                    ...rules.map((rule) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 小圆点
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
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
                                  children: [
                                    TextSpan(
                                      text: "${rule['label']}：\n",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: rule['content'],
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("明白了"),
        ),
      ],
    );
  }
}