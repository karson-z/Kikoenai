class TagVo {
  final int? id;
  final String? name;

  TagVo({this.id, this.name});

  factory TagVo.fromJson(Map<String, dynamic> json) {
    return TagVo(
      id: json['id'] as int?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
