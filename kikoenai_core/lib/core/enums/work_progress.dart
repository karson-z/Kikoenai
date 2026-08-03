enum WorkProgress {
  marked("marked"),       // 已标记/想听
  listening("listening"),     // 正在听
  listened("listened"), // 已听完
  replay("replay"),
  postponed("postponed"),
  unknown("unknown");     // 未知/默认

  final String value;
  const WorkProgress(this.value);

  // 字符串转枚举 (安全处理)
  static WorkProgress fromString(String? val) {
    return WorkProgress.values.firstWhere(
          (e) => e.value == val,
      orElse: () => WorkProgress.unknown,
    );
  }

  // 枚举转字符串
  String toJson() => value;
}
extension WorkProgressExtension on WorkProgress {
  String get label {
    switch (this) {
      case WorkProgress.marked:
        return "想听";
      case WorkProgress.listening:
        return "在听";
      case WorkProgress.listened:
        return "听完";
      case WorkProgress.replay:
        return "重播";
      case WorkProgress.postponed:
        return "搁置";
      case WorkProgress.unknown:
        return "标记";
    }
  }
}