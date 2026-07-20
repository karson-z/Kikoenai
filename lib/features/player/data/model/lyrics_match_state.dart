import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kikoenai/core/model/file_node.dart';

part 'lyrics_match_state.freezed.dart';

@freezed
abstract class LyricsMatchState with _$LyricsMatchState {
  const factory LyricsMatchState({
    @Default(null) int? currentWorkId,
    @Default({}) Map<String, FileNode?> subtitleMapping,
    @Default([]) List<FileNode> lyricsList,
    @Default(false) bool isSearching,
  }) = _LyricsMatchState;
}