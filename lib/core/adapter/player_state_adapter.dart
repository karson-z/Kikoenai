import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/widgets/player/state/player_state.dart';
import 'package:kikoenai/core/widgets/player/state/progress_state.dart';
import 'package:kikoenai/features/album/data/model/file_node.dart'; // 确保导入 FileNode

class PlayerStateAdapter extends TypeAdapter<AppPlayerState> {
  @override
  int get typeId => 3;

  @override
  AppPlayerState read(BinaryReader reader) {
    // 1. 先按顺序读取基础字段
    final playing = reader.readBool();
    final loading = reader.readBool();
    final progressBarState = reader.read() as ProgressBarState;
    final currentTrack = reader.read() as MediaItem?;
    final playlist = (reader.readList().cast<MediaItem>());
    final isFirst = reader.readBool();
    final isLast = reader.readBool();
    final shuffleEnabled = reader.readBool();
    final repeatMode = AudioServiceRepeatMode.values[reader.readInt()];
    final volume = reader.readDouble();

    // 2. 读取新增字段 (包含兼容性检查)
    // 如果是旧数据，availableBytes 将为 0，跳过读取以防止 EOF 错误
    List<FileNode> subtitleList = [];
    FileNode? currentSubtitle;

    if (reader.availableBytes > 0) {
      // 必须确保 FileNode 也有注册 TypeAdapter
      subtitleList = (reader.readList().cast<FileNode>());
    }

    if (reader.availableBytes > 0) {
      currentSubtitle = reader.read() as FileNode?;
    }

    // 3. 构建对象
    return AppPlayerState(
      playing: playing,
      loading: loading,
      progressBarState: progressBarState,
      currentTrack: currentTrack,
      playlist: playlist,
      isFirst: isFirst,
      isLast: isLast,
      shuffleEnabled: shuffleEnabled,
      repeatMode: repeatMode,
      volume: volume,
      subtitleList: subtitleList,
      currentSubtitle: currentSubtitle,
    );
  }

  @override
  void write(BinaryWriter writer, AppPlayerState obj) {
    writer.writeBool(obj.playing);
    writer.writeBool(obj.loading);
    writer.write(obj.progressBarState);
    writer.write(obj.currentTrack);
    writer.writeList(obj.playlist);
    writer.writeBool(obj.isFirst);
    writer.writeBool(obj.isLast);
    writer.writeBool(obj.shuffleEnabled);
    writer.writeInt(obj.repeatMode.index);
    writer.writeDouble(obj.volume);
    writer.writeList(obj.subtitleList);
    writer.write(obj.currentSubtitle);
  }
}