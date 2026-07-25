// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppPlayerStateAdapter extends TypeAdapter<AppPlayerState> {
  @override
  final typeId = 50;

  @override
  AppPlayerState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppPlayerState(
      playing: fields[0] == null ? false : fields[0] as bool,
      loading: fields[1] == null ? false : fields[1] as bool,
      progressBarState: fields[2] == null
          ? const ProgressBarState(
              current: Duration.zero,
              buffered: Duration.zero,
              total: Duration.zero,
            )
          : fields[2] as ProgressBarState,
      isFirst: fields[5] == null ? true : fields[5] as bool,
      isLast: fields[6] == null ? true : fields[6] as bool,
      shuffleEnabled: fields[7] == null ? false : fields[7] as bool,
      repeatMode: fields[8] == null
          ? AudioServiceRepeatMode.none
          : fields[8] as AudioServiceRepeatMode,
      volume: fields[9] == null ? 1.0 : (fields[9] as num).toDouble(),
      isAudioOnly: fields[12] == null ? false : fields[12] as bool,
      session: fields[13] as PlaybackSession?,
    );
  }

  @override
  void write(BinaryWriter writer, AppPlayerState obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.playing)
      ..writeByte(1)
      ..write(obj.loading)
      ..writeByte(2)
      ..write(obj.progressBarState)
      ..writeByte(5)
      ..write(obj.isFirst)
      ..writeByte(6)
      ..write(obj.isLast)
      ..writeByte(7)
      ..write(obj.shuffleEnabled)
      ..writeByte(8)
      ..write(obj.repeatMode)
      ..writeByte(9)
      ..write(obj.volume)
      ..writeByte(12)
      ..write(obj.isAudioOnly)
      ..writeByte(13)
      ..write(obj.session);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPlayerStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
