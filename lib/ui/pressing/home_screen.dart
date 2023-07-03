import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/bonus_tables.dart';
import 'package:ballistics_wallet_flutter/providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet_pressing.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/circles.dart';
import 'package:flutter/rendering.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile.dart';
import 'package:lottie/lottie.dart';

import '../../repository/users_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final String userId = ref.read(authRepositoryProvider).currentUserId;
        ref.read(targetRatioProvider(userId).notifier).init();
      }
    });
    _tabController = TabController(length: 3, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        if (_isVisible == true) {
          _animationController.forward();
        }
      } else if (notification.direction == ScrollDirection.forward) {
        if (_isVisible == false) {
          _animationController.reverse();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = ref.read(authRepositoryProvider).currentUserId;
    double aboveMinimum = ref.watch(targetRatioProvider(userId));
    double kBottomNavigationBarHeight =
        MediaQuery.of(context).size.height * 0.12;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWideScreen = constraints.maxWidth > 500;
                    return TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.vertical,
                          child: Column(
                                  children: [
                                    TargetChecker(),
                                    BonusTableAlive(),
                                  ],
                                ),
                        ),
                        (userId != null)
                            ? BonusCalendar(
                                userId: userId, onNotification: handleScroll)
                            : const CircularProgressIndicator(),
                        ProfilePage(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            bottom: _isVisible ? 0 : -kBottomNavigationBarHeight,
            left: 0.0,
            right: 0.0,
            child: buildBottomNavigationBar(context),
          ),
        ],
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
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.show_chart,
                  size: 40,
                ),
                onPressed: () {
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
                icon: const Icon(
                  Icons.wallet_outlined,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _tabController.animateTo(1);
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
                icon: const Icon(
                  Icons.account_circle_outlined,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _tabController.animateTo(2);
                  });
                },
              ),
              const Center(child: Text('Profile')),
            ],
          ),
        ],
      ),
    );
  }
}

class TargetChecker extends ConsumerStatefulWidget {
  const TargetChecker({Key? key}) : super(key: key);

  @override
  TargetCheckerCard createState() => TargetCheckerCard();
}

