class Tag {
  final int id;
  final String name;
  final int num;
  final DateTime createdAt;
  final bool? isLike;
  final bool? isDisLike;

  Tag({
    required this.id,
    required this.name,
    required this.num,
    required this.createdAt,
    this.isLike,
    this.isDisLike,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      num: json['num'],
      createdAt: DateTime.parse(json['createdAt']),
      isLike: json['isLike'],
      isDisLike: json['isDisLike'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'num': num,
        'createdAt': createdAt.toIso8601String(),
        'isLike': isLike,
        'isDisLike': isDisLike,
      };
}
