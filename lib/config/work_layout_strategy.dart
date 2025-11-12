import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_config.dart';

/// 作品布局策略（对 WorkLayoutConfig 的便捷封装）
class WorkLayoutStrategy {
  const WorkLayoutStrategy();

  /// 根据屏幕宽度判断设备类型
  DeviceType getDeviceType(BuildContext context) {
    return DeviceType.fromWidth(MediaQuery.of(context).size.width);
  }

  /// 每行的列数
  int getColumnsCount(BuildContext context) {
    return WorkLayoutConfig.getColumnsCount(getDeviceType(context));
  }

  /// 行间距（纵向间距）
  double getRowSpacing(BuildContext context) {
    return WorkLayoutConfig.getVerticalSpacing(getDeviceType(context));
  }

  /// 列间距（横向间距）
  double getColumnSpacing(BuildContext context) {
    return WorkLayoutConfig.getHorizontalSpacing(getDeviceType(context));
  }

  /// 内边距
  EdgeInsets getPadding(BuildContext context) {
    return WorkLayoutConfig.getPadding(getDeviceType(context));
  }
}
