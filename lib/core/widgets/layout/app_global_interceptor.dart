import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/layout/app_main_scaffold.dart';
import 'package:kikoenai/core/widgets/layout/provider/main_scaffold_provider.dart';
/// 路由回退操作拦截器， 当我的播放器还处于打开状态下进行页面回退的话则是关闭播放页，而不是直接进行路由页回退。
class GlobalBackInterceptor extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalBackInterceptor({super.key, required this.child});

  @override
  ConsumerState<GlobalBackInterceptor> createState() =>
      _GlobalBackInterceptorState();
}

class _GlobalBackInterceptorState
    extends ConsumerState<GlobalBackInterceptor>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    // 你自己的播放器 provider，例如：
    final bg = ref.read(mainScaffoldProvider);
    final controller = ref.read(panelController);

    // 展开状态 → 不让路由 pop，而是先收起
    if (bg.isPlayerExpanded) {
      controller.close();
      return true; // 系统事件已处理
    }
    // 没处理 → 继续交给 go_router pop
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
