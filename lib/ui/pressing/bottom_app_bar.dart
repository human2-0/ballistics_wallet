import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/app_glass_style.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/profile.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/split_check_view.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/basic_shift/bonus_tables_v2.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/overtime_shift/bonus_table_v2.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/target_checker_main_tree.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/wallet_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class RootBottomBar extends ConsumerStatefulWidget {
  const RootBottomBar({super.key});

  @override
  ConsumerState<RootBottomBar> createState() => _RootBottomBarState();
}

class _RootBottomBarState extends ConsumerState<RootBottomBar>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ProviderSubscription<int?>? _activeIndexTabSub;

  int activeIndex = 0;
  bool _isBottomBarVisible = true;
  bool _didPrecacheBackgrounds = false;

  void setActiveTab(int index) {
    if (activeIndex == index) return;
    setState(() {
      activeIndex = index;
    });
  }

  void _selectTab(int index) {
    if (index < 0 || index >= _tabController.length) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(activeIndexTabProvider.notifier).activeIndex = index;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // adjust icon brightness as needed
      ),
    );
    if (mounted) {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(userNotifierProvider.notifier).loadUser(userId);
      });
    }

    _tabController = TabController(length: 4, vsync: this);
    _tabController.animation!.addListener(_handleTabAnimation);
    // Riverpod listener for external tab index requests.
    _activeIndexTabSub = ref.listenManual<int?>(activeIndexTabProvider, (
      prev,
      next,
    ) {
      debugPrint('activeIndexTabProvider: $prev -> $next');
      if (!mounted) return;
      if (next == null) return;
      if (next < 0 || next >= _tabController.length) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setActiveTab(next);
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });
  }

  void _handleTabAnimation() {
    final newIndex = _tabController.animation!.value.round();

    if (newIndex != activeIndex) {
      setActiveTab(newIndex);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Prefer UserScrollNotification for clear intent; fall back to metrics
    if (notification is UserScrollNotification) {
      final dir = notification.direction;
      if (dir == ScrollDirection.reverse && _isBottomBarVisible) {
        setState(() => _isBottomBarVisible = false);
      } else if (dir == ScrollDirection.forward && !_isBottomBarVisible) {
        setState(() => _isBottomBarVisible = true);
      }
    } else if (notification is ScrollUpdateNotification) {
      final dir = notification.metrics.axisDirection;
      if (dir == AxisDirection.up && _isBottomBarVisible) {
        setState(() => _isBottomBarVisible = false);
      } else if (dir == AxisDirection.down && !_isBottomBarVisible) {
        setState(() => _isBottomBarVisible = true);
      }
    }
    return false; // allow notifications to continue bubbling
  }

  @override
  void dispose() {
    _activeIndexTabSub?.close();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheBackgrounds) return;
    _didPrecacheBackgrounds = true;

    unawaited(
      Future.wait([
        precacheImage(const AssetImage('assets/login_screen.webp'), context),
        precacheImage(const AssetImage('assets/target_screen.webp'), context),
        precacheImage(const AssetImage('assets/wallet_screen.webp'), context),
        precacheImage(const AssetImage('assets/profile_screen.webp'), context),
      ]),
    );
  }

  String getBackgroundImagePath() {
    switch (activeIndex) {
      case 0:
        return 'assets/login_screen.webp';
      case 1:
        return 'assets/target_screen.webp';
      case 2:
        return 'assets/wallet_screen.webp';
      case 3:
        return 'assets/profile_screen.webp';
      default:
        return 'assets/login_screen.png'; // A default image if no index matches
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    endDrawerEnableOpenDragGesture: false,
    endDrawer:
        ref.watch(bonusTableSelectorProvider)
            ? const OvertimeBonusTableV2()
            : const BonusTableV2(),
    // Keep the navigation bar anchored while the keyboard covers the page.
    // Individual sheets and forms handle their own scroll/padding when an
    // input needs to remain visible.
    resizeToAvoidBottomInset: false,
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(getBackgroundImagePath(), fit: BoxFit.cover),
        ),
        SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: LayoutBuilder(
              builder:
                  (context, constraints) => TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      TickerMode(
                        enabled: activeIndex == 0,
                        child: const TargetChecker(),
                      ),
                      TickerMode(
                        enabled: activeIndex == 1,
                        child: const SplitCheck(),
                      ),
                      TickerMode(
                        enabled: activeIndex == 2,
                        child: const WalletRoot(),
                      ),
                      TickerMode(
                        enabled: activeIndex == 3,
                        child: const ProfilePage(),
                      ),
                    ],
                  ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            offset: Offset(0, _isBottomBarVisible ? 0 : 1.2),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeIndex == 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TimelineToggleButton(
                      isOpen: ref.watch(workTimelineOpenProvider),
                      onPressed: () {
                        final notifier = ref.read(
                          workTimelineOpenProvider.notifier,
                        );
                        notifier.state = !notifier.state;
                      },
                    ),
                  ),
                buildBottomNavigationBar(context),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget buildBottomNavigationBar(BuildContext context) {
    final barHeight = _bottomBarHeight(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: GlassTabBar.bottom(
        selectedIndex: activeIndex,
        onTabSelected: _selectTab,
        barHeight: barHeight,
        horizontalPadding: 12,
        verticalPadding: 0,
        barBorderRadius: barHeight / 2,
        settings: appGlassSettings,
        indicatorColor: appGlassIndicatorColor,
        indicatorBorderRadius: 24,
        indicatorExpansion: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 6,
        ),
        selectedIconColor: appGlassAccent,
        selectedLabelColor: appGlassAccent,
        unselectedIconColor: appGlassOnSurfaceMuted,
        unselectedLabelColor: appGlassOnSurface,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          shadows: appGlassTextShadows,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          shadows: appGlassTextShadows,
        ),
        interactionGlowColor: appGlassAccent,
        magnification: 1.06,
        pressScale: 1.02,
        tabs: const [
          GlassTab(
            icon: Icon(Icons.query_stats_outlined),
            activeIcon: Icon(Icons.query_stats_rounded),
            label: 'Target',
            semanticLabel: 'Target checker',
          ),
          GlassTab(
            icon: Icon(Icons.balance_outlined),
            activeIcon: Icon(Icons.balance_rounded),
            label: 'Split',
            semanticLabel: 'Split checker',
          ),
          GlassTab(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          GlassTab(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  double _bottomBarHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.072).clamp(62.0, 68.0);
}

class _TimelineToggleButton extends StatelessWidget {
  const _TimelineToggleButton({required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = isOpen ? 'Close timeline' : 'Open timeline';

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GlassIconButton(
          size: 52,
          iconSize: 25,
          useOwnLayer: true,
          quality: GlassQuality.standard,
          settings: appGlassSettings.copyWith(
            glassColor:
                isOpen ? const Color(0xB8C44E16) : const Color(0x66FFF9F5),
          ),
          glowColor: appGlassAccent,
          icon: Icon(
            isOpen ? Icons.close_rounded : Icons.timer_outlined,
            color: appGlassOnSurface,
            shadows: appGlassTextShadows,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
