import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/app_localizations.dart';

/*
*移动端一级页面返回保护:首次返回提示,短时间内再次返回才退出应用。
*/
class MobileDoubleBackExit extends StatefulWidget {
  const MobileDoubleBackExit({
    required this.child,
    this.interval = const Duration(seconds: 2),
    this.onExit,
    super.key,
  });

  final Widget child;
  final Duration interval;
  final Future<void> Function()? onExit;

  @override
  State<MobileDoubleBackExit> createState() => MobileDoubleBackExitState();
}

class MobileDoubleBackExitState extends State<MobileDoubleBackExit> {
  DateTime? _lastBackAt;

  @visibleForTesting
  void handleBack() => _handlePop(false, null);

  void _handlePop(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    final now = DateTime.now();
    final lastBackAt = _lastBackAt;
    if (lastBackAt != null && now.difference(lastBackAt) <= widget.interval) {
      unawaited((widget.onExit ?? _exitApplication)());
      return;
    }
    _lastBackAt = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).tr('common.press_back_again_to_exit')),
          duration: widget.interval,
        ),
      );
  }

  Future<void> _exitApplication() => SystemNavigator.pop();

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: widget.child,
    );
  }
}
