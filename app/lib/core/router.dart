// Navegación declarativa (GoRouter) con PageView horizontal fluido y barra flotante Soft Glass.
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

/// Construye el [GoRouter] principal con desplazamiento horizontal fluido entre las 3 pestañas y `/ajustes`.
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
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            _SwipeablePowerShell(
          navigationShell: navigationShell,
          children: children,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: _KeepAliveTab(child: todayPage),
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
                  child: _KeepAliveTab(child: goalsPage),
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
                  child: _KeepAliveTab(child: progressPage),
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

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});
  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(child: widget.child);
  }
}

class _SwipeablePowerShell extends StatefulWidget {
  const _SwipeablePowerShell({
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<_SwipeablePowerShell> createState() => _SwipeablePowerShellState();
}

class _SwipeablePowerShellState extends State<_SwipeablePowerShell> {
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

  late final PageController _pageController;
  late final ValueNotifier<double> _pagePosition;
  bool _animatingToTab = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.navigationShell.currentIndex;
    _pageController = PageController(initialPage: initial);
    _pagePosition = ValueNotifier<double>(initial.toDouble());
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final p = _pageController.page;
    if (p != null) {
      _pagePosition.value = p.clamp(0.0, (_tabs.length - 1).toDouble());
    }
  }

  @override
  void didUpdateWidget(covariant _SwipeablePowerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.navigationShell.currentIndex;
    if (_pageController.hasClients && !_animatingToTab) {
      final currentRounded = (_pageController.page ?? target.toDouble()).round();
      if (currentRounded != target) {
        _animateToPage(target);
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _pagePosition.dispose();
    super.dispose();
  }

  void _animateToPage(int index) {
    final reduce = reduceMotionOf(context);
    if (reduce || !_pageController.hasClients) {
      if (_pageController.hasClients) _pageController.jumpToPage(index);
      _pagePosition.value = index.toDouble();
      return;
    }
    _animatingToTab = true;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          _animatingToTab = false;
        });
  }

  void _onSelectTab(int index) {
    final isSame = index == widget.navigationShell.currentIndex;
    if (!isSame) PowerHaptics.tap();
    widget.navigationShell.goBranch(index, initialLocation: isSame);
    _animateToPage(index);
  }

  void _onPageChanged(int index) {
    if (_animatingToTab) return;
    if (index != widget.navigationShell.currentIndex) {
      PowerHaptics.tap();
      widget.navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(
          parent: PageScrollPhysics(),
        ),
        children: widget.children,
      ),
      bottomNavigationBar: _FloatingGlassNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        pagePosition: _pagePosition,
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
    required this.pagePosition,
    required this.tabs,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueNotifier<double> pagePosition;
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
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Rad.pill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: pc.glassFillStrong,
                      borderRadius: BorderRadius.circular(Rad.pill),
                      border: Border.all(color: pc.glassBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: pc.ink.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final count = tabs.length;
                        final slotW = constraints.maxWidth / count;
                        return SizedBox(
                          height: 52,
                          child: Stack(
                            children: [
                              // Indicador neón sincronizado 1:1 con el arrastre del dedo
                              ValueListenableBuilder<double>(
                                valueListenable: pagePosition,
                                builder: (_, pos, _) {
                                  final alignX = count <= 1
                                      ? 0.0
                                      : -1.0 + (2.0 * pos / (count - 1));
                                  return Align(
                                    alignment: Alignment(alignX, 0),
                                    child: Container(
                                      width: slotW,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: pc.neon,
                                        borderRadius: BorderRadius.circular(
                                          Rad.pill,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  for (var i = 0; i < tabs.length; i++)
                                    Expanded(
                                      child: _FloatingNavPillButton(
                                        item: tabs[i],
                                        selected: i == currentIndex,
                                        onTap: () => onSelect(i),
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
    );
  }
}
