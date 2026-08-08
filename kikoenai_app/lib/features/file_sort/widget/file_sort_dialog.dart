import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/common/kikoenai_dialog.dart';
import '../provider/file_sort_provider.dart';
import '../provider/file_sort_option.dart';

class FileSortDialog {
  static Future<void> show(BuildContext context) {
    return KikoenaiDialog.show<void>(
      context: context,
      builder: (context) => const _FileSortDialogBody(),
    );
  }
}

class _FileSortDialogBody extends ConsumerStatefulWidget {
  const _FileSortDialogBody();

  @override
  ConsumerState<_FileSortDialogBody> createState() => _FileSortDialogBodyState();
}

class _FileSortDialogBodyState extends ConsumerState<_FileSortDialogBody> {
  late FileSortField _selectedField;
  late bool _descending;

  @override
  void initState() {
    super.initState();
    final current = ref.read(fileSortProvider);
    _selectedField = current.field;
    _descending = current.descending;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('排序方式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<FileSortField>(
            groupValue: _selectedField,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedField = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in FileSortField.values)
                  RadioListTile<FileSortField>(
                    value: field,
                    title: Text(_fieldLabel(field)),
                  ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('倒序'),
            value: _descending,
            onChanged: (value) => setState(() => _descending = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(fileSortProvider.notifier).update(
                  FileSortOption(
                    field: _selectedField,
                    descending: _descending,
                  ),
                );
            Navigator.of(context).pop();
          },
          child: const Text('确认'),
        ),
      ],
    );
  }

  String _fieldLabel(FileSortField field) {
    switch (field) {
      case FileSortField.defaultSort:
        return '默认';
      case FileSortField.title:
        return '标题';
      case FileSortField.titleNumber:
        return '标题序号';
      case FileSortField.duration:
        return '时长';
      case FileSortField.size:
        return '文件大小';
    }
  }
}
