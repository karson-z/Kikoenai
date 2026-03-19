import 'package:flutter/material.dart';
import 'package:kikoenai/core/service/audio/audio_extension.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/service/audio/audio_service_ctrl.dart';
import '../../../../core/service/audio/audio_service_media_kit.dart';

class PlayerVideoContent extends StatefulWidget {
  const PlayerVideoContent({super.key});

  @override
  State<PlayerVideoContent> createState() => _PlayerVideoContentState();
}

class _PlayerVideoContentState extends State<PlayerVideoContent> {
  // 声明底层渲染控制器
  late final VideoController _videoController;

  @override
  void initState() {
    super.initState();
    // 利用之前写的 extension，直接从单例中安全地获取 VideoController
    _videoController = AudioServiceSingleton.instance.videoController;
  }
  @override
  void dispose() {
    super.dispose();
    AudioServiceSingleton.instance.toggleVideoDecoding(false);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      // 视频播放器背景通常强制为黑色，防止不同比例的视频出现白边
      color: Colors.black,
      child: Center(
        child: Video(
          controller: _videoController,

          // --- 控制器 UI 配置 ---
          // MaterialVideoControls：提供标准的播放/暂停、进度条、全屏、音量手势等
          // 如果你希望视频像 Spotify 的 Canvas 一样纯粹作为动态背景，
          // 且用户只能通过你自己的底栏来控制播放，请将其改为 `NoVideoControls`
          controls: MaterialVideoControls,

          // --- 画面缩放配置 ---
          // BoxFit.contain: 保持原比例，留黑边（推荐，能看全画面）
          // BoxFit.cover: 保持比例铺满容器，画面边缘可能会被裁切
          fit: BoxFit.contain,

          // --- 占位图设置 ---
          // 视频在刚切过来、还在解码第一帧时的背景图
          // 可以传入当前的专辑封面图以实现更平滑的过渡
          fill: Colors.transparent,
        ),
      ),
    );
  }
}