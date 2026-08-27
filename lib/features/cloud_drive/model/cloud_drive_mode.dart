enum CloudDriveMode { alistApi, webDav }

extension CloudDriveModeDisplay on CloudDriveMode {
  String get label => switch (this) {
    CloudDriveMode.alistApi => 'AList API',
    CloudDriveMode.webDav => 'WebDAV',
  };
}

enum CloudDriveScope {
  all(0, '全部'),
  folders(1, '文件夹'),
  files(2, '文件');

  const CloudDriveScope(this.apiValue, this.label);

  final int apiValue;
  final String label;
}

enum CloudDriveSort {
  defaultSort('默认顺序'),
  nameAsc('名称升序'),
  nameDesc('名称降序'),
  sizeAsc('大小升序'),
  sizeDesc('大小降序'),
  modifiedAsc('修改时间升序'),
  modifiedDesc('最近修改');

  const CloudDriveSort(this.label);

  final String label;
}
