import 'package:flutter/material.dart';
import '../core/enums/device_type.dart';

class CardWorkLayoutConfig {
  static const int mobileColumns = 2;
  static const int tabletColumns = 3;
  static const int laptopColumns = 4;
  static const int desktopColumns = 6;

  static const double mobileHSpacing = 1;
  static const double tabletHSpacing = 2;
  static const double laptopHSpacing = 3;
  static const double desktopHSpacing = 4;

  static const double mobileVSpacing = 1;
  static const double tabletVSpacing = 2;
  static const double laptopVSpacing = 2;
  static const double desktopVSpacing = 2;

  static const EdgeInsets mobilePadding = EdgeInsets.all(8);
  static const EdgeInsets tabletPadding = EdgeInsets.all(12);
  static const EdgeInsets laptopPadding = EdgeInsets.all(16);
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  const CardWorkLayoutConfig._();

  static int getColumnsCount(DeviceType type) {
    switch (type) {
      case DeviceType.mobile: return mobileColumns;
      case DeviceType.tablet: return tabletColumns;
      case DeviceType.laptop: return laptopColumns;
      case DeviceType.desktop: return desktopColumns;
    }
  }

  static double getHorizontalSpacing(DeviceType type) {
    switch (type) {
      case DeviceType.mobile: return mobileHSpacing;
      case DeviceType.tablet: return tabletHSpacing;
      case DeviceType.laptop: return laptopHSpacing;
      case DeviceType.desktop: return desktopHSpacing;
    }
  }

  static double getVerticalSpacing(DeviceType type) {
    switch (type) {
      case DeviceType.mobile: return mobileVSpacing;
      case DeviceType.tablet: return tabletVSpacing;
      case DeviceType.laptop: return laptopVSpacing;
      case DeviceType.desktop: return desktopVSpacing;
    }
  }

  static EdgeInsets getPadding(DeviceType type) {
    switch (type) {
      case DeviceType.mobile: return mobilePadding;
      case DeviceType.tablet: return tabletPadding;
      case DeviceType.laptop: return laptopPadding;
      case DeviceType.desktop: return desktopPadding;
    }
  }
}
