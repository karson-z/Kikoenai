enum NodeType {
  folder,
  audio,
  image,
  text,
  video,
  other,
  unknown, // 预留一个未知类型，防止后端增加新类型导致前端崩溃
}

// 扩展方法：用于将后端字符串转为枚举
extension NodeTypeExtension on NodeType {
  static NodeType fromString(String value) {
    switch (value) {
      case 'folder':
        return NodeType.folder;
      case 'audio':
        return NodeType.audio;
      case 'image':
        return NodeType.image;
      case 'text':
        return NodeType.text;
      case 'other':
        return NodeType.other;
      case 'video':
        return NodeType.video;
      default:
        return NodeType.unknown;
    }
  }
}