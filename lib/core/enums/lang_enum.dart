import 'package:flutter/material.dart';
import '../model/filter_option_item.dart';

enum LangEnum implements FilterOptionItem {
  // 对应 $lang:JPN$
  jpn("日本語", "JPN", Colors.pinkAccent),

  // 对应 $lang:ENG$
  eng("English", "ENG", Colors.indigo),

  // 对应 $lang:CHI_HANS$
  chiHans("简体中文", "CHI_HANS", Colors.red),

  // 对应 $lang:CHI_HANT$
  chiHant("繁體中文", "CHI_HANT", Colors.redAccent),

  // 对应 $lang:CHI$ (通常指通用中文或未区分)
  chi("中文", "CHI", Colors.deepOrange),

  // 对应 $lang:KO_KR$
  kor("한국어", "KO_KR", Colors.teal),

  // 对应 $lang:SPA$
  spa("Español", "SPA", Colors.orange),

  // 对应 $lang:ITA$
  ita("Italiano", "ITA", Colors.green),

  // 对应 $lang:GER$
  ger("Deutsch", "GER", Colors.amber),

  // 对应 $lang:FRE$
  fre("Français", "FRE", Colors.lightBlue);

  @override
  final String label;
  @override
  final String value;
  @override
  final Color activeColor;

  const LangEnum(this.label, this.value, this.activeColor);
}