import 'package:flutter/material.dart';
import 'package:name_app/config/work_layout_config.dart';

/// 作品布局策略
class WorkLayoutStrategy {
  const WorkLayoutStrategy();

  /// 获取设备类型
  DeviceType _getDeviceType(BuildContext context) {
    return DeviceType.fromWidth(MediaQuery.of(context).size.width);
  }

  /// 获取每行的列数
  int getColumnsCount(BuildContext context) {
    return WorkLayoutConfig.getColumnsCount(_getDeviceType(context));
  }

  /// 获取行间距
  double getRowSpacing(BuildContext context) {
    return WorkLayoutConfig.getSpacing(_getDeviceType(context));
  }

  /// 获取列间距
  double getColumnSpacing(BuildContext context) {
    return WorkLayoutConfig.getSpacing(_getDeviceType(context));
  }

  /// 获取内边距
  EdgeInsets getPadding(BuildContext context) {
    return WorkLayoutConfig.getPadding(_getDeviceType(context));
  }
}
