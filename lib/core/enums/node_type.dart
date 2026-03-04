import 'package:hive_ce/hive.dart';

part 'node_type.g.dart';

@HiveType(typeId: 13)
enum NodeType {
  @HiveField(0)
  folder,
  @HiveField(1)
  audio,
  @HiveField(2)
  image,
  @HiveField(3)
  text,
  @HiveField(4)
  video,
  @HiveField(5)
  other,
  @HiveField(6)
  unknown,
}