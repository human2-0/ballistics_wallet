import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
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

const _bottomNavigationSurfaceColor = Color(0x80EFEBE9);

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
    resizeToAvoidBottomInset: true,
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
          bottom: -8,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            offset: Offset(0, _isBottomBarVisible ? 0 : 1.2),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: buildBottomNavigationBar(context),
          ),
        ),
        if (activeIndex == 0)
          Positioned(
            bottom:
                MediaQuery.of(context).padding.bottom +
                2 +
                (_bottomBarHeight(context) - 36),
            left: 0,
            right: 0,
            child: Center(
              child: _TimelineToggleButton(
                isOpen: ref.watch(workTimelineOpenProvider),
                onPressed: () {
                  final notifier = ref.read(workTimelineOpenProvider.notifier);
                  notifier.state = !notifier.state;
                },
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
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: _bottomNavigationSurfaceColor,
          borderRadius: BorderRadius.circular(66),
          boxShadow: const [BoxShadow(color: Color(0x80D7BEB1), blurRadius: 5)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              alignment: Alignment(
                activeIndex == 0
                    ? -1.0
                    : activeIndex == 1
                    ? -0.33
                    : activeIndex == 2
                    ? 0.33
                    : 1.0,
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / 4,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(33),
                    color: Colors.yellow.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _BottomNavigationItem(
                  icon: Icons.show_chart,
                  label: 'Target',
                  selected: activeIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _BottomNavigationItem(
                  icon: Icons.balance_outlined,
                  label: 'Split',
                  selected: activeIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                _BottomNavigationItem(
                  icon: Icons.wallet_outlined,
                  label: 'Wallet',
                  selected: activeIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                _BottomNavigationItem(
                  icon: Icons.account_circle_outlined,
                  label: 'Profile',
                  selected: activeIndex == 3,
                  onTap: () => _selectTab(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _bottomBarHeight(BuildContext context) =>
      (MediaQuery.of(context).size.height * 0.075).clamp(62.0, 74.0);
}

class _TimelineToggleButton extends StatelessWidget {
  const _TimelineToggleButton({required this.isOpen, required this.onPressed});

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    color:
        isOpen
            ? Colors.deepOrange.withValues(alpha: 0.88)
            : _bottomNavigationSurfaceColor,
    shape: const CircleBorder(),
    child: IconButton(
      tooltip: isOpen ? 'Close timeline' : 'Open timeline',
      icon: Icon(isOpen ? Icons.close : Icons.timer_outlined),
      color: isOpen ? Colors.white : Colors.deepOrange,
      iconSize: 26,
      constraints: const BoxConstraints.tightFor(width: 56, height: 56),
      onPressed: onPressed,
    ),
  );
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(33),
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? Colors.orange : Colors.black54,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
