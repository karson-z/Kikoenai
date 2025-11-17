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
}