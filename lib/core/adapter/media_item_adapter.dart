
import 'package:hive_ce/hive.dart';
import 'package:audio_service/audio_service.dart';

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 2;

  @override
  MediaItem read(BinaryReader reader) {

    final id = reader.read() as String;
    final title = reader.read() as String;
    final artist = reader.read() as String?;
    final album = reader.read() as String?;

    // 处理 Duration (存的是 int 毫秒)
    final durationMs = reader.read() as int?;
    final duration = durationMs != null ? Duration(milliseconds: durationMs) : null;

    // 处理 Map
    final extras = (reader.read() as Map?)?.cast<String, dynamic>();

    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      extras: extras,
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem obj) {

    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.artist); // Hive 会自动处理 null
    writer.write(obj.album);

    // Duration 转 int 存储
    writer.write(obj.duration?.inMilliseconds);

    // 写入 Map
    writer.write(obj.extras);
  }
}