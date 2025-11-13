import 'package:flutter/material.dart';

/// 设备类型
enum DeviceType {
  mobile,
  tablet,
  laptop,
  desktop;

  /// 根据屏幕宽度获取设备类型
  static DeviceType fromWidth(double width) {
    if (width >= WorkLayoutConfig.desktopBreakpoint) return DeviceType.desktop;
    if (width >= WorkLayoutConfig.laptopBreakpoint) return DeviceType.laptop;
    if (width >= WorkLayoutConfig.tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}

/// 响应式布局配置
class WorkLayoutConfig {
  // ===== 屏幕断点 =====
  static const double tabletBreakpoint = 768;
  static const double laptopBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // ===== 列数 =====
  static const int mobileColumns = 2;
  static const int tabletColumns = 3;
  static const int laptopColumns = 4;
  static const int desktopColumns = 6;

  // ===== 横向间距（crossAxisSpacing）=====
  static const double mobileHSpacing = 1;
  static const double tabletHSpacing = 2;
  static const double laptopHSpacing = 3;
  static const double desktopHSpacing = 4;

  // ===== 纵向间距（mainAxisSpacing）=====
  // 保持紧凑，不随屏幕增大而增加太多
  static const double mobileVSpacing = 1;
  static const double tabletVSpacing = 2;
  static const double laptopVSpacing = 2;
  static const double desktopVSpacing = 2;

  // ===== 内边距 =====
  static const EdgeInsets mobilePadding = EdgeInsets.all(8);
  static const EdgeInsets tabletPadding = EdgeInsets.all(12);
  static const EdgeInsets laptopPadding = EdgeInsets.all(16);
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );

  const WorkLayoutConfig._();

  /// 列数
  static int getColumnsCount(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return mobileColumns;
      case DeviceType.tablet:
        return tabletColumns;
      case DeviceType.laptop:
        return laptopColumns;
      case DeviceType.desktop:
        return desktopColumns;
    }
  }

  /// 横向间距
  static double getHorizontalSpacing(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return mobileHSpacing;
      case DeviceType.tablet:
        return tabletHSpacing;
      case DeviceType.laptop:
        return laptopHSpacing;
      case DeviceType.desktop:
        return desktopHSpacing;
    }
  }

  /// 纵向间距
  static double getVerticalSpacing(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return mobileVSpacing;
      case DeviceType.tablet:
        return tabletVSpacing;
      case DeviceType.laptop:
        return laptopVSpacing;
      case DeviceType.desktop:
        return desktopVSpacing;
    }
  }

  /// 内边距
  static EdgeInsets getPadding(DeviceType type) {
    switch (type) {
      case DeviceType.mobile:
        return mobilePadding;
      case DeviceType.tablet:
        return tabletPadding;
      case DeviceType.laptop:
        return laptopPadding;
      case DeviceType.desktop:
        return desktopPadding;
    }
  }
}
