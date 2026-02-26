import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tasks/presentation/screens/home_screen.dart';
import '../providers/auth_controller.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const routeName = '/';

  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authControllerProvider.notifier).restoreSession();
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      Navigator.pushReplacementNamed(
        context,
        auth.isAuthenticated ? HomeScreen.routeName : LoginScreen.routeName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text('Doora', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
