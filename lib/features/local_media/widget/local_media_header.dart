import 'package:flutter/material.dart';
import 'package:kikoenai_core/kikoenai_core.dart';

class LocalMediaHeader extends StatelessWidget {
  const LocalMediaHeader({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ScanMode value;
  final ValueChanged<ScanMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.library_music_outlined, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '本地媒体',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(child: title),
          const SizedBox(width: 8),
          SegmentedButton<ScanMode>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(0, 30)),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 6),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 10.5)),
              shape: WidgetStatePropertyAll(StadiumBorder()),
            ),
            segments: const [
              ButtonSegment(value: ScanMode.audio, label: Text('音频')),
              ButtonSegment(value: ScanMode.video, label: Text('视频')),
              ButtonSegment(value: ScanMode.subtitles, label: Text('字幕')),
            ],
            selected: {value},
            onSelectionChanged: (values) => onChanged(values.single),
          ),
        ],
      ),
    );
  }
}
