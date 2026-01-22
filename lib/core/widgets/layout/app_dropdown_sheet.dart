import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../common/custom_bottom_type.dart';
import '../common/custom_side_sheet_type.dart';

/// 通用下拉弹窗
class CustomDropdownSheet {
  static Future<void> show({
    required BuildContext context,
    required String title,
    bool? isDark,
    required Widget Function(BuildContext modalContext) contentBuilder,
    double? maxHeight,
    List<Widget>? actionButtons,
    VoidCallback? onClosed, // 新增关闭回调
  }) {
    return WoltModalSheet.show<void>(
      context: context,
      modalTypeBuilder: (_) {
        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 500;

        return isMobile
            ?  WoltModalType.dialog()
            : const CustomSideSheetType();
      },
      pageListBuilder: (modalContext) => [
        SliverWoltModalSheetPage(
          backgroundColor: isDark ?? false ? Colors.black : Colors.white,
          isTopBarLayerAlwaysVisible: true,
          trailingNavBarWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(children: actionButtons ?? []),
              ],
            ),
          ),
          mainContentSliversBuilder: (context) => [
            const SliverPadding(padding: EdgeInsets.only(top: 8)),
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight ??
                      MediaQuery.of(context).size.height * 0.5,
                ),
                child: contentBuilder(modalContext),
              ),
            ),
          ],
        ),
      ],
    ).whenComplete(() {
      if (onClosed != null) {
        onClosed();
      }
    });
  }
}
