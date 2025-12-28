import 'package:flutter/material.dart';

import '../model/filter_option_item.dart';

enum RateEnum implements FilterOptionItem {
  over3("3分+", "3", Colors.amber),
  over4("4分+ (好评)", "4", Colors.amber),
  over45("4.5分+ (神作)", "4.5", Colors.orange);

  @override
  final String label;
  @override
  final String value;
  @override
  final Color activeColor;

  const RateEnum(this.label, this.value, this.activeColor);
}