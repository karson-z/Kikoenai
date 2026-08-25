import '../../gen/assets.gen.dart';

export '../../gen/assets.gen.dart';

/// 统一资源入口。
///
/// - [Assets]：flutter_gen 生成的类型安全资源常量（图片 / 动画 / 图标），
///   由 `dart run build_runner build` 根据 pubspec.yaml 的 `flutter.assets`
///   自动生成，新增资源后需重新生成。
/// - [placeholderImage]：占位图路径（SVG），保持 String 以兼容
///   `Image.asset` / `SvgPicture.asset` 等 API。
final String placeholderImage = Assets.images.placeholder.path;
