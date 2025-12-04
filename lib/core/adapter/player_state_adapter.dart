import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:kikoenai/core/widgets/player/state/player_state.dart';
import 'package:kikoenai/core/widgets/player/state/progress_state.dart';


class PlayerStateAdapter extends TypeAdapter<AppPlayerState> {
  @override
  int get typeId => 3;

  @override
  AppPlayerState read(BinaryReader reader) {
    return AppPlayerState(
      playing: reader.readBool(),
      loading: reader.readBool(),
      progressBarState: reader.read() as ProgressBarState,
      currentTrack: reader.read() as MediaItem?,
      playlist: (reader.readList().cast<MediaItem>()),
      isFirst: reader.readBool(),
      isLast: reader.readBool(),
      shuffleEnabled: reader.readBool(),
      repeatMode:
      AudioServiceRepeatMode.values[reader.readInt()],
      volume: reader.readDouble(),
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
  }
}
