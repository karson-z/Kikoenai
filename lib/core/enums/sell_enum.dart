import 'package:flutter/material.dart';

import '../model/filter_option_item.dart';

enum SellEnum implements FilterOptionItem {
  over100("100+", "100", Colors.deepOrange),
  over1000("1000+ (热门)", "1000", Colors.deepOrange),
  over5000("5000+ (爆款)", "5000", Colors.deepOrange),
  over10000("1万+ (殿堂)", "10000", Colors.red);

  @override
  final String label;
  @override
  final String value;
  @override
  final Color activeColor;

  const SellEnum(this.label, this.value, this.activeColor);
}