class CirclesInfo {
  final int? id;
  final String? circleName;
  final String? circleDesc;
  final int? status;
  final int? workCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CirclesInfo({
    this.id,
    this.circleName,
    this.circleDesc,
    this.status,
    this.workCount,
    this.createdAt,
    this.updatedAt,
  });

  /// 从 JSON 转换成对象
  factory CirclesInfo.fromJson(Map<String, dynamic> json) {
    return CirclesInfo(
      id: json['id'] as int?,
      circleName: json['circleName'] as String?,
      circleDesc: json['circleDesc'] as String?,
      status: json['status'] as int?,
      workCount: json['workCount'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  /// 对象转 JSON（用于提交或缓存）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circleName': circleName,
      'circleDesc': circleDesc,
      'status': status,
      'workCount': workCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'CirclesInfo(id: $id, circleName: $circleName, workCount: $workCount)';
}
