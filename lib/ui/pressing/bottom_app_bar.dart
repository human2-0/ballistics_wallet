import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/overtime_shift/bonus_tables_overtimes.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/target_checker_main_tree.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/basic_shift/bonus_tables.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/wallet_pressing.dart';
import 'package:flutter/rendering.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/profile.dart';

import '../../providers/wallet_provider.dart';
import 'split_check/split_check.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final String userId = ref.read(authRepositoryProvider).currentUserId;
        ref.read(targetRatioProvider(userId).notifier).init();
      }
    });

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
      end: const Offset(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isVisible == true) {
          _animationController.forward();
        }
      } else {
        if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward) {
          if (_isVisible == false) {
            _animationController.reverse();
          }
        }
      }
    });
  }

  void _handleTabAnimation() {
    // Use round() to convert the animation value to the nearest integer.
    // This gives the index of the tab we're swiping towards.
    int newIndex = _tabController.animation!.value.round();

    if (newIndex != activeIndex) {
      setActiveTab(newIndex);
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final String userId = ref.read(authRepositoryProvider).currentUserId;


    return Scaffold(
      endDrawer: ref.watch(bonusTableSelectorProvider) ? const BonusTableOvertime() : const BonusTable() ,
      resizeToAvoidBottomInset: false,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          handleScroll(notification);
          return true;
        },
        child: Stack(
          children: [
            Stack(
              children: [
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          const TargetChecker(),
                          const SplitCheck(),
                          BonusCalendar(
                                  userId: userId, onNotification: handleScroll),
                          const ProfilePage(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // Always show the bottom navigation bar
            Positioned(
              bottom: 0,
              left: 0.0,
              right: 0.0,
              child: SlideTransition(
                position: _offsetAnimation,
                child: buildBottomNavigationBar(context),)
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.10,
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 5,
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
      child: Stack(children: [
        AnimatedContainer(
          height: MediaQuery.of(context).size.height * 0.10, // specify a height
          width: MediaQuery.of(context).size.width * 0.80, // specify a width
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
              0),

          child: FractionallySizedBox(
            widthFactor: 1 / 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(33.0),
                color: Colors.yellow.withOpacity(0.5),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.show_chart,
                    size: 40,
                    color: (activeIndex == 0) ? Colors.orange : Colors.black54,
                  ),
                  onPressed: () {
                    setActiveTab(0);
                    setState(() {
                      _tabController.animateTo(0);
                    });
                  },
                ),
                const Text('Target'),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.balance_outlined,
                    size: 40,
                    color: (activeIndex == 1) ? Colors.orange : Colors.black54,
                  ),
                  onPressed: () {
                    setActiveTab(1);
                    setState(() {
                      _tabController.animateTo(1);
                    });
                  },
                ),
                const Text('Split'),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.wallet_outlined,
                    size: 40,
                    color: (activeIndex == 2) ? Colors.orange : Colors.black54,
                  ),
                  onPressed: () {
                    setActiveTab(2);
                    setState(() {
                      _tabController.animateTo(2);
                    });
                  },
                ),
                const Text("Wallet"),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.account_circle_outlined,
                    size: 40,
                    color: (activeIndex == 3) ? Colors.orange : Colors.black54,
                  ),
                  onPressed: () {
                    setActiveTab(3);
                    setState(() {
                      _tabController.animateTo(3);
                    });
                  },
                ),
                const Center(child: Text('Profile')),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}