class TargetCheckerCard extends ConsumerState<TargetChecker>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textEditingController = TextEditingController();
  bool _showList = false;
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isSearchBarFocused = false;
  bool _isBackVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _numberFocusNode = FocusNode();
  final allowanceController = TextEditingController();
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  final TextEditingController _overtimeAmountController =
      TextEditingController();
  final TextEditingController _overtimeWorkingHoursController =
      TextEditingController();
  double _startPosition = 0.0;

  double _overtimeHours = 0.0;
  int _overtimeAmount = 0;
  double _effectiveWorkingHours = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _flipAnimation = Tween(begin: 0.0, end: 3.14).animate(_flipController);
    _textEditingController.addListener(_textChangeListener);
    _overtimeAmountController.addListener(overtimeAmount);
    _overtimeWorkingHoursController.addListener(overtimeWorkingHours);
  }

  void _textChangeListener() {
    setState(() {
      _isSearchBarFocused = _textEditingController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _textEditingController.removeListener(_textChangeListener);
    _numberFocusNode.dispose();
    _textEditingController.dispose();
    allowanceController.dispose();
    _overtimeWorkingHoursController.dispose();
    _overtimeAmountController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void overtimeAmount() {
    setState(() {
      _overtimeAmount = int.tryParse(_overtimeAmountController.text) ?? 0;
    });
  }

  void overtimeWorkingHours() {
    setState(() {
      _overtimeHours =
          double.tryParse(_overtimeWorkingHoursController.text) ?? 0;
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authRepositoryProvider).currentUserId;
    final products = ref.watch(productsProvider);
    final productName =
        ref.watch(selectedProductProvider).state.toLowerCase().trimRight();

    final double percentage = ref.watch(targetRatioProvider(userId)) * 100;
    final int amount = ref.watch(numberProvider);
    int productTarget = ref.watch(targetProvider);

    final double targetRatio = ref.watch(targetRatioProvider(userId));
    ref.read(userNotifierProvider.notifier).loadUser(userId);
    final userState = ref.watch(userNotifierProvider.notifier).state;
    final allowance = ref.watch(allowanceProvider);
    final double workingHours = userState.workingHours ?? 0.0;
    double _overtimePercents = 0.0;
    double _effectiveOvertimeHours = ref
        .read(userNotifierProvider.notifier)
        .calculateEffectiveWorkingHours(_overtimeHours);

    if (_overtimeAmount != 0 &&
        productTarget != 0 &&
        _effectiveOvertimeHours != 0) {
      _overtimePercents = (_overtimeAmount / (productTarget)) * 100;
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      bool isWideScreen = constraints.maxWidth > 500;
      double containerWidth = isWideScreen
          ? MediaQuery.of(context).size.width * 0.33
          : MediaQuery.of(context).size.width * 0.85;
      double containerHeight = MediaQuery.of(context).size.height * 0.75;

      return GestureDetector(
        onHorizontalDragStart: (details) {
          _startPosition = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            double dx = details.globalPosition.dx - _startPosition;
            _flipController.value += dx / (containerWidth ?? 1);
            _startPosition = details.globalPosition.dx;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_flipController.value >= 0.5) {
            _flipController.forward();

            ref.read(selectedProductProvider).state = '';
            ref.read(searchTermProvider.notifier).state = "";
            _textEditingController.clear();
            ref.read(targetProvider.notifier).updateTarget(0);
          } else {
            _flipController.reverse();
          }
        },
        child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(pi * _flipController.value)
                    ..setEntry(
                        3, 2, _flipController.value > 0.5 ? -0.001 : 0.001),
                  child: IndexedStack(
                      alignment: Alignment.center,
                      index: (_flipController.value < 0.5) ? 0 : 1,
                      children: [
                        Stack(children: [
                          Center(
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: isWideScreen ? 500 : 0.0,
                              ),
                              width: containerWidth,
                              height: containerHeight,
                              margin: const EdgeInsets.fromLTRB(20, 10, 10, 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50.0),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange[50]!,
                                    Colors.orange[100]!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    offset: const Offset(0, -4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(

                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isFocused = true;
                                          _showList = true; // Change _showList state here
                                        });
                                        _focusNode.requestFocus();
                                      },
                                      child: AnimatedContainer(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.orange[100]!,
                                              Colors.orange[200]!,
                                              Colors.orange[300]!,
                                            ],
                                            stops: [
                                              0.0,
                                              0.5,
                                              0.9,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        duration: Duration(milliseconds: 400),
                                        width: ((_showList || _isFocused)
                                            ? MediaQuery.of(context).size.width *
                                                0.5
                                            : MediaQuery.of(context).size.width *
                                                0.12),
                                        child: TextField(
                                          focusNode: _focusNode,
                                          controller: _textEditingController,
                                          textAlign: TextAlign.center,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            suffixIcon: _textEditingController
                                                        .text.isEmpty &&
                                                    !_isSearchBarFocused
                                                ? const Center(
                                                    child: Icon(
                                                        Icons.search_rounded))
                                                : IconButton(
                                                    icon: const Icon(Icons.clear),
                                                    onPressed: () {
                                                      setState(() {
                                                        ref
                                                            .read(
                                                                searchTermProvider
                                                                    .notifier)
                                                            .state = "";
                                                        ref
                                                            .read(
                                                                selectedProductProvider
                                                                    .notifier)
                                                            .state
                                                            .state = "";
                                                        _textEditingController
                                                            .clear();
                                                        _showList = false;
                                                        _isFocused = false;
                                                        _focusNode.unfocus();
                                                        _isSearchBarFocused =
                                                            false;
                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                FocusNode());
                                                        _numberController.clear();

                                                        int productTarget = ref
                                                            .read(targetProvider);

                                                        ref
                                                            .read(targetProvider
                                                                .notifier)
                                                            .updateTarget(0);
                                                        ref
                                                            .read(
                                                                targetRatioProvider(
                                                                        userId)
                                                                    .notifier)
                                                            .init();
                                                      });
                                                    },
                                                  ),
                                            hintStyle: const TextStyle(
                                                color: Colors.grey),
                                            hintText: "Search",
                                          ),
                                          onTap: () {
                                            if (!_showList) {
                                              setState(() {
                                                _showList = true;
                                                _isSearchBarFocused = true;

                                                FocusScope.of(context)
                                                    .requestFocus(FocusNode());
                                                _numberController.clear();
                                              });
                                            }
                                          },
                                          onChanged: (value) {
                                            ref
                                                .read(searchTermProvider.notifier)
                                                .state = value;
                                            ref
                                                .read(selectedProductProvider
                                                    .notifier)
                                                .state
                                                .state = value;
                                          },
                                          onSubmitted: (value) {
                                            setState(() {
                                              _showList = false;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_showList)
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(33),
                                          ),
                                          color: Colors.orange[50],
                                        ),
                                        child: products.when(
                                          data: (data) {
                                            final filteredProducts = data
                                                .where((product) => product[
                                                        'name']
                                                    .toLowerCase()
                                                    .contains(ref
                                                        .watch(
                                                            searchTermProvider)
                                                        .toLowerCase()))
                                                .toList();
                                            return ListView.builder(
                                              itemCount:
                                                  filteredProducts.isEmpty
                                                      ? 1
                                                      : filteredProducts.length,
                                              itemBuilder: (context, index) {
                                                if (filteredProducts.isEmpty) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              33),
                                                      color: Colors.white,
                                                    ),
                                                    margin: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                    child: ListTile(
                                                      title: Text(
                                                          'Not found what you\'re looking for?'),
                                                      trailing: Container(
                                                        padding: EdgeInsets.fromLTRB(4,8,4,8),
                                                      decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                            Colors.black.withOpacity(0.2),
                                                            spreadRadius: 2,
                                                            blurRadius: 16,
                                                            offset: Offset(4,
                                                                4), // changes position of shadow
                                                          ),
                                                        ],
                                                        gradient: LinearGradient(
                                                          colors: [
                                                            Colors.orange[50]!,
                                                            Colors.orange[200]!,
                                                            Colors.orange[300]!,
                                                          ],
                                                          stops: [
                                                            0.0,
                                                            0.5,
                                                            0.9,
                                                          ],
                                                        ),
                                                      borderRadius: const BorderRadius.all(
                                                      Radius.circular(33),

                                                    ),),
                                                        child: IconButton(
                                                            icon: Icon(Icons.add),
                                                            color: Colors.brown[400],
                                                            tooltip: 'Add product',
                                                            onPressed: () async {
                                                              final _productNameController =
                                                                  TextEditingController();
                                                              final _targetController =
                                                                  TextEditingController();

                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return Dialog(
                                                                      child:
                                                                          Container(
                                                                        padding:
                                                                            EdgeInsets.all(
                                                                                16),
                                                                        height: MediaQuery.of(context)
                                                                                .size
                                                                                .height *
                                                                            0.35, // 30% of screen height
                                                                        width: MediaQuery.of(context)
                                                                                .size
                                                                                .width *
                                                                            0.80, // 75% of screen width
                                                                        child:
                                                                            Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceEvenly,
                                                                          children: <Widget>[
                                                                            Text(
                                                                                "Add a new product"),
                                                                            TextField(
                                                                              controller:
                                                                                  _productNameController,
                                                                              decoration:
                                                                                  InputDecoration(labelText: 'Product Name'),
                                                                            ),
                                                                            TextField(
                                                                              controller:
                                                                                  _targetController,
                                                                              decoration:
                                                                                  InputDecoration(labelText: 'Target'),
                                                                              keyboardType:
                                                                                  TextInputType.number,
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.spaceEvenly,
                                                                              children: [
                                                                                TextButton(
                                                                                  child: Text('Cancel'),
                                                                                  onPressed: () {
                                                                                    Navigator.of(context).pop();
                                                                                  },
                                                                                ),
                                                                                TextButton(
                                                                                  child: Text('Add'),
                                                                                  onPressed: () async {
                                                                                    final String productName = _productNameController.text;
                                                                                    final int target = int.parse(_targetController.text);
                                                                                    await ref.read(pressingRepositoryProvider).addProduct(productName, target);
                                                                                    Navigator.of(context).pop();
                                                                                  },
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    );
                                                                  });
                                                            }),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                // If the index is not 0, adjust it by 1 to get the correct product
                                                else {
                                                  final product = filteredProducts[index];
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          33),
                                                      color: Colors.white,
                                                    ),
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                    child: ListTile(
                                                      title:
                                                      Text(product['name']),
                                                      subtitle: Text(
                                                          'Target: ${((product['target']
                                                              ?.toDouble() ??
                                                              0) *
                                                              ((workingHours -
                                                                  allowance) /
                                                                  7.00))
                                                              .ceil()}'),
                                                      onTap: () {
                                                        String
                                                        selectedProductName =
                                                        product['name'];
                                                        ref
                                                            .watch(
                                                            selectedProductProvider
                                                                .notifier)
                                                            .state
                                                            .state =
                                                            selectedProductName;
                                                        _textEditingController
                                                            .text =
                                                            selectedProductName
                                                                .toString(); // Update the controller's text
                                                        _showList = false;
                                                        _isFocused = true;

                                                        // Update the targetProvider state when a product is selected
                                                        int productTarget = (((product[
                                                        'target']
                                                            ?.toDouble()) *
                                                            ((workingHours -
                                                                allowance) /
                                                                7.00))
                                                            .ceil());
                                                        ref
                                                            .read(targetProvider
                                                            .notifier)
                                                            .updateTarget(
                                                            productTarget);
                                                      },
                                                    ),
                                                  );
                                                }},
                                            );
                                          },
                                          loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                          error: (error, stackTrace) =>
                                              Text('Error: $error'),
                                        ),
                                      ),
                                    ),
                                  if (!_showList && productName != '')
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.66,
                                      height:
                                          MediaQuery.of(context).size.width *
                                              0.66,
                                      child: Image.asset(
                                        'assets/images/${productName.split(' ').join('_')}.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (BuildContext context,
                                            Object exception,
                                            StackTrace? stackTrace) {
                                          // If the image fails to load, load a Lottie animation
                                          return Lottie.asset(
                                              'assets/lottie/product_image_not_found.json');
                                        },
                                      ),
                                    ),
                                  if (!_showList && productName == "")
                                    Container(
                                      width: 256,
                                      height: 256,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.orange[100]!,
                                            Colors.orange[200]!,
                                            Colors.orange[300]!,
                                            Colors.orange[400]!,
                                            Colors.black,
                                          ],
                                          stops: [
                                            0.0,
                                            0.3,
                                            0.5,
                                            0.7,
                                            1.0
                                          ], // controls the color transition positions
                                          center: Alignment(-0.5,
                                              -0.5), // shift the center alignment to mimic light reflection
                                          radius:
                                              1.5, // controls the overall radius of the gradient
                                          focal: Alignment(-0.5,
                                              -0.5), // controls the focal point of the gradient
                                          focalRadius:
                                              0.1, // controls the radius of the focal point
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 5,
                                            blurRadius: 12,
                                            offset: Offset(4,
                                                4), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: 75,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!_showList)
                                    Form(
                                      key: _formKey,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            4, 0, 4, 0),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.40,
                                              child: TextFormField(
                                                focusNode: _numberFocusNode,
                                                controller: _numberController,
                                                textAlign: TextAlign.center,
                                                // Center the text
                                                decoration: InputDecoration(
                                                  alignLabelWithHint: true,
                                                  labelText: 'Amount pressed',
                                                  contentPadding:
                                                      const EdgeInsets
                                                              .symmetric(
                                                          vertical: 4.0),
                                                  fillColor:
                                                      Colors.yellowAccent[100],
                                                  // Add the color of the search bar widget here
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            33),
                                                    // Rounded edges
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  prefixIcon: const Icon(Icons
                                                      .numbers_outlined), // Add an icon symbolizing number input here
                                                ),
                                                keyboardType:
                                                    const TextInputType
                                                            .numberWithOptions(
                                                        decimal: false,
                                                        signed: false),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a number';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  int parsedValue =
                                                      int.tryParse(value) ?? 0;
                                                  print(
                                                      'here is allowance in number provider${allowance}');
                                                  ref
                                                      .read(numberProvider
                                                          .notifier)
                                                      .updateNumber(
                                                          parsedValue);
                                                  print(allowance);

                                                  ref
                                                      .watch(
                                                          targetRatioProvider(
                                                                  userId)
                                                              .notifier)
                                                      .updateRatio(
                                                          productName,
                                                          productTarget,
                                                          parsedValue,
                                                          workingHours,
                                                          allowance);
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child: SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.40,
                                                child: TextFormField(
                                                  controller:
                                                      allowanceController,
                                                  decoration: InputDecoration(
                                                    alignLabelWithHint: true,
                                                    labelText: 'Allowance',
                                                    contentPadding:
                                                        const EdgeInsets
                                                                .symmetric(
                                                            vertical: 8.0),
                                                    fillColor: Colors
                                                        .yellowAccent[100],
                                                    filled: true,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              33),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    prefixIcon:
                                                        const Icon(Icons.timer),
                                                  ),
                                                  keyboardType:
                                                      const TextInputType
                                                              .numberWithOptions(
                                                          decimal: false,
                                                          signed: false),
                                                  onChanged: (value) {
                                                    int parsedValue =
                                                        int.tryParse(value) ??
                                                            0;
                                                    double allowanceProvided =
                                                        parsedValue == 0
                                                            ? 0.0
                                                            : parsedValue / 60;
                                                    ref
                                                            .read(
                                                                allowanceProvider
                                                                    .notifier)
                                                            .state =
                                                        allowanceProvided;

                                                    // allowanceController.text = value; // Remove this line

                                                    int declaredAmount = ref
                                                        .read(numberProvider);
                                                    ref
                                                        .read(
                                                            targetRatioProvider(
                                                                    userId)
                                                                .notifier)
                                                        .updateRatio(
                                                          productName
                                                              .toLowerCase(),
                                                          productTarget,
                                                          declaredAmount,
                                                          workingHours,
                                                          allowanceProvided,
                                                        );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (!_showList)
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Transform.scale(
                                                  scale: 4.0,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 10.0,
                                                    // Divide by the scale factor
                                                    backgroundColor: Colors
                                                        .greenAccent.shade100,
                                                    valueColor:
                                                        const AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.transparent),
                                                    value: 1.0,
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Transform.scale(
                                                  scale: 4.0,
                                                  child: MinimumCircle(
                                                    percentage: percentage,
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Transform.scale(
                                                  scale: 4.0,
                                                  child: ClipOval(
                                                    child:
                                                        RainbowCircularProgressIndicator(
                                                      percentage:
                                                          percentage, // Substitute your actual percentage here
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Container(
                                                  width: 105,
                                                  height: 105,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.orange[50]!,
                                                        Colors.orange[200]!
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Consumer(
                                                  builder: (context, watch, _) {
                                                    return Text(
                                                      '${(targetRatio * 100).toStringAsFixed(2)}%',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 3.0),
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Consumer(builder:
                                                  (context, watch, child) {
                                                final userState = ref
                                                    .watch(userNotifierProvider
                                                        .notifier)
                                                    .state;
                                                final bonus = ref.watch(
                                                    bonusValueProvider(
                                                        targetRatio));
                                                final allowance =
                                                    userState.allowance;

                                                return BonusCoin(
                                                    bonus: bonus *
                                                        ((workingHours -
                                                                (allowance ??
                                                                    0)) /
                                                            7.00));
                                              }),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  //add a new widget to the row
                                  if (!_showList)
                                    Builder(
                                      builder: (BuildContext buttonContext) {
                                        return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: LayoutBuilder(builder:
                                                (BuildContext context,
                                                    BoxConstraints
                                                        constraints) {
                                              return SizedBox(
                                                // 10
                                                width: constraints.maxWidth *
                                                    0.70, // % of the Container height
                                                // 10% of the Container height
                                                child: ElevatedButton(
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStateProperty.all(
                                                            Colors.yellowAccent[
                                                                100]),
                                                    shape: MaterialStateProperty
                                                        .all<
                                                            RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: (productName
                                                              .isEmpty ||
                                                          amount == 0)
                                                      ? null
                                                      : () async {
                                                          final authRepository =
                                                              ref.read(
                                                                  authRepositoryProvider);
                                                          final pressingRepository =
                                                              ref.read(
                                                                  pressingRepositoryProvider);
                                                          final bonusAsyncValue =
                                                              ref.read(
                                                                  bonusValueProvider(
                                                                      targetRatio)); // changed watch to read
                                                          final String userId =
                                                              authRepository
                                                                  .currentUserId;
                                                          final String
                                                              productName = ref
                                                                  .read(
                                                                      selectedProductProvider)
                                                                  .state;
                                                          double bonus =
                                                              bonusAsyncValue *
                                                                  ((workingHours -
                                                                          allowance) /
                                                                      7.0);
                                                          final productRatioProvider =
                                                              ref.watch(
                                                                  targetRatioProvider(
                                                                          userId)
                                                                      .notifier);
                                                          final double
                                                              productRatio =
                                                              productRatioProvider
                                                                  .getProductRatio(
                                                                      productName);
                                                          print(productRatio);
                                                          // Retrieve the bonus value

                                                          try {
                                                            await pressingRepository.saveUserBonus(
                                                                userId,
                                                                productName,
                                                                bonus,
                                                                amount,
                                                                productRatio,
                                                                workingHours: (userState
                                                                            .paidBreaks ??
                                                                        false)
                                                                    ? (userState
                                                                            .realWorkingHours ??
                                                                        0)
                                                                    : (userState
                                                                            .workingHours ??
                                                                        0));
                                                            // Show a success message
                                                            ScaffoldMessenger.of(
                                                                    buttonContext)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Saved to Wallet successfully!'),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            if (e is String) {
                                                              ref
                                                                  .read(targetRatioProvider(
                                                                          userId)
                                                                      .notifier)
                                                                  .init();
                                                              // Handle the case where the bonus is already added today
                                                              ScaffoldMessenger.of(
                                                                      buttonContext)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'This product has been overwritten because it was already added today.',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .orange,
                                                                ),
                                                              );
                                                              // Call editUserBonus if saveUserBonus fails
                                                              await pressingRepository
                                                                  .editUserBonus(
                                                                e,
                                                                // Pass the bonusId as the first parameter
                                                                productName,
                                                                bonus,
                                                                amount,
                                                              );
                                                            } else {
                                                              print(e);
                                                              // Show an error message for other exceptions
                                                              ScaffoldMessenger.of(
                                                                      buttonContext)
                                                                  .showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                      e.toString()),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          }

                                                          // Show a success message or navigate to another screen
                                                        },
                                                  child: const Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    // Center the content horizontally
                                                    children: [
                                                      Icon(Icons.wallet),
                                                      // Add your desired icon
                                                      SizedBox(width: 8),
                                                      // Add some space between the icon and the text
                                                      Text('Save to Wallet'),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }));
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ]), // FrontFlipCard
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: Stack(children: [
                            Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  minWidth: isWideScreen ? 500 : 0.0,
                                ),
                                width: containerWidth,
                                height: containerHeight,
                                margin:
                                    const EdgeInsets.fromLTRB(20, 10, 10, 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.lightBlue[100]!,
                                      Colors.lightBlueAccent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.6),
                                      offset: const Offset(0, 4),
                                      blurRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.4),
                                      offset: const Offset(0, -4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(

                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
                                              width: ((_isFocused || _showList)
                                                  ? MediaQuery.of(context).size.width * 0.5
                                                  : MediaQuery.of(context).size.width * 0.15),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(33),
                                                  color:
                                                      Colors.yellowAccent[100]),
                                              child: TextField(
                                                controller:
                                                    _textEditingController,
                                                textAlign: TextAlign.center,
                                                textAlignVertical:
                                                    TextAlignVertical.center,
                                                readOnly: _overtimeHours ==
                                                    0.0, // Make TextField read-only if _overtimeHours is not set
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,

                                                  suffixIcon:
                                                      _textEditingController
                                                                  .text.isEmpty &&
                                                              !_isSearchBarFocused
                                                          ? const Center(
                                                              child: Icon(Icons
                                                                  .search_rounded))
                                                          : IconButton(
                                                              icon: const Icon(
                                                                  Icons.clear),
                                                              onPressed: () {
                                                                setState(() {
                                                                  ref
                                                                      .read(searchTermProvider
                                                                          .notifier)
                                                                      .state = "";
                                                                  ref
                                                                      .read(selectedProductProvider
                                                                          .notifier)
                                                                      .state
                                                                      .state = "";
                                                                  _textEditingController
                                                                      .clear();
                                                                  _overtimeAmountController.text = '';
                                                                  _showList =
                                                                      false;
                                                                  _isSearchBarFocused =
                                                                      false;
                                                                  _isFocused = false;
                                                                  FocusScope.of(
                                                                          context)
                                                                      .requestFocus(
                                                                          FocusNode());
                                                                  _numberController
                                                                      .clear();

                                                                  int productTarget =
                                                                      ref.read(
                                                                          targetProvider);

                                                                  ref
                                                                      .read(targetProvider
                                                                          .notifier)
                                                                      .updateTarget(
                                                                          0);
                                                                  ref
                                                                      .read(targetRatioProvider(
                                                                              userId)
                                                                          .notifier)
                                                                      .init();
                                                                });
                                                              },
                                                            ),
                                                  hintStyle: const TextStyle(
                                                      color: Colors.grey),
                                                  hintText: "Search",
                                                ),
                                                onTap: () {
                                                  if (_overtimeHours == 0.0) {
                                                    // If _overtimeHours is not set, show a dialog
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          Dialog(
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    20.0)), //this right here
                                                        child: Container(
                                                          height: 300,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12.0),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Center(
                                                                  child: Lottie.asset(
                                                                      'assets/lottie/alert.json',
                                                                      width: 100,
                                                                      height:
                                                                          100), // Lottie animation
                                                                ),
                                                                SizedBox(
                                                                    height: 20),
                                                                Text(
                                                                  'Hey there!',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          16),
                                                                ),
                                                                SizedBox(
                                                                    height: 10),
                                                                Text(
                                                                  'Before you proceed with searching products, please set your overtime hours.',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14),
                                                                ),
                                                                SizedBox(
                                                                    height: 20),
                                                                Align(
                                                                  alignment: Alignment
                                                                      .bottomRight,
                                                                  child:
                                                                      TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context)
                                                                                .pop();
                                                                          },
                                                                          child: Text(
                                                                              'Got it!')),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    if (!_showList) {
                                                      setState(() {
                                                        _showList = true;
                                                        _isSearchBarFocused =
                                                            true;

                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                FocusNode());
                                                        _numberController.clear();
                                                      });
                                                    }
                                                  }
                                                },
                                                onChanged: (value) {
                                                  ref
                                                      .read(searchTermProvider
                                                          .notifier)
                                                      .state = value;
                                                  ref
                                                      .read(
                                                          selectedProductProvider
                                                              .notifier)
                                                      .state
                                                      .state = value;
                                                },
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    _showList = false;
                                                  });
                                                },
                                              )),
                                        ),
                                        AnimatedContainer(
                                            duration: Duration(milliseconds: 400),
                                          width: ((_isFocused || _showList)
                                              ? MediaQuery.of(context).size.width * 0.15
                                              : MediaQuery.of(context).size.width * 0.25),
                                          child: TextFormField(
                                            onChanged: (value) {
                                              ref.watch(overtimeWorkingHoursState.notifier).state = int.tryParse(value);
                                            },
                                            controller:
                                                _overtimeWorkingHoursController,
                                            decoration: InputDecoration(
                                              alignLabelWithHint: true,
                                              labelText: 'Hours',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 1.0,),
                                              fillColor:
                                                  Colors.yellowAccent[100],
                                              filled: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(33),
                                                borderSide: BorderSide.none,
                                              ),
                                              prefixIcon:
                                                  const Icon(Icons.timer),
                                            ),
                                            keyboardType: const TextInputType
                                                    .numberWithOptions(
                                                decimal: false, signed: false),
                                            enabled: ((productName != '' || _isSearchBarFocused) ? false : true), // disable TextField when productName is empty
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_showList)
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(33),
                                            ),
                                            color: Colors.orange[50],
                                          ),
                                          child: products.when(
                                            data: (data) {
                                              final filteredProducts = data
                                                  .where((product) => product[
                                                          'name']
                                                      .toLowerCase()
                                                      .contains(ref
                                                          .watch(
                                                              searchTermProvider)
                                                          .toLowerCase()))
                                                  .toList();
                                              return ListView.builder(
                                                itemCount:
                                                    filteredProducts.length,
                                                itemBuilder: (context, index) {
                                                  final product =
                                                      filteredProducts[index];
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              33),
                                                      color: Colors.white,
                                                    ),
                                                    margin: const EdgeInsets
                                                            .symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                    child: ListTile(
                                                      title:
                                                          Text(product['name']),
                                                      subtitle: Text(
                                                          'Target: ${((product['target']?.toDouble() ?? 0) * (_effectiveOvertimeHours / 7.00)).ceil()}'),
                                                      onTap: () {
                                                        String
                                                            selectedProductName =
                                                            product['name'];
                                                        ref
                                                                .watch(
                                                                    selectedProductProvider
                                                                        .notifier)
                                                                .state
                                                                .state =
                                                            selectedProductName;
                                                        _textEditingController
                                                                .text =
                                                            selectedProductName
                                                                .toString(); // Update the controller's text
                                                        _showList = false;
                                                        _isFocused = true;


                                                        // Update the targetProvider state when a product is selected
                                                        int productTarget =
                                                            (((product['target']
                                                                        ?.toDouble()) *
                                                                    ((_effectiveOvertimeHours) /
                                                                        7.00))
                                                                .ceil());
                                                        ref
                                                            .read(targetProvider
                                                                .notifier)
                                                            .updateTarget(
                                                                productTarget);
                                                        _overtimeAmountController.text = '';
                                                      },
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            loading: () => const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                            error: (error, stackTrace) =>
                                                Text('Error: $error'),
                                          ),
                                        ),
                                      ),
                                    if (!_showList && productName != '')
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.66,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.66,
                                        child: Image.asset(
                                          'assets/images/${productName.split(' ').join('_')}.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    if (!_showList && productName == "")
                                      Container(
                                        width: 256,
                                        height: 256,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.blue[100]!,
                                              Colors.blue[200]!,
                                              Colors.blue[300]!,
                                              Colors.blue[400]!,
                                              Colors.black,
                                            ],
                                            stops: [
                                              0.0,
                                              0.3,
                                              0.5,
                                              0.7,
                                              1.0
                                            ], // controls the color transition positions
                                            center: Alignment(-0.5,
                                                -0.5), // shift the center alignment to mimic light reflection
                                            radius:
                                                1.5, // controls the overall radius of the gradient
                                            focal: Alignment(-0.5,
                                                -0.5), // controls the focal point of the gradient
                                            focalRadius:
                                                0.1, // controls the radius of the focal point
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              spreadRadius: 5,
                                              blurRadius: 12,
                                              offset: Offset(4,
                                                  4), // changes position of shadow
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '?',
                                            style: TextStyle(
                                              fontSize: 75,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!_showList)
                                      Form(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              4, 0, 4, 0),
                                          child: Center(
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.40,
                                              child: TextFormField(
                                                controller:
                                                    _overtimeAmountController,
                                                textAlign: TextAlign.center,
                                                // Center the text
                                                decoration: InputDecoration(
                                                  alignLabelWithHint: true,
                                                  labelText: 'Amount',
                                                  contentPadding:
                                                      const EdgeInsets
                                                              .symmetric(
                                                          vertical: 4.0),
                                                  fillColor:
                                                      Colors.yellowAccent[100],
                                                  // Add the color of the search bar widget here
                                                  filled: true,
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            33),
                                                    // Rounded edges
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  prefixIcon: const Icon(Icons
                                                      .numbers_outlined), // Add an icon symbolizing number input here
                                                ),
                                                keyboardType:
                                                    const TextInputType
                                                            .numberWithOptions(
                                                        decimal: false,
                                                        signed: false),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly
                                                ],
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter a number';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  ref
                                                      .read(
                                                          overtimeRatioProvider
                                                              .notifier)

                                                      .state = (_overtimeAmount / productTarget);
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!_showList)
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 200,
                                            height: 200,
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child: Transform.scale(
                                                    scale: 4.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 10.0,
                                                      // Divide by the scale factor
                                                      backgroundColor: Colors
                                                          .greenAccent.shade100,
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors
                                                                  .transparent),
                                                      value: 1.0,
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: Transform.scale(
                                                    scale: 4.0,
                                                    child: MinimumCircle(
                                                      percentage:
                                                          _overtimePercents,
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: Transform.scale(
                                                    scale: 4.0,
                                                    child: ClipOval(
                                                      child:
                                                          RainbowCircularProgressIndicator(
                                                        percentage:
                                                            _overtimePercents, // Substitute your actual percentage here
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: Container(
                                                    width: 105,
                                                    height: 105,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:
                                                          Colors.green.shade50,
                                                    ),
                                                  ),
                                                ),
                                                Center(
                                                  child: Consumer(
                                                    builder:
                                                        (context, watch, _) {
                                                      return Text(
                                                        '${(_overtimePercents).toStringAsFixed(2)}%',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 3.0),
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Consumer(builder:
                                                    (context, watch, child) {
                                                  final userState = ref
                                                      .watch(
                                                          userNotifierProvider
                                                              .notifier)
                                                      .state;
                                                  final bonus = ref.watch(
                                                      bonusValueProvider(
                                                          _overtimePercents /
                                                              100));
                                                  final allowance =
                                                      userState.allowance;

                                                  return BonusCoin(
                                                      bonus: bonus *
                                                          (_overtimeHours /
                                                              7.00));
                                                }),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    //add a new widget to the row
                                    if (!_showList)
                                      Builder(
                                        builder: (BuildContext buttonContext) {
                                          return Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: LayoutBuilder(builder:
                                                  (BuildContext context,
                                                      BoxConstraints
                                                          constraints) {
                                                return SizedBox(
                                                  // 10
                                                  width: constraints.maxWidth *
                                                      0.70, // % of the Container height
                                                  // 10% of the Container height
                                                  child: ElevatedButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all(Colors
                                                                      .yellowAccent[
                                                                  100]),
                                                      shape: MaterialStateProperty
                                                          .all<
                                                              RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: (productName
                                                                .isEmpty ||
                                                            _overtimeAmount ==
                                                                0 ||
                                                            _overtimeHours == 0)
                                                        ? null
                                                        : () async {
                                                            final authRepository =
                                                                ref.read(
                                                                    authRepositoryProvider);
                                                            final pressingRepository =
                                                                ref.read(
                                                                    pressingRepositoryProvider);
                                                            print(
                                                                _overtimePercents);
                                                            final bonusChecker =
                                                                ref.read(bonusValueProvider(
                                                                    _overtimePercents /
                                                                        100));
                                                            final double bonus =
                                                                bonusChecker *
                                                                    (_overtimeHours /
                                                                        7);
                                                            final String
                                                                userId =
                                                                authRepository
                                                                    .currentUserId;
                                                            final String
                                                                productName =
                                                                ref
                                                                    .read(
                                                                        selectedProductProvider)
                                                                    .state;
                                                            final productRatioProvider =
                                                                ref.watch(targetRatioProvider(
                                                                        userId)
                                                                    .notifier);
                                                            final double
                                                                productRatio =
                                                                productRatioProvider
                                                                    .getProductRatio(
                                                                        productName);
                                                            print(productRatio);
                                                            // Retrieve the bonus value

                                                            try {
                                                              await pressingRepository.saveOvertimeUserBonus(
                                                                  userId,
                                                                  productName,
                                                                  bonus,
                                                                  _overtimeAmount,
                                                                  _overtimePercents /
                                                                      100,
                                                                  isOvertime:
                                                                      true,
                                                                  workingHours: userState
                                                                              .paidBreaks ??
                                                                          false
                                                                      ? _overtimeHours
                                                                      : _effectiveOvertimeHours);
                                                              // Show a success message
                                                              ScaffoldMessenger.of(
                                                                      buttonContext)
                                                                  .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                      'Saved to Wallet successfully!'),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              if (e is String) {
                                                                ref
                                                                    .read(targetRatioProvider(
                                                                            userId)
                                                                        .notifier)
                                                                    .init();
                                                                // Handle the case where the bonus is already added today
                                                                ScaffoldMessenger.of(
                                                                        buttonContext)
                                                                    .showSnackBar(
                                                                  const SnackBar(
                                                                    content:
                                                                        Text(
                                                                      'This product has been overwritten because it was already added today.',
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .orange,
                                                                  ),
                                                                );
                                                                // Call editUserBonus if saveUserBonus fails
                                                                await pressingRepository
                                                                    .editUserBonus(
                                                                  e,
                                                                  // Pass the bonusId as the first parameter
                                                                  productName,
                                                                  bonus,
                                                                  amount,
                                                                );
                                                              } else {
                                                                // Show an error message for other exceptions
                                                                ScaffoldMessenger.of(
                                                                        buttonContext)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                        e.toString()),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                            ref
                                                                .read(targetRatioProvider(
                                                                        userId)
                                                                    .notifier)
                                                                .init();

                                                            // Show a success message or navigate to another screen
                                                          },
                                                    child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      // Center the content horizontally
                                                      children: [
                                                        Icon(Icons.wallet),
                                                        // Add your desired icon
                                                        SizedBox(width: 8),
                                                        // Add some space between the icon and the text
                                                        Text('Save to Wallet'),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }));
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ]),
                        ), // BackFlipCard
                      ]));
            }),
      );
    });
  }
}
