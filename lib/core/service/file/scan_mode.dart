import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/core/constants/app_typeIds.dart';

part 'scan_mode.g.dart';

@HiveType(typeId: TypeIds.scanMode, adapterName: 'ScanModeAdapter')
enum ScanMode {
  @HiveField(0)
  audio,
  @HiveField(1)
  video,
  @HiveField(2)
  subtitles,
}

extension ScanModeConfig on ScanMode {
  Set<String> get extensions {
    switch (this) {
      case ScanMode.audio:
        return FileExtensions.audio;

      case ScanMode.video:
        return FileExtensions.video;

      case ScanMode.subtitles:
        return FileExtensions.subtitles;
    }
  }

  bool get scanArchives => this == ScanMode.subtitles;
}
