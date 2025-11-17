import 'package:flutter/material.dart';
import '../core/enums/device_type.dart';
import 'card_layout_config.dart';
import 'list_layout_config.dart';

enum WorkListLayoutType {
  card,
  list,
}

class WorkListLayout {
  final WorkListLayoutType layoutType;

  const WorkListLayout({required this.layoutType});

  DeviceType getDeviceType(BuildContext context) =>
      DeviceType.fromWidth(MediaQuery.of(context).size.width);

  int getColumnsCount(BuildContext context) {
    final device = getDeviceType(context);
    switch (layoutType) {
      case WorkListLayoutType.card:
        return CardWorkLayoutConfig.getColumnsCount(device);
      case WorkListLayoutType.list:
        return ListWorkLayoutConfig.getColumns(device);
    }
  }

  double getRowSpacing(BuildContext context) {
    final device = getDeviceType(context);
    switch (layoutType) {
      case WorkListLayoutType.card:
        return CardWorkLayoutConfig.getVerticalSpacing(device);
      case WorkListLayoutType.list:
        return ListWorkLayoutConfig.getVerticalSpacing(device);
    }
  }

  double getColumnSpacing(BuildContext context) {
    final device = getDeviceType(context);
    switch (layoutType) {
      case WorkListLayoutType.card:
        return CardWorkLayoutConfig.getHorizontalSpacing(device);
      case WorkListLayoutType.list:
        return ListWorkLayoutConfig.getHorizontalSpacing(device);
    }
  }

  EdgeInsets getPadding(BuildContext context) {
    final device = getDeviceType(context);
    switch (layoutType) {
      case WorkListLayoutType.card:
        return CardWorkLayoutConfig.getPadding(device);
      case WorkListLayoutType.list:
        return ListWorkLayoutConfig.getPadding(device);
    }
  }
}
