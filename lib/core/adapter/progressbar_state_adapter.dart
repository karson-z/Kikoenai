import 'package:hive/hive.dart';
import 'package:kikoenai/core/widgets/player/state/progress_state.dart';

import '../widgets/player/provider/player_controller_provider.dart';

class ProgressBarStateAdapter extends TypeAdapter<ProgressBarState> {
  @override
  int get typeId => 1;

  @override
  ProgressBarState read(BinaryReader reader) {
    return ProgressBarState(
      current: Duration(milliseconds: reader.readInt()),
      buffered: Duration(milliseconds: reader.readInt()),
      total: Duration(milliseconds: reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ProgressBarState obj) {
    writer.writeInt(obj.current.inMilliseconds);
    writer.writeInt(obj.buffered.inMilliseconds);
    writer.writeInt(obj.total.inMilliseconds);
  }
}