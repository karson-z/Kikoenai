import 'package:flutter/material.dart';
import 'package:name_app/app/loading_controller.dart';

class RouterLoadingObserver extends NavigatorObserver {
  final LoadingViewModel loadingVM;

  RouterLoadingObserver(this.loadingVM);

  @override
  void didPush(Route route, Route? previousRoute) {
    loadingVM.show();
    Future.delayed(const Duration(milliseconds: 300), loadingVM.hide);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    loadingVM.show();
    Future.delayed(const Duration(milliseconds: 300), loadingVM.hide);
  }
}
