import 'package:flutter/material.dart';

class AppUseExplain {
  // 定义结构化数据
  static const List<Map<String, dynamic>> importRules = [
    {
      'title': '单文件 / 多文件模式',
      'icon': Icons.insert_drive_file_outlined,
      'color': Colors.blue,
      'rules': [
        {
          'label': '智能匹配当前目录',
          'content': '如果当前所在的目录名已是一个 ID（例如你已进入 /RJ123456 目录），文件将直接导入该目录。'
        },
        {
          'label': '自动识别文件名',
          'content': '如果源文件名包含 ID（例如 "RJ123456.mp4"），会自动创建并导入到 "/根目录/RJ123456/"。'
        },
        {
          'label': '日期归档 (兜底)',
          'content': '如果以上都没匹配到，系统将创建一个以当天日期命名的文件夹（例如 "/根目录/2025-12-14/"）并放入其中。'
        },
      ]
    },
    {
      'title': '文件夹模式',
      'icon': Icons.folder_open_outlined,
      'color': Colors.orange,
      'rules': [
        {
          'label': '智能识别',
          'content': '如果源文件夹名字包含 ID，内容将导入到 "/根目录/ID/"。'
        },
        {
          'label': '默认策略',
          'content': '如果没有 ID，内容将导入到 "/根目录/源文件夹名/"。'
        },
      ]
    },
  ];
}