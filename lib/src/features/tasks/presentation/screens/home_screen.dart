import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import '../../../../core/navigation/shortcut_navigation_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../domain/task.dart';
import '../providers/task_controller.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _themeIconKey = GlobalKey();
  late final AnimationController _themeAnimationController;
  OverlayEntry? _themeOverlayEntry;
  Offset _themeCenter = Offset.zero;
  double _themeMaxRadius = 0;
  Color _themeOverlayColor = Colors.transparent;
  Color _themeRingColor = Colors.transparent;
  bool _isExpandAnimation = true;

  @override
  void initState() {
    super.initState();
    _themeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    Future.microtask(
      () => ref.read(taskControllerProvider.notifier).initialize(),
    );
    _scrollController.addListener(() {
      final threshold = _scrollController.position.maxScrollExtent - 200;
      if (_scrollController.position.pixels >= threshold) {
        ref.read(taskControllerProvider.notifier).loadMore();
      }
    });

    final initialAction = ShortcutNavigationService.consumePendingAction();
    if (initialAction == ShortcutNavigationService.addTaskAction) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openForm();
      });
    }
    ShortcutNavigationService.onShortcutRequested = (action) {
      if (!mounted) return;
      if (action != ShortcutNavigationService.addTaskAction) return;
      _openForm();
    };
  }

  @override
  void dispose() {
    if (ShortcutNavigationService.onShortcutRequested != null) {
      ShortcutNavigationService.onShortcutRequested = null;
    }
    _themeAnimationController.dispose();
    _themeOverlayEntry?.remove();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleThemeAnimated() async {
    if (_themeAnimationController.isAnimating) return;
    final iconContext = _themeIconKey.currentContext;
    if (iconContext == null || !mounted) return;

    final currentBrightness = Theme.of(context).brightness;
    final isDark = currentBrightness == Brightness.dark;
    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;

    final iconBox = iconContext.findRenderObject() as RenderBox?;
    final pageBox = context.findRenderObject() as RenderBox?;
    if (iconBox == null || pageBox == null) return;

    _themeCenter = iconBox.localToGlobal(
      iconBox.size.center(Offset.zero),
      ancestor: pageBox,
    );

    final size = pageBox.size;
    _themeMaxRadius = _maxDistanceToCorner(_themeCenter, size);
    _isExpandAnimation = isDark;

    final nextScheme = nextMode == ThemeMode.dark
        ? AppTheme.dark().colorScheme
        : AppTheme.light().colorScheme;
    _themeOverlayColor = nextScheme.primary.withValues(alpha: 0.18);
    _themeRingColor = nextScheme.primary.withValues(alpha: 0.55);

    _themeOverlayEntry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _themeAnimationController,
            builder: (_, __) {
              final t = Curves.easeInOutCubicEmphasized.transform(
                _themeAnimationController.value,
              );
              final radius = _isExpandAnimation
                  ? (_themeMaxRadius * t)
                  : (_themeMaxRadius * (1 - t));
              return CustomPaint(
                size: Size.infinite,
                painter: _ThemePulsePainter(
                  center: _themeCenter,
                  radius: radius,
                  fillColor: _themeOverlayColor,
                  ringColor: _themeRingColor,
                ),
              );
            },
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_themeOverlayEntry!);
    ref.read(themeModeProvider.notifier).state = nextMode;
    await _themeAnimationController.forward(from: 0);

    _themeOverlayEntry?.remove();
    _themeOverlayEntry = null;
  }

  double _maxDistanceToCorner(Offset center, Size size) {
    final corners = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((corner) => (corner - center).distance).reduce(math.max);
  }

  Future<void> _openForm([Task? task]) async {
    await Navigator.pushNamed(
      context,
      TaskFormScreen.routeName,
      arguments: task,
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (route) => false,
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('This will permanently remove "${task.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await ref.read(taskControllerProvider.notifier).deleteTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskControllerProvider);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('My Tasks'),
        actions: [
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                key: _themeIconKey,
                tooltip:
                    isDark ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: _toggleThemeAnimated,
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: () {
          if (state.isLoading && state.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.tasks.isEmpty) {
            return ErrorStateView(
              message: state.error!,
              onRetry: () =>
                  ref.read(taskControllerProvider.notifier).loadInitial(),
            );
          }
          if (state.tasks.isEmpty) {
            return EmptyStateView(
              title: 'No tasks yet',
              subtitle: 'Create your first task to get organized.',
              actionLabel: 'Create Task',
              onAction: () => _openForm(),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(taskControllerProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 92),
              itemCount: state.tasks.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.tasks.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final task = state.tasks[index];
                return TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  onEdit: () => _openForm(task),
                  onDelete: () => _confirmDelete(task),
                );
              },
            ),
          );
        }(),
      ),
    );
  }
}

class _ThemePulsePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color fillColor;
  final Color ringColor;

  const _ThemePulsePainter({
    required this.center,
    required this.radius,
    required this.fillColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = ringColor;

    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _ThemePulsePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.ringColor != ringColor;
  }
}
