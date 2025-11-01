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

class RootBottomBar extends ConsumerStatefulWidget {
  const RootBottomBar({
    super.key,
  });

  @override
  ConsumerState<RootBottomBar> createState() => _RootBottomBarState();
}

class _RootBottomBarState extends ConsumerState<RootBottomBar>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ProviderSubscription<int?>? _activeIndexTabSub;

  int activeIndex = 0;
  bool _isBottomBarVisible = true;

  void setActiveTab(int index) {
    if (activeIndex == index) return;
    setState(() {
      activeIndex = index;
    });
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
    // Riverpod listener for external tab index requests
    _activeIndexTabSub = ref.listenManual<int?>(
      activeIndexTabProvider,
      (prev, next) {
        debugPrint('activeIndexTabProvider: $prev -> $next');
        if (!mounted) return;
        // Treat provider as an edge-triggered event: only react to null -> index transitions.
        if (prev != null || next == null) return;
        if (next >= 0 && next < _tabController.length && _tabController.index != next) {
          _tabController.animateTo(next);
        }
        // Reset to null after consumption so future events fire cleanly.
        ref.read(activeIndexTabProvider.notifier).state = null;
      },
    );
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
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    for (final path in [
      'assets/login_screen.webp',
      'assets/target_screen.webp',
      'assets/wallet_screen.webp',
      'assets/profile_screen.webp',
    ]) {
      // Start caching without awaiting to avoid blocking the UI thread.
      await precacheImage(AssetImage(path), context);
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawerEnableOpenDragGesture: false,
      endDrawer: ref.watch(bonusTableSelectorProvider)
          ? const OvertimeBonusTableV2()
          : const BonusTableV2(),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              getBackgroundImagePath(),
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: LayoutBuilder(
                builder: (context, constraints) => TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const <Widget>[
                    TargetChecker(),
                    SplitCheck(),
                    WalletRoot(),
                    ProfilePage(),
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
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: buildBottomNavigationBar(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.08,
        decoration: BoxDecoration(
          color: Colors.brown[50]!.withAlpha(128),
          borderRadius: BorderRadius.circular(66),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80D7BEB1),
              blurRadius: 5,
            ),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
        child: Stack(
          children: [
            AnimatedContainer(
              height: MediaQuery.of(context).size.height * 0.10,
              width: MediaQuery.of(context).size.width * 0.80,
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(33),
                    color: Colors.yellow.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: MediaQuery.of(context).size.aspectRatio * 60,
                        color:
                            (activeIndex == 0) ? Colors.orange : Colors.black54,
                      ),
                      const Text('Target'),
                    ],
                  ),
                  onPressed: () {
                    setActiveTab(0);
                    setState(() {
                      _tabController.animateTo(0);
                    });
                  },
                ),
                IconButton(
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.balance_outlined,
                        size: MediaQuery.of(context).size.aspectRatio * 60,
                        color:
                            (activeIndex == 1) ? Colors.orange : Colors.black54,
                      ),
                      const Text('Split'),
                    ],
                  ),
                  onPressed: () {
                    setActiveTab(1);
                    setState(() {
                      _tabController.animateTo(1);
                    });
                  },
                ),
                IconButton(
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.wallet_outlined,
                        size: MediaQuery.of(context).size.aspectRatio * 60,
                        color:
                            (activeIndex == 2) ? Colors.orange : Colors.black54,
                      ),
                      const Text('Wallet'),
                    ],
                  ),
                  onPressed: () {
                    setActiveTab(2);
                    setState(() {
                      _tabController.animateTo(2);
                    });
                  },
                ),
                IconButton(
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: MediaQuery.of(context).size.aspectRatio * 60,
                        color:
                            (activeIndex == 3) ? Colors.orange : Colors.black54,
                      ),
                      const Center(child: Text('Profile')),
                    ],
                  ),
                  onPressed: () {
                    setActiveTab(3);
                    setState(() {
                      _tabController.animateTo(3);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      );
}
