

import 'package:hive_ce/hive.dart';

import '../../features/album/data/model/work.dart';
import '../model/history_entry.dart';

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  int get typeId => 203;

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    // 保存 Work 对象
    writer.write(obj.work);

    // 保存最后播放曲目信息
    writer.writeString(obj.lastTrackId ?? '');
    writer.writeString(obj.currentTrackTitle ?? '');
    writer.writeInt(obj.lastProgressMs ?? 0);

    // 保存更新时间戳
    writer.writeInt(obj.updatedAt);
  }

  @override
  HistoryEntry read(BinaryReader reader) {
    final work = reader.read() as Work;

    // 读取最后播放曲目信息
    final lastTrackId = reader.readString();
    final currentTrackTitle = reader.readString();
    final lastProgressMs = reader.readInt();

    // 读取更新时间戳
    final updatedAt = reader.readInt();

    return HistoryEntry(
      work: work,
      lastTrackId: lastTrackId.isEmpty ? null : lastTrackId,
      currentTrackTitle: currentTrackTitle.isEmpty ? null : currentTrackTitle,
      lastProgressMs: lastProgressMs == 0 ? null : lastProgressMs,
      updatedAt: updatedAt,
    );
  }
}
