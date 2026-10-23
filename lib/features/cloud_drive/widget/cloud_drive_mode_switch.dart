import 'package:flutter/material.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';

import '../model/cloud_drive_mode.dart';

class CloudDriveModeSwitch extends StatelessWidget {
  const CloudDriveModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final CloudDriveMode value;
  final ValueChanged<CloudDriveMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_outlined, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '云盘',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    final switcher = SegmentedButton<CloudDriveMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, 30)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
        shape: WidgetStatePropertyAll(StadiumBorder()),
      ),
      segments: const [
        ButtonSegment(
          value: CloudDriveMode.alistApi,
          label: Text('AList'),
        ),
        ButtonSegment(
          value: CloudDriveMode.webDav,
          label: Text('WebDAV'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (values) => onChanged(values.single),
    );

    return Padding(
      padding: context.layout.pagePadding(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(child: title),
          const SizedBox(width: 12),
          switcher,
        ],
      ),
    );
  }
}
