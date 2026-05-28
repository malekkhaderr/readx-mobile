import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_theme.dart';
import '../di/injection_container.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/ai_chat/presentation/widgets/owl_chat_fab.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  static bool _initialized = false;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      sl<ProfileBloc>().add(const LoadProfileEvent());
      sl<HomeBloc>().add(const LoadHomeEvent());
    }

    // The app uses AppColors static mutables for theming. When the theme
    // toggles, those statics get reassigned, but cached pages inside the
    // StatefulNavigationShell don't automatically rebuild. Wrapping the
    // shell's body in a KeyedSubtree keyed on brightness forces every tab
    // page to be recreated when the theme changes, picking up the new
    // AppColors values. The bloc singletons survive (they live in GetIt,
    // not in the widget tree), so data isn't lost — just the UI rebuilds.
    final themeKey = ValueKey(Theme.of(context).brightness);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>.value(value: sl<ProfileBloc>()),
        BlocProvider<HomeBloc>.value(value: sl<HomeBloc>()),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            KeyedSubtree(key: themeKey, child: navigationShell),
            _DraggableOwlFab(onTap: () => context.push('/ai-chat')),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_rounded, label: 'Home', isSelected: navigationShell.currentIndex == 0, onTap: () => navigationShell.goBranch(0)),
                  _NavItem(icon: Icons.auto_stories_rounded, label: 'Library', isSelected: navigationShell.currentIndex == 1, onTap: () => navigationShell.goBranch(1)),
                  _NavItem(icon: Icons.search_rounded, label: 'Search', isSelected: navigationShell.currentIndex == 2, onTap: () => navigationShell.goBranch(2)),
                  _NavItem(icon: Icons.format_quote_rounded, label: 'Quotes', isSelected: navigationShell.currentIndex == 3, onTap: () => navigationShell.goBranch(3)),
                  _NavItem(icon: Icons.person_rounded, label: 'Profile', isSelected: navigationShell.currentIndex == 4, onTap: () => navigationShell.goBranch(4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight.withOpacity(0.6) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, spreadRadius: 0),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.primary : AppColors.textGrey),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _DraggableOwlFab extends StatefulWidget {
  final VoidCallback onTap;
  const _DraggableOwlFab({required this.onTap});

  @override
  State<_DraggableOwlFab> createState() => _DraggableOwlFabState();
}

class _DraggableOwlFabState extends State<_DraggableOwlFab> {
  double _x = -1;
  double _y = -1;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Initialize position on first build
    if (_x < 0) _x = size.width - 72;
    if (_y < 0) _y = size.height - 160;

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) {
          setState(() {
            _x = (_x + details.delta.dx).clamp(0, size.width - 60);
            _y = (_y + details.delta.dy).clamp(0, size.height - 140);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _dragging = false;
            // Snap to nearest edge
            final midX = size.width / 2;
            _x = _x < midX ? 16 : size.width - 72;
          });
        },
        child: AnimatedScale(
          scale: _dragging ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: OwlChatFab(onTap: widget.onTap),
        ),
      ),
    );
  }
}
