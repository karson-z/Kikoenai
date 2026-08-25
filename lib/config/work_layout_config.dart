import 'package:flutter/material.dart';

import '../core/enums/device_type.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class WorkLayoutMetrics {
  final int columns;
  final double horizontalSpacing;
  final double verticalSpacing;
  final EdgeInsets padding;

  const WorkLayoutMetrics({
    required this.columns,
    required this.horizontalSpacing,
    required this.verticalSpacing,
    required this.padding,
  });
}

class WorkLayoutConfig {
  const WorkLayoutConfig._();

  static WorkLayoutMetrics card(BuildContext context) =>
      cardFor(context.deviceType);

  static WorkLayoutMetrics list(BuildContext context) =>
      listFor(context.deviceType);

  static WorkLayoutMetrics cardFor(DeviceType device) {
    return switch (device) {
      DeviceType.mobile => const WorkLayoutMetrics(
          columns: 2,
          horizontalSpacing: 1,
          verticalSpacing: 1,
          padding: EdgeInsets.all(8),
        ),
      DeviceType.tablet => const WorkLayoutMetrics(
          columns: 3,
          horizontalSpacing: 2,
          verticalSpacing: 2,
          padding: EdgeInsets.all(12),
        ),
      DeviceType.laptop => const WorkLayoutMetrics(
          columns: 4,
          horizontalSpacing: 3,
          verticalSpacing: 2,
          padding: EdgeInsets.all(16),
        ),
      DeviceType.desktop => const WorkLayoutMetrics(
          columns: 6,
          horizontalSpacing: 4,
          verticalSpacing: 2,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
    };
  }

  static WorkLayoutMetrics listFor(DeviceType device) {
    return switch (device) {
      DeviceType.mobile => const WorkLayoutMetrics(
          columns: 1,
          horizontalSpacing: 8,
          verticalSpacing: 8,
          padding: EdgeInsets.all(8),
        ),
      DeviceType.tablet => const WorkLayoutMetrics(
          columns: 2,
          horizontalSpacing: 12,
          verticalSpacing: 10,
          padding: EdgeInsets.all(12),
        ),
      DeviceType.laptop => const WorkLayoutMetrics(
          columns: 3,
          horizontalSpacing: 12,
          verticalSpacing: 12,
          padding: EdgeInsets.all(16),
        ),
      DeviceType.desktop => const WorkLayoutMetrics(
          columns: 3,
          horizontalSpacing: 16,
          verticalSpacing: 12,
          padding: EdgeInsets.all(16),
        ),
    };
  }
}
