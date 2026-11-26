// Navegación declarativa (GoRouter) con barra inferior flotante de vidrio esmerilado.
import 'dart:ui';

import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// Rutas declarativas de Power Habits.
abstract final class AppRoutes {
  static const String today = '/hoy';
  static const String goals = '/metas';
  static const String progress = '/progreso';
  static const String settings = '/ajustes';
}

/// Espacio inferior recomendado para listas que pasan bajo la barra flotante.
const double kFloatingNavClearance = 108;

/// Construye el [GoRouter] principal con shell persistente de 3 pestañas y `/ajustes`.
GoRouter buildAppRouter({
  required Widget todayPage,
  required Widget goalsPage,
  required Widget progressPage,
  required Widget settingsPage,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final rootNavigatorKey =
      navigatorKey ?? GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _PowerShellScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: todayPage,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.goals,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: goalsPage,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: progressPage,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => settingsPage,
      ),
    ],
  );
}

class _PowerShellScaffold extends StatelessWidget {
  const _PowerShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_NavTabItem> _tabs = [
    _NavTabItem(
      label: 'Hoy',
      icon: LucideIcons.calendarCheck,
      route: AppRoutes.today,
    ),
    _NavTabItem(
      label: 'Metas',
      icon: LucideIcons.target,
      route: AppRoutes.goals,
    ),
    _NavTabItem(
      label: 'Progreso',
      icon: LucideIcons.trendingUp,
      route: AppRoutes.progress,
    ),
  ];

  void _onSelectTab(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _FloatingGlassNavBar(
        currentIndex: navigationShell.currentIndex,
        tabs: _tabs,
        onSelect: _onSelectTab,
      ),
    );
  }
}

class _NavTabItem {
  const _NavTabItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _FloatingGlassNavBar extends StatelessWidget {
  const _FloatingGlassNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onSelect,
  });

  final int currentIndex;
  final List<_NavTabItem> tabs;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Sp.x3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x5),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Rad.pill),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: pc.glassFillStrong,
                    borderRadius: BorderRadius.circular(Rad.pill),
                    border: Border.all(color: pc.glassBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: pc.ink.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final count = tabs.length;
                      final slotW = constraints.maxWidth / count;
                      final alignX = count <= 1
                          ? 0.0
                          : -1.0 + (2.0 * currentIndex / (count - 1));
                      final reduce = reduceMotionOf(context);
                      return SizedBox(
                        height: 52,
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              alignment: Alignment(alignX, 0),
                              duration: reduce
                                  ? Duration.zero
                                  : const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              child: Container(
                                width: slotW,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: pc.neon,
                                  borderRadius: BorderRadius.circular(Rad.pill),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (var i = 0; i < tabs.length; i++)
                                  Expanded(
                                    child: _FloatingNavPillButton(
                                      item: tabs[i],
                                      selected: i == currentIndex,
                                      onTap: () {
                                        if (i != currentIndex) {
                                          PowerHaptics.tap();
                                        }
                                        onSelect(i);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavPillButton extends StatelessWidget {
  const _FloatingNavPillButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pc = context.pc;
    final tt = context.tt;
    final fg = selected ? pc.onNeon : pc.inkMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Rad.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 6),
            child: AnimatedScale(
              scale: selected && !reduceMotionOf(context) ? 1.03 : 1.0,
              duration: reduceMotionOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 19, color: fg),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelMedium?.copyWith(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
