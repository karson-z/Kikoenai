import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kikoenai_core/kikoenai_core.dart';
import '../../service/site/site_api_provider.dart';
import '../../widgets/common/kikoenai_dialog.dart';
import '../../widgets/layout/app_toast.dart';

class HandleSubmit {
  /// 处理评分提交
  static Future<void> handleRatingSubmit(
      BuildContext context,
      WidgetRef ref,
      UserWorkStatus newStatus
      ) async {
    // 1. 显示加载中
    KikoenaiDialog.showLoading(msg: "正在保存...");

    try {
      // 2. 获取 API 客户端
      await ref.read(siteApiProvider).submitReview(newStatus);
      // 4. 关闭加载框
      KikoenaiDialog.dismiss();
      KikoenaiToast.success("标记成功");
      // 6. (可选) 刷新关联的 Provider，让界面更新
      // ref.invalidate(workStatusProvider(newStatus.workId));

    } catch (e) {
      // 7. 处理错误
      KikoenaiDialog.dismiss(); // 确保关闭 Loading
      debugPrint("提交失败: $e");
      KikoenaiToast.error("提交失败:$e");
    }
  }
}