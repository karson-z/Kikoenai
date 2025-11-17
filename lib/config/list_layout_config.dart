import 'package:flutter/material.dart';
import '../core/enums/device_type.dart';

/// 列表响应式布局
class ListWorkLayoutConfig {
  // ===== 列数 =====
  static const int mobileColumns = 1;
  static const int tabletColumns = 2;
  static const int laptopColumns = 3;
  static const int desktopColumns = 3;

  // ===== 横向间距 =====
  static const double mobileHSpacing = 8;
  static const double tabletHSpacing = 12;
  static const double laptopHSpacing = 12;
  static const double desktopHSpacing = 16;

  // ===== 纵向间距 =====
  static const double mobileVSpacing = 8;
  static const double tabletVSpacing = 10;
  static const double laptopVSpacing = 12;
  static const double desktopVSpacing = 12;

  // ===== 内边距 =====
  static const EdgeInsets mobilePadding = EdgeInsets.all(8);
  static const EdgeInsets tabletPadding = EdgeInsets.all(12);
  static const EdgeInsets laptopPadding = EdgeInsets.all(16);
  static const EdgeInsets desktopPadding = EdgeInsets.all(16);

  const ListWorkLayoutConfig._();

  /// 列数
  static int getColumns(DeviceType type) {
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
