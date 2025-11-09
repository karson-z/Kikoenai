import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:name_app/features/album/presentation/viewmodel/album_view_model.dart';
import 'package:name_app/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:name_app/features/user/presentation/view_models/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// 全局状态管理
/// 1. AuthViewModel: 处理用户认证相关状态，如登录、注册、注销等。
/// 2. UserViewModel: 管理用户个人信息，如用户配置、个人数据等。
/// 3. ThemeViewModel: 处理应用主题相关状态，如切换主题、保存主题偏好等。
/// 4. AlbumViewModel: 管理相册相关状态，如相册列表、图片加载等。
List<SingleChildWidget> get providers {
  return [
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
    ChangeNotifierProvider(create: (_) => UserViewModel()),
    ChangeNotifierProvider(create: (_) => ThemeViewModel()),
    ChangeNotifierProvider(create: (_) => AlbumViewModel()),
  ];
}
