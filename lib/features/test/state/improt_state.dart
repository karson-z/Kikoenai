class ImportState {
  final double progress; // 0.0 到 1.0
  final String currentFile;

  const ImportState({
    this.progress = 0.0,
    this.currentFile = '',
  });

  ImportState copyWith({double? progress, String? currentFile}) {
    return ImportState(
      progress: progress ?? this.progress,
      currentFile: currentFile ?? this.currentFile,
    );
  }
}