import 'package:flutter/material.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class BackButtonPriorityWrapper extends StatefulWidget {
  final Widget child;
  final int zIndex;
  final String? name;

  final bool Function()? onBack;

  const BackButtonPriorityWrapper({
    super.key,
    required this.child,
    this.zIndex = 0,
    this.name,
    this.onBack,
  });

  @override
  State<BackButtonPriorityWrapper> createState() => _BackButtonPriorityWrapperState();
}

class _BackButtonPriorityWrapperState extends State<BackButtonPriorityWrapper> {
  late final String _interceptorName;

  @override
  void initState() {
    super.initState();
    _interceptorName = widget.name ?? 'PriorityWrapper-$hashCode';
    BackButtonInterceptor.add(_interceptor, zIndex: widget.zIndex, name: _interceptorName);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_interceptor);
    super.dispose();
  }

  bool _interceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (stopDefaultButtonEvent) return false;

    if (widget.onBack != null) {
      // 直接使用回调的返回值
      // 如果回调返回 true -> 拦截器 return true (事件结束)
      // 如果回调返回 false -> 拦截器 return false (事件继续向下传递给系统)
      return widget.onBack!();
    }

    // 如果没有定义 onBack，走默认的弹窗关闭逻辑
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}