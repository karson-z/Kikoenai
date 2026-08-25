import 'package:flutter/material.dart';

/// 统一风格的 AlertDialog，样式与“取消定时关闭”弹窗一致。
///
/// - 背景：深色 `0xFF1E1E1E` / 浅色纯白
/// - 圆角 16、elevation 0（无投影，靠遮罩区分层级）
/// - 标题 18 / w600，正文 15 / 次级色
/// - 按钮区 padding：水平 16、垂直 12
///
/// 需要标准“取消 / 确定”按钮时可直接使用 [KikoenaiDialog.confirm]。
class KikoenaiAlertDialog extends StatelessWidget {
  const KikoenaiAlertDialog({
    super.key,
    this.title,
    this.titleText,
    this.content,
    this.contentText,
    this.actions,
    this.contentPadding,
    this.titlePadding,
    this.insetPadding,
    this.scrollable = false,
  });

  /// 标题 Widget（与 [titleText] 二选一）。
  final Widget? title;

  /// 标题文本，自动应用统一样式（18 / w600）。
  final String? titleText;

  /// 内容 Widget（与 [contentText] 二选一），自动应用正文次级色。
  final Widget? content;

  /// 内容文本，自动应用统一样式（15 / 次级色）。
  final String? contentText;

  final List<Widget>? actions;

  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsets? insetPadding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF333333);
    final contentColor = isDark ? Colors.white70 : const Color(0xFF666666);

    return AlertDialog(
      backgroundColor: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: title ??
          (titleText == null
              ? null
              : Text(
                  titleText!,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                )),
      content: content ??
          (contentText == null
              ? null
              : DefaultTextStyle(
                  style: TextStyle(color: contentColor, fontSize: 15),
                  child: Text(contentText!),
                )),
      contentPadding: contentPadding,
      titlePadding: titlePadding,
      insetPadding: insetPadding,
      scrollable: scrollable,
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: actions,
    );
  }

  /// 统一的弹窗文本按钮样式。
  ///
  /// [isConfirm] 为 true 时使用主题色加粗（确定按钮），
  /// [isDestructive] 为 true 时使用红色加粗（危险操作按钮），
  /// 否则使用正文次级色（取消按钮）。
  static Widget textAction(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    bool isConfirm = false,
    bool isDestructive = false,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFF5A89BF) : Theme.of(context).primaryColor;
    final contentColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final isEmphasis = isConfirm || isDestructive;

    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: isDestructive
            ? Theme.of(context).colorScheme.error
            : isConfirm
                ? primaryColor
                : contentColor,
        textStyle: isEmphasis
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      child: Text(label),
    );
  }

  /// 标准“取消 / 确定”确认弹窗，返回是否点击了确定。
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String content,
    String cancelLabel = '取消',
    String confirmLabel = '确定',
    bool clickMaskDismiss = true,
  }) async {
    final result = await KikoenaiDialog.show<bool>(
      context: context,
      clickMaskDismiss: clickMaskDismiss,
      builder: (ctx) => KikoenaiAlertDialog(
        titleText: title,
        contentText: content,
        actions: [
          KikoenaiAlertDialog.textAction(
            ctx,
            label: cancelLabel,
            onPressed: () => KikoenaiDialog.dismiss(popWith: false),
          ),
          KikoenaiAlertDialog.textAction(
            ctx,
            label: confirmLabel,
            isConfirm: true,
            onPressed: () => KikoenaiDialog.dismiss(popWith: true),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class KikoenaiDialog {
  static final KikoenaiDialogObserver observer = KikoenaiDialogObserver();

  KikoenaiDialog._internal();

  static Future<T?> show<T>({
    BuildContext? context,
    bool? clickMaskDismiss,
    VoidCallback? onDismiss,
    required WidgetBuilder builder,
  }) async {
    final ctx = context ?? observer.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        final result = await showDialog<T>(
          context: ctx,
          barrierDismissible: clickMaskDismiss ?? true,
          builder: builder,
          routeSettings: const RouteSettings(name: 'KikoenaiDialog'),
        );
        onDismiss?.call();
        return result;
      } catch (e) {
        debugPrint('Kikoenai Dialog Error: Failed to show dialog: $e');
        return null;
      }
    } else {
      debugPrint(
          'Kikoenai Dialog Error: No context available to show the dialog');
      return null;
    }
  }
  static Future<void> showLoading({
    BuildContext? context,
    String? msg,
    bool barrierDismissible = false,
    Function()? onDismiss,
  }) async {
    final ctx = context ?? observer.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        await showDialog(
          context: ctx,
          barrierDismissible: barrierDismissible,
          builder: (BuildContext context) {
            return Center(
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        msg ?? 'Loading...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          routeSettings: const RouteSettings(name: 'KikoenaiDialog'),
        );
        onDismiss?.call();
      } catch (e) {
        debugPrint('Kikoenai Dialog Error: Failed to show loading dialog: $e');
      }
    } else {
      debugPrint(
          'Kikoenai Dialog Error: No context available to show the loading dialog');
    }
  }

  static Future<T?> showBottomSheet<T>({
    BuildContext? context,
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = true,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
    bool useSafeArea = false,
  }) async {
    // Use provided context first, then root context, then fallback to current context
    final ctx = context ?? observer.rootContext ?? observer.currentContext;
    if (ctx != null && ctx.mounted) {
      try {
        final result = await showModalBottomSheet<T>(
          context: ctx,
          builder: builder,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shape: shape,
          clipBehavior: clipBehavior,
          constraints: constraints,
          barrierColor: barrierColor,
          isScrollControlled: isScrollControlled,
          useRootNavigator: useRootNavigator,
          isDismissible: isDismissible,
          enableDrag: enableDrag,
          routeSettings:
          routeSettings ?? const RouteSettings(name: 'KikoenaiBottomSheet'),
          transitionAnimationController: transitionAnimationController,
          anchorPoint: anchorPoint,
          useSafeArea: useSafeArea,
        );
        return result;
      } catch (e) {
        debugPrint('Kikoenai Dialog Error: Failed to show bottom sheet: $e');
        return null;
      }
    } else {
      debugPrint(
          'Kikoenai Dialog Error: No context available to show the bottom sheet');
      return null;
    }
  }

  // 在存在返回值时弹出并附带返回值
  static void dismiss<T>({T? popWith}) {
    if (observer.hasKikoenaiDialog && observer.kikoenaiDialogContext != null) {
      try {
        Navigator.of(observer.kikoenaiDialogContext!).pop(popWith);
      } catch (e) {
        debugPrint('Kikoenai Dialog Error: Failed to dismiss dialog: $e');
      }
    } else {
      debugPrint('Kikoenai Dialog Debug: No active KikoenaiDialog to dismiss');
    }
  }
}

/// Navigator observer to track contexts and dialog routes
class KikoenaiDialogObserver extends NavigatorObserver {
  /// List of active dialog routes
  final List<Route<dynamic>> _kikoenaiDialogRoutes = [];

  /// The most recent context from any MaterialPageRoute or PopupRoute
  BuildContext? _currentContext;

  /// The most recent context from any route containing a Scaffold
  BuildContext? _scaffoldContext;

  /// The root context of the app (for bottom sheets to cover the entire app)
  BuildContext? _rootContext;

  BuildContext? get currentContext => _currentContext;

  BuildContext? get scaffoldContext => _scaffoldContext ?? _currentContext;

  /// Get the root context for bottom sheets, fallback to scaffold context, then current context
  BuildContext? get rootContext =>
      _rootContext ?? _scaffoldContext ?? _currentContext;

  bool get hasKikoenaiDialog => _kikoenaiDialogRoutes.isNotEmpty;

  BuildContext? get kikoenaiDialogContext => _kikoenaiDialogRoutes.isNotEmpty
      ? _kikoenaiDialogRoutes.last.navigator?.context
      : null;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    /// workaround for #533
    /// we can't remove snackbar when push a new route
    /// otherwise, framework will throw an exception, and can't be caught
    /// need other way to remove snackbar here
    // _removeCurrentSnackBar(previousRoute);
    if (_isKikoenaiDialogRoute(route)) {
      _kikoenaiDialogRoutes.add(route);
    }
    if (route.navigator?.context != null) {
      _updateContexts(route.navigator!.context, route);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _removeCurrentSnackBar(route);
    if (_isKikoenaiDialogRoute(route)) {
      _kikoenaiDialogRoutes.remove(route);
    }
    if (previousRoute?.navigator?.context != null) {
      _updateContexts(previousRoute!.navigator!.context, previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_isKikoenaiDialogRoute(oldRoute!)) {
      _kikoenaiDialogRoutes.remove(oldRoute);
    }
    if (_isKikoenaiDialogRoute(newRoute!)) {
      _kikoenaiDialogRoutes.add(newRoute);
    }
    if (newRoute.navigator?.context != null) {
      _updateContexts(newRoute.navigator!.context, newRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);

    if (_isKikoenaiDialogRoute(route)) {
      _kikoenaiDialogRoutes.remove(route);
    }

    if (previousRoute?.navigator?.context != null) {
      _updateContexts(previousRoute!.navigator!.context, previousRoute);
    }
  }

  void _updateContexts(BuildContext context, Route<dynamic> route) {
    _currentContext = context;
    if (_hasScaffold(context)) {
      _scaffoldContext = context;
      // Always update root context with scaffold contexts to ensure we have the most recent one
      // This helps ensure bottom sheets appear at the app level
      _rootContext = context;
    }
  }

  bool _hasScaffold(BuildContext context) {
    return Scaffold.maybeOf(context) != null;
  }

  bool _isKikoenaiDialogRoute(Route<dynamic> route) {
    return route.settings.name == 'KikoenaiDialog' ||
        route.settings.name == 'KikoenaiBottomSheet';
  }

  void _removeCurrentSnackBar(Route<dynamic>? route) {
    if (route?.navigator?.context != null) {
      try {
        ScaffoldMessenger.maybeOf(route!.navigator!.context)
            ?.removeCurrentSnackBar();
      } catch (_) {}
    }
  }
}