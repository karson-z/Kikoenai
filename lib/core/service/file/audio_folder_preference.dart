import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai_core/core/model/local_media/file_node.dart';

/// 详情页文件区用来挑选格式文件夹的音效倾向。
enum AudioEffectPreference {
  /// 文件夹名标明没有音效。
  without('without', '无音效'),

  /// 文件夹名标明带有音效。
  withEffect('with', '有音效');

  const AudioEffectPreference(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static AudioEffectPreference? fromStorage(String value) {
    for (final preference in AudioEffectPreference.values) {
      if (preference.storageValue == value) return preference;
    }
    return null;
  }
}

/// 用户配置的两张表：格式顺序和音效顺序。
class AudioFolderPreference {
  const AudioFolderPreference({required this.formats, required this.effects});

  /// 初始格式顺序。只包含应用识别的八种音频扩展名。
  static const List<String> defaultFormats = [
    'mp3',
    'wav',
    'flac',
    'aac',
    'm4a',
    'ogg',
    'opus',
    'wma',
  ];

  /// 初始音效顺序：无音效优先于有音效。
  static const List<AudioEffectPreference> defaultEffects = [
    AudioEffectPreference.without,
    AudioEffectPreference.withEffect,
  ];

  static const AudioFolderPreference defaults = AudioFolderPreference(
    formats: defaultFormats,
    effects: defaultEffects,
  );

  final List<String> formats;
  final List<AudioEffectPreference> effects;

  factory AudioFolderPreference.fromStorage(Box<dynamic> box) {
    return AudioFolderPreference(
      formats: _readFormats(box.get(StorageKeys.audioFormatPreference)),
      effects: _readEffects(box.get(StorageKeys.audioEffectPreference)),
    );
  }

  Future<void> save(Box<dynamic> box) {
    return Future.wait([
      box.put(StorageKeys.audioFormatPreference, formats),
      box.put(
        StorageKeys.audioEffectPreference,
        effects.map((effect) => effect.storageValue).toList(),
      ),
    ]);
  }

  String get summary {
    final formatText = formats.take(3).join(' > ');
    final effect = effects.firstOrNull;
    if (effect == null) return formatText;
    return '$formatText · ${effect.label}优先';
  }

  static List<String> _readFormats(Object? stored) {
    if (stored is! List) return defaultFormats;
    final known = defaultFormats.toSet();
    final result = <String>[];
    for (final item in stored) {
      if (item is! String) continue;
      final format = item.toLowerCase();
      if (!known.contains(format) || result.contains(format)) continue;
      result.add(format);
    }
    for (final format in defaultFormats) {
      if (!result.contains(format)) result.add(format);
    }
    return result;
  }

  static List<AudioEffectPreference> _readEffects(Object? stored) {
    if (stored is! List) return defaultEffects;
    final result = <AudioEffectPreference>[];
    for (final item in stored) {
      if (item is! String) continue;
      final effect = AudioEffectPreference.fromStorage(item);
      if (effect == null || result.contains(effect)) continue;
      result.add(effect);
    }
    for (final effect in defaultEffects) {
      if (!result.contains(effect)) result.add(effect);
    }
    return result;
  }
}

/// 从一个文件夹名里读出的格式和音效。
class FolderAudioIdentity {
  const FolderAudioIdentity({this.format, this.effect});

  final String? format;
  final AudioEffectPreference? effect;

  bool get hasFormat => format != null;
}

/// 根目录或根目录下一层里，可以按两张表比较的候选文件夹。
class AudioFolderCandidate {
  const AudioFolderCandidate({
    required this.folder,
    required this.depth,
    required this.identity,
  });

