import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/core/navigation/shortcut_navigation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ShortcutNavigationService.init();
  runApp(const ProviderScope(child: TaskFlowApp()));
}
