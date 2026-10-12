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

  bool get _isDefaultField => _selectedField == FileSortField.defaultSort;

  @override
  void initState() {
    super.initState();
    final current = ref.read(fileSortProvider);
    _selectedField = current.field;
    _descending = current.descending;
  }

  @override
  Widget build(BuildContext context) {
    return KikoenaiAlertDialog(
      titleText: '排序方式',
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
          // “默认”表示保持原始返回顺序，倒序对它没有意义，直接禁用。
          SwitchListTile(
            title: const Text('倒序'),
            value: _isDefaultField ? false : _descending,
            onChanged: _isDefaultField
                ? null
                : (value) => setState(() => _descending = value),
          ),
        ],
      ),
      actions: [
        KikoenaiAlertDialog.textAction(
          context,
          label: '取消',
          onPressed: () => Navigator.of(context).pop(),
        ),
        KikoenaiAlertDialog.textAction(
          context,
          label: '确认',
          isConfirm: true,
          onPressed: () {
            ref.read(fileSortProvider.notifier).update(
                  FileSortOption(
                    field: _selectedField,
                    descending: _isDefaultField ? false : _descending,
                  ),
                );
            Navigator.of(context).pop();
          },
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
