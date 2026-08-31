import 'package:kikoenai_core/kikoenai_core.dart';

enum AlbumDetailMode { remote, dlLibrary }

class AlbumDetailArgs {
  const AlbumDetailArgs({
    this.work,
    this.workId,
    this.mode = AlbumDetailMode.remote,
  });

  final Work? work;
  final int? workId;
  final AlbumDetailMode mode;

  int get resolvedWorkId => workId ?? work?.id ?? 0;

  static AlbumDetailArgs fromExtra(Object? extra) {
    if (extra is AlbumDetailArgs) return extra;
    if (extra is! Map) return const AlbumDetailArgs();

    final rawWork = extra['work'];
    final Work? work = switch (rawWork) {
      Work value => value,
      Map value => Work.fromJson(Map<String, dynamic>.from(value)),
      _ => null,
    };
    final rawMode = extra['mode'];
    final mode = rawMode is AlbumDetailMode
        ? rawMode
        : rawMode == AlbumDetailMode.dlLibrary.name
        ? AlbumDetailMode.dlLibrary
        : AlbumDetailMode.remote;

    return AlbumDetailArgs(
      work: work,
      workId: extra['workId'] as int?,
      mode: mode,
    );
  }
}
