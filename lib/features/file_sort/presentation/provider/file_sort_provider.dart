import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../domain/file_sort_option.dart';

final fileSortProvider = NotifierProvider<FileSortNotifier, FileSortOption>(
  FileSortNotifier.new,
);

class FileSortNotifier extends Notifier<FileSortOption> {
  @override
  FileSortOption build() {
    return FileSortOption.fromStorage(AppStorage.settingsBox);
  }

  void update(FileSortOption option) {
    option.saveToStorage(AppStorage.settingsBox);
    state = option;
  }
}
