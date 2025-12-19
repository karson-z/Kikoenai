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
  static const List<Map<String, dynamic>> scannerRules = [
    {
      'title': '支持的文件类型',
      'icon': Icons.library_music_outlined,
      'color': Colors.green,
      'rules': [
        {
          'label': '支持音频与视频',
          'content': '本地扫描支持音频文件和视频文件。'
        },
        {
          'label': '路径独立管理',
          'content': '音频与视频的扫描路径是分开管理的，互不影响。'
        },
        {
          'label': '文件夹建议',
          'content': '建议分别放在不同文件夹中（不分开也可以正常使用）。'
        },
      ]
    },
    {
      'title': '封面获取规则（rjCode）',
      'icon': Icons.image_outlined,
      'color': Colors.purple,
      'rules': [
        {
          'label': '推荐放置方式',
          'content': '建议将文件放在包含 rjCode 的文件夹路径下。'
        },
        {
          'label': '路径包含 rjCode',
          'content': '如果路径中存在 rjCode，播放时会自动显示对应作品封面。'
        },
        {
          'label': '路径不包含 rjCode',
          'content': '如果路径中未检测到 rjCode，则不显示封面，仅使用音频文件自带信息。'
        },
      ]
    },
    {
      'title': '本地播放说明',
      'icon': Icons.play_circle_outline,
      'color': Colors.blueGrey,
      'rules': [
        {
          'label': '播放历史',
          'content': '当前版本暂不支持本地播放历史记录功能。'
        },
      ]
    },
    {
      'title': '扫描数量建议',
      'icon': Icons.warning_amber_outlined,
      'color': Colors.orange,
      'rules': [
        {
          'label': '单文件夹限制',
          'content': '为保证扫描速度和稳定性，单个文件夹内建议不超过 2000 个文件。'
        },
        {
          'label': '性能提示',
          'content': '文件数量过多可能导致扫描变慢或界面卡顿。'
        },
      ]
    },
  ];
}