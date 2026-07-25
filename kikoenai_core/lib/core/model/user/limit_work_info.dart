class LimitWorkInfo {
  final String coverUrl;
  final String title;
  final String vas;
  final String circle; // 社团

  const LimitWorkInfo({
    required this.coverUrl,
    required this.title,
    required this.vas,
    required this.circle,
  });

  LimitWorkInfo copyWith({
    String? coverUrl,
    String? title,
    String? vas,
    String? circle,
  }) {
    return LimitWorkInfo(
      coverUrl: coverUrl ?? this.coverUrl,
      title: title ?? this.title,
      vas: vas ?? this.vas,
      circle: circle ?? this.circle,
    );
  }
}
