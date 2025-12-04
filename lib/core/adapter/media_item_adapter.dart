import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';

class MediaItemAdapter extends TypeAdapter<MediaItem> {
  @override
  final int typeId = 2;

  @override
  MediaItem read(BinaryReader reader) {
    return MediaItem(
      id: reader.readString(),
      title: reader.readString(),
      artist: reader.readString(),
      album: reader.readString(),
      duration: Duration(milliseconds: reader.readInt()),
      extras: reader.readMap().cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, MediaItem item) {
    writer.writeString(item.id);
    writer.writeString(item.title);
    writer.writeString(item.artist ?? '');
    writer.writeString(item.album ?? '');
    writer.writeInt(item.duration?.inMilliseconds ?? 0);
    writer.writeMap(castMap(item.extras));
  }
}
Map<String, dynamic> castMap(Map<dynamic, dynamic>? raw) {
  if (raw == null) return {};
  return raw.map(
        (key, value) => MapEntry(key.toString(), value),
  );
}