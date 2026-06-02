import 'package:kikoenai/core/constants/app_file_extensions.dart';

enum ScanMode { audio, video, subtitles }

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