  final NodeFolder folder;
  final int depth;
  final FolderAudioIdentity identity;
}

const Map<String, String> _formatAliases = {
  'wave': 'wav',
  'alac': 'm4a',
  'vorbis': 'ogg',
};

const Set<String> _formatModifiers = {
  'bit',
  'khz',
  'hz',
  'kbps',
  'kb',
  'k',
  '版',
  'ver',
  'version',
  'files',
  'file',
};

/// 无音效短语，长的排在前面，避免 `seなし` 被单独的 `se` 先认走。
const List<String> _withoutEffectPhrases = [
  '効果音カット',
  '効果音オフ',
  '効果音無し',
  '効果音なし',
  '効果音无',
  '効果音無',
  '效果音无',
  '效果音無',
  '无效果音',
  '無效果音',
  '无音效',
  '無音效',
  'seoff',
  'seオフ',
  'se_off',
  'se無し',
  'seなし',
  'se无',
  'se無',
  'no_se',
  'nose',
];

/// 有音效短语。单独的 `se` 最后认。
const List<String> _withEffectPhrases = [
  '効果音付き',
  '効果音有り',
  '効果音あり',
  '効果音入り',
  '効果音有',
  '效果音有',
  '有效果音',
  '有音效',
  '効果音',
  '效果音',
  '音效',
  'se_on',
  'seあり',
  'se有り',
  'se付き',
  'se入り',
  'se有',
  'se付',
  'se',
];

final List<String> _formatsByLength = [
  ...AudioFolderPreference.defaultFormats,
  ..._formatAliases.keys,
]..sort((a, b) => b.length.compareTo(a.length));

/// 读取文件夹名里的格式和音效。没有格式词时 [FolderAudioIdentity.format] 为 null。
FolderAudioIdentity readFolderAudioIdentity(String folderName) {
  final normalized = folderName.toLowerCase().replaceAllMapped(
    RegExp(r'[\uFF01-\uFF5E]'),
    (match) {
      final code = match.group(0)!.codeUnitAt(0);
      return String.fromCharCode(code - 0xFEE0);
    },
  );
  final withoutEffect = _consumeEffect(normalized, _withoutEffectPhrases);
  final withEffect = _consumeEffect(withoutEffect.text, _withEffectPhrases);
  final effect = switch ((withoutEffect.matched, withEffect.matched)) {
    (true, false) => AudioEffectPreference.without,
    (false, true) => AudioEffectPreference.withEffect,
    _ => null,
  };
  return FolderAudioIdentity(
    format: _readFormat(withEffect.text),
    effect: effect,
  );
}

/// 在根目录和根目录下一层里，按格式表、音效表挑一个文件夹。
///
/// 只接受能读出格式的位置。根上只有音效、下一层才是格式时，落到下一层；
/// 根上有格式但没写音效、下一层写了音效时，也落到下一层。找不到返回 null。
NodeFolder? pickPreferredAudioFolder({
  required List<NodeFolder> rootFolders,
  required List<NodeFolder> Function(NodeFolder folder) childrenOf,
  required AudioFolderPreference preference,
}) {
  final candidates = <AudioFolderCandidate>[];
  for (final folder in rootFolders) {
    final identity = readFolderAudioIdentity(folder.name);
    if (identity.hasFormat) {
      candidates.add(
        AudioFolderCandidate(folder: folder, depth: 1, identity: identity),
      );
    }

    for (final nested in childrenOf(folder)) {
      final resolved = _resolveNestedIdentity(
        parent: identity,
        child: readFolderAudioIdentity(nested.name),
      );
      if (resolved == null) continue;
      candidates.add(
        AudioFolderCandidate(folder: nested, depth: 2, identity: resolved),
      );
    }
  }
  if (candidates.isEmpty) return null;

  candidates.sort((a, b) {
    final formatCompare = _rank(
      preference.formats,
      a.identity.format,
    ).compareTo(_rank(preference.formats, b.identity.format));
    if (formatCompare != 0) return formatCompare;

    final effectCompare = _effectRank(
      preference,
      a.identity.effect,
    ).compareTo(_effectRank(preference, b.identity.effect));
    if (effectCompare != 0) return effectCompare;

    final depthCompare = a.depth.compareTo(b.depth);
    if (depthCompare != 0) return depthCompare;
    return a.folder.normalized.length.compareTo(b.folder.normalized.length);
  });
  return candidates.first.folder;
}

/// 下一层只有在补上另一张表缺的信息时才成为候选。
///
/// 根上是格式、下一层是章节时不下降。根上没写格式也没写音效时，
/// 不把 `本体/mp3` 这类下一层当成格式文件夹。
FolderAudioIdentity? _resolveNestedIdentity({
  required FolderAudioIdentity parent,
  required FolderAudioIdentity child,
}) {
  if (parent.hasFormat) {
    if (parent.effect != null || child.effect == null || child.hasFormat) {
      return null;
    }
    return FolderAudioIdentity(format: parent.format, effect: child.effect);
  }
  if (!child.hasFormat || parent.effect == null) return null;
  return FolderAudioIdentity(
    format: child.format,
    effect: child.effect ?? parent.effect,
  );
}

int _rank(List<String> order, String? value) {
  if (value == null) return order.length + 1;
  final index = order.indexOf(value);
  return index < 0 ? order.length : index;
}

/// 没写音效的文件夹排在首选音效之后、另一种之前。
int _effectRank(
  AudioFolderPreference preference,
  AudioEffectPreference? effect,
) {
  if (effect == null) return 1;
  final index = preference.effects.indexOf(effect);
  if (index < 0) return preference.effects.length + 1;
  return index == 0 ? 0 : 2;
}

({String text, bool matched}) _consumeEffect(
  String text,
  List<String> phrases,
) {
  var matched = false;
  var current = text;
  for (final phrase in phrases) {
    final pattern = RegExp('(?<![a-z0-9])${RegExp.escape(phrase)}(?![a-z0-9])');
    if (!pattern.hasMatch(current)) continue;
    matched = true;
    current = current.replaceAll(pattern, ' ');
  }
  return (text: current, matched: matched);
}

String? _readFormat(String text) {
  final tokens = text
      .split(RegExp(r'[^0-9a-z\u3040-\u30ff\u3400-\u9fff]+'))
      .where((token) => token.isNotEmpty);
  String? found;
  for (final token in tokens) {
    final format = _formatOfToken(token);
    if (format == null) continue;
    found ??= format;
  }
  return found;
}

String? _formatOfToken(String token) {
  for (final raw in _formatsByLength) {
    final canonical = _formatAliases[raw] ?? raw;
    if (token == raw || token == canonical) return canonical;
  }
  for (final raw in _formatsByLength) {
    if (!token.contains(raw)) continue;
    final stripped = token.replaceAll(raw, '');
    if (_isFormatModifier(stripped)) return _formatAliases[raw] ?? raw;
  }
  return null;
}

bool _isFormatModifier(String value) {
  if (value.isEmpty) return false;
  final parts = value
      .split(RegExp(r'(?<=\d)(?!\d)|(?<!\d)(?=\d)'))
      .where((part) => part.isNotEmpty);
  if (parts.isEmpty) return false;
  return parts.every(
    (part) =>
        RegExp(r'^\d+$').hasMatch(part) || _formatModifiers.contains(part),
  );
}
