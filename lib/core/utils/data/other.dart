import 'package:audio_service/audio_service.dart';
import '../../../features/album/data/model/va.dart';

/// 工具类，提供与 VA（声优）、页面路由和 MediaItem 相关的常用方法
class OtherUtil {

  /// 将 [VA] 列表中的 name 字段拼接为一个字符串，用 '/' 分隔
  /// - 会过滤掉 name 为 null 或空字符串的项
  /// - 如果 [vas] 为 null 或空列表，则返回空字符串
  /// 示例：
  /// ```dart
  /// final vas = [VA(name: 'A'), VA(name: null), VA(name: 'B')];
  /// final result = OtherUtil.joinVAs(vas); // "A/B"
  /// ```
  static String joinVAs(List<VA>? vas) {
    if (vas == null || vas.isEmpty) return '';
    final names = vas
        .where((va) => va.name != null && va.name!.isNotEmpty)
        .map((va) => va.name!.trim());
    return names.join('/');
  }

  /// 判断给定 [location] 是否属于全屏页面
  /// - 例如播放器页面可能是全屏展示，不显示底部导航栏
  /// - 可以在 Scaffold 或导航逻辑中使用
  /// 示例：
  /// ```dart
  /// final isFullScreen = OtherUtil.isFullScreenPage('/album/detail'); // true
  /// ```
  static bool isFullScreenPage(String location) {
    const fullScreenRoutes = [
      '/album/detail',
      '/settingsTheme',
    ];
    return fullScreenRoutes.contains(location);
  }

  /// 将 [MediaItem] 转换为 Map，用于存储或序列化为 JSON
  /// - duration 会转换为毫秒数
  /// - extras 会保持 Map<String, dynamic> 形式
  /// 示例：
  /// ```dart
  /// final map = OtherUtil.mediaItemToMap(mediaItem);
  /// ```
  static Map<String, dynamic> mediaItemToMap(MediaItem item) {
    return {
      'id': item.id,
      'album': item.album,
      'title': item.title,
      'artist': item.artist,
      'duration': item.duration?.inMilliseconds,
      'extras': item.extras,
    };
  }

  /// 将 Map 反序列化为 [MediaItem]
  /// - [duration] 以毫秒恢复为 Duration 对象
  /// - [extras] 会被转换为 Map<String, dynamic>
  /// 示例：
  /// ```dart
  /// final mediaItem = OtherUtil.mediaItemFromMap(map);
  /// ```
  static MediaItem mediaItemFromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] ?? '',
      album: map['album'],
      title: map['title'] ?? '',
      artist: map['artist'],
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'])
          : null,
      extras: map['extras'] != null
          ? Map<String, dynamic>.from(map['extras'])
          : null,
    );
  }
}
