import 'package:hive_ce/hive.dart';
import 'package:audio_service/audio_service.dart';

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 2; // 确保 ID 唯一

  @override
  MediaItem read(BinaryReader reader) {
    // 1. 基本 String 字段
    final id = reader.read() as String;
    final title = reader.read() as String;
    final artist = reader.read() as String?;
    final album = reader.read() as String?;
    final genre = reader.read() as String?;

    // 2. Duration (读 int -> 转 Duration)
    final durationMs = reader.read() as int?;
    final duration = durationMs != null ? Duration(milliseconds: durationMs) : null;

    // 3. ArtUri (读 String -> 转 Uri)
    final artUriString = reader.read() as String?;
    final artUri = artUriString != null ? Uri.tryParse(artUriString) : null;

    // 4. Headers Map
    final artHeaders = (reader.read() as Map?)?.cast<String, String>();

    // 5. 其他布尔和显示字段
    final playable = reader.read() as bool?;
    final displayTitle = reader.read() as String?;
    final displaySubtitle = reader.read() as String?;
    final displayDescription = reader.read() as String?;
    final isLive = reader.read() as bool?;

    // 6. Extras Map
    final extras = (reader.read() as Map?)?.cast<String, dynamic>();

    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      duration: duration,
      artUri: artUri,
      artHeaders: artHeaders,
      playable: playable,
      displayTitle: displayTitle,
      displaySubtitle: displaySubtitle,
      displayDescription: displayDescription,
      isLive: isLive,
      rating: null, // 显式设为 null，因为我们不存储它
      extras: extras,
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {
    // 注意：写入顺序必须严格匹配读取顺序

    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.artist);
    writer.write(obj.album);
    writer.write(obj.genre);

    // 1. Duration 转 int 存储
    writer.write(obj.duration?.inMilliseconds);

    // 2. Uri 转 String 存储
    writer.write(obj.artUri?.toString());

    // 3. Headers Map
    writer.write(obj.artHeaders);

    writer.write(obj.playable);
    writer.write(obj.displayTitle);
    writer.write(obj.displaySubtitle);
    writer.write(obj.displayDescription);
    writer.write(obj.isLive);

    // 4. Extras Map
    writer.write(obj.extras);
  }
}