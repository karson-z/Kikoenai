import 'package:flutter/material.dart';

import '../model/filter_option_item.dart';

enum DurationEnum implements FilterOptionItem {
  over10("10分钟+", "10", Colors.teal),
  over20("20分钟+", "20", Colors.teal),
  over45("45分钟+ (长篇)", "45", Colors.teal),
  over90("1.5小时+ (全长)", "90", Colors.tealAccent);

  @override
  final String label;
  @override
  final String value;
  @override
  final Color activeColor;

  const DurationEnum(this.label, this.value, this.activeColor);
}