import 'package:flutter/material.dart';

import '../model/filter_option_item.dart';

enum PriceEnum implements FilterOptionItem {
  paid("100円+", "100", Colors.green), // 大于1，即排除免费
  over50("1000円+", "1000", Colors.green),
  over100("3000円+", "3000", Colors.green);

  @override
  final String label;
  @override
  final String value;
  @override
  final Color activeColor;

  const PriceEnum(this.label, this.value, this.activeColor);
}