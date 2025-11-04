import 'package:name_app/core/theme/theme_view_model.dart';
import 'package:name_app/features/album/presentation/viewmodel/album_view_model.dart';
import 'package:name_app/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:name_app/features/user/presentation/view_models/user_view_model.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> get providers {
  return [
    ChangeNotifierProvider(create: (_) => AuthViewModel()),
    ChangeNotifierProvider(create: (_) => UserViewModel()),
    ChangeNotifierProvider(create: (_) => ThemeViewModel()),
    ChangeNotifierProvider(create: (_) => AlbumViewModel()),
  ];
}
