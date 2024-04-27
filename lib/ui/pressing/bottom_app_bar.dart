import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/profile.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/split_check.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/basic_shift/bonus_tables.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/overtime_shift/bonus_tables_overtimes.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/target_checker_main_tree.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/wallet_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RootBottomBar extends ConsumerStatefulWidget {
  const RootBottomBar({
    super.key,
  });

  @override
  ConsumerState<RootBottomBar> createState() => _RootBottomBarState();
}

class _RootBottomBarState extends ConsumerState<RootBottomBar>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isVisible = true;

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  int activeIndex = 0;

  void setActiveTab(int index) {
    setState(() {
      activeIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (mounted) {
      final userId = ref.read(authRepositoryProvider).currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(userNotifierProvider.notifier).loadUser(userId);
      });
    }

    _tabController = TabController(length: 4, vsync: this);
    _tabController.animation!.addListener(_handleTabAnimation);

    _scrollController = ScrollController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isVisible = false;
          });
        }
        if (status == AnimationStatus.dismissed) {
          setState(() {
            _isVisible = true;
          });
        }
      });

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isVisible) {
          _animationController.forward();
        }
      } else {
        if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward) {
          if (!_isVisible) {
            _animationController.reverse();
          }
        }
      }
    });
  }

  void _handleTabAnimation() {
    // Use round() to convert the animation value to the nearest integer.
    // This gives the index of the tab we're swiping towards.
    final newIndex = _tabController.animation!.value.round();

    if (newIndex != activeIndex) {
      setActiveTab(newIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Future.microtask(Hive.close);
    _tabController.animation!.removeListener(_handleTabAnimation);
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _animationController.forward();
      } else if (notification.direction == ScrollDirection.forward) {
        _animationController.reverse();
      }
    }
    return false;
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
      // Add cases for other indices, with their respective image paths
      default:
        return 'assets/login_screen.png'; // A default image if no index matches
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        // App is in the background
        _runBackendTasks();
        break;
      case AppLifecycleState.resumed:
        // App is in foreground
        break;
      case AppLifecycleState.inactive:
        // App is in an inactive state
        break;
      case AppLifecycleState.detached:
        // App is still hosted on a flutter engine but is detached from any host views
        _runBackendTasks();
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        break;
    }
  }

  void _runBackendTasks() {
    // Here you could add your function to call your backend or perform any tasks
    Future.microtask(
      () async => ref.read(backupManagerProvider.notifier).backupData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // adjust icon brightness as needed
      ),
    );

    return Scaffold(
      endDrawer: ref.watch(bonusTableSelectorProvider)
          ? const BonusTableOvertime()
          : const BonusTable(),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              getBackgroundImagePath(),
              fit: BoxFit.cover,
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              handleScroll(notification);
              return true;
            },
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    TargetChecker(
                      onNotification: handleScroll,
                    ),
                    const SplitCheck(),
                    WalletRoot(
                      onNotification: handleScroll,
                    ),
                    const ProfilePage(),
                  ],
                ),
              ),
            ),
          ),
          // Always show the bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _offsetAnimation,
              child: buildBottomNavigationBar(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.10,
        decoration: BoxDecoration(
          color: Colors.brown[50]?.withOpacity(0.7),
          borderRadius: BorderRadius.circular(33),
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
              height:
                  MediaQuery.of(context).size.height * 0.10, // specify a height
              width:
                  MediaQuery.of(context).size.width * 0.80, // specify a width
              duration: const Duration(milliseconds: 200),
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
                    color: Colors.yellow.withOpacity(0.5),
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
