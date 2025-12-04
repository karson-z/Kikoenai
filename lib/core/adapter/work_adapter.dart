import 'dart:convert';

import 'package:hive/hive.dart';

import '../../features/album/data/model/work.dart';

class WorkAdapter extends TypeAdapter<Work> {
  @override
  int get typeId => 101; // 确保全局唯一，自己定义一个

  @override
  Work read(BinaryReader reader) {
    final jsonString = reader.readString();
    final map = jsonDecode(jsonString);
    return Work.fromJson(Map<String, dynamic>.from(map));
  }

  @override
  void write(BinaryWriter writer, Work obj) {
    final map = obj.toJson();
    final jsonString = jsonEncode(map);
    writer.writeString(jsonString);
  }
}