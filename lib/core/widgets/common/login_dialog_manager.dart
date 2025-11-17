import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:name_app/core/constants/app_constants.dart';
import 'package:name_app/core/routes/app_routes.dart';
import 'package:name_app/features/auth/presentation/widgets/auth_dialog.dart';
import 'package:name_app/features/auth/presentation/widgets/auth_login_center.dart';
import '../../utils/log/logger.dart';

class _PendingRequest {
  final RequestOptions request;
  final ErrorInterceptorHandler handler;
  _PendingRequest(this.request, this.handler);

  void resolve(Response response) => handler.resolve(response);
  void reject(DioException e) => handler.reject(e);
}

/// 登录弹窗管理器
class LoginDialogManager {
  static final LoginDialogManager _instance = LoginDialogManager._internal();
  factory LoginDialogManager() => _instance;
  LoginDialogManager._internal();

  final Queue<_PendingRequest> _queue = Queue();
  bool _showing = false;

  Future<void> handleUnauthorized(
    Response response,
      ErrorInterceptorHandler handler,
    Dio dio, {
    Future<String?> Function()? tokenProvider,
  }) async {
    _queue.add(_PendingRequest(response.requestOptions, handler));
    if (_showing) return;

    _showing = true;
    Log.w('401 detected. Showing login dialog...', tag: 'LoginDialogManager');

    final success = await showLoginDialog();
    _showing = false;

    if (success == true) {
      await _retryAll(dio, tokenProvider);
    } else {
      _failAll("User cancelled login");
    }
  }

  Future<bool?> showLoginDialog() async {
    final context = AppConstants.rootNavigatorKey.currentContext;
    if (context == null) {
      Log.e('Root context unavailable.', tag: 'LoginDialogManager');
      return false;
    }

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, _) {
        return FadeTransition(
          opacity: animation,
          child: DraggableCenteredPopup(
            child: AuthDialog(
              onSuccess: () => Navigator.of(context).pop(true),
            ),
          ),
        );
      },
    ).then((value) {
      if (value != true && context.mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          context.go(AppRoutes.home);
        });
      }
      return value;
    });
  }

  Future<void> _retryAll(
    Dio dio,
    Future<String?> Function()? tokenProvider,
  ) async {
    Log.i('Retrying queued requests...', tag: 'LoginDialogManager');

    String? token;
    if (tokenProvider != null) token = await tokenProvider();

    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      try {
        if (token != null) item.request.headers['token'] = token;
        final response = await dio.fetch(item.request);
        item.resolve(response);
      } catch (e) {
        item.reject(DioException(requestOptions: item.request, error: e));
      }
    }
  }

  void _failAll(String error) {
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      item.reject(DioException(requestOptions: item.request, error: error));
    }
  }
}
