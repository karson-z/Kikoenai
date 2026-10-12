

import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  laptop,
  desktop;

  static const double tabletBreakpoint = 600;
  static const double laptopBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static DeviceType fromWidth(double width) {
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= laptopBreakpoint) return DeviceType.laptop;
    if (width >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// 用短边区分手机和平板，再用当前宽度区分笔记本和桌面。
  /// 手机横屏时宽度会超过 [tabletBreakpoint]，但短边仍小于它，应继续使用手机布局。
  static DeviceType fromSize(Size size) {
    if (size.shortestSide < tabletBreakpoint) return DeviceType.mobile;
    return fromWidth(size.width);
  }
}
extension DeviceTypeX on BuildContext {
  /// 获取当前设备的 DeviceType
  /// 使用 MediaQuery.sizeOf(context) 比 .of(context) 更高效，
  /// 因为它只监听尺寸变化，不会因为其他 MediaQuery 属性（如键盘弹出）变化而导致无关的重建。
  DeviceType get deviceType {
    return DeviceType.fromSize(MediaQuery.sizeOf(this));
  }

  // --- 以下是可选的便捷判断属性 ---

  /// 是否为手机
  bool get isMobile => deviceType == DeviceType.mobile;

  /// 是否为平板
  bool get isTablet => deviceType == DeviceType.tablet;

  /// 是否为笔记本
  bool get isLaptop => deviceType == DeviceType.laptop;

  /// 是否为桌面显示器
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// 是否为移动设备 (手机或平板)
  bool get isMobileOrTablet => isMobile || isTablet;

  /// 是否为大屏幕设备 (笔记本或桌面)
  bool get isLargeScreen => isLaptop || isDesktop;
}