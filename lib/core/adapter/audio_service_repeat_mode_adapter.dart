import 'package:audio_service/audio_service.dart';
import 'package:hive_ce/hive.dart';

import '../constants/app_typeIds.dart';

class AudioServiceRepeatModeAdapter extends TypeAdapter<AudioServiceRepeatMode> {
  @override
  final int typeId = TypeIds.repeatMode; // 只要不重复即可

  @override
  AudioServiceRepeatMode read(BinaryReader reader) {
    return AudioServiceRepeatMode.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, AudioServiceRepeatMode obj) {
    writer.writeInt(obj.index);
  }
}