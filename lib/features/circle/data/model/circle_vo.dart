class CircleVo {
  final int? circleId;
  final String? circleName;

  CircleVo({this.circleId, this.circleName});

  factory CircleVo.fromJson(Map<String, dynamic> json) {
    return CircleVo(
      circleId: json['circleId'] as int?,
      circleName: json['circleName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'circleId': circleId,
        'circleName': circleName,
      };
}
