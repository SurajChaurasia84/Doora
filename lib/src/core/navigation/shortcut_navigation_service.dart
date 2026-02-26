import 'package:flutter/services.dart';

class ShortcutNavigationService {
  static const MethodChannel _channel = MethodChannel(
    'doora/shortcut_navigation',
  );
  static const String addTaskAction = 'add_task';

  static String? _pendingAction;
  static bool _initialized = false;
  static void Function(String action)? onShortcutRequested;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'openShortcut') return;
      final action = _extractAction(call.arguments);
      if (action != null) {
        _deliverAction(action);
      }
    });

    try {
      final initial = await _channel.invokeMethod<String>('getInitialShortcut');
      if (initial != null && initial.isNotEmpty) {
        _pendingAction = initial.toLowerCase();
      }
    } catch (_) {
      // No-op: app should still run even when platform channel is unavailable.
    }
  }

  static String? consumePendingAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  static void _deliverAction(String action) {
    final callback = onShortcutRequested;
    if (callback == null) {
      _pendingAction = action;
      return;
    }
    callback(action);
  }

  static String? _extractAction(dynamic args) {
    if (args is String && args.isNotEmpty) {
      return args.toLowerCase();
    }
    if (args is Map) {
      final action = args['action'];
      if (action is String && action.isNotEmpty) {
        return action.toLowerCase();
      }
    }
    return null;
  }
}
