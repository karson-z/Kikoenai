import 'package:hive_ce/hive.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

part 'progress_state.g.dart';

@HiveType(typeId: TypeIds.progressBarState, adapterName: 'ProgressBarStateAdapter')
class ProgressBarState {
  const ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });

  @HiveField(0)
  final Duration current;

  @HiveField(1)
  final Duration buffered;

  @HiveField(2)
  final Duration total;
}
