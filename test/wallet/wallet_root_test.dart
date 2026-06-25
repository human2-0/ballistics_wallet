import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/ratio_and_bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/wallet_root.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────
// Helper fakes that let us tweak the hourly‑rate easily in these tests.
// ─────────────────────────────────────────────────────────────────────────

void main() {
  late FakeBonusInfoNotifier fakeBonusNotifier;
  late FakeUserNotifier fakeUserNotifier;
  late FakeProductInfoNotifier fakeProductInfoNotifier;

  /// Builds the WalletRoot inside a ProviderScope that injects the fakes.
  Future<void> pumpWalletRoot(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bonusInfoListProvider.overrideWith((_) => fakeBonusNotifier),
          userNotifierProvider.overrideWith((_) => fakeUserNotifier),
          productInfoProvider.overrideWith((_) => fakeProductInfoNotifier),
        ],
        child: const MaterialApp(home: WalletRoot()),
      ),
    );
    // First frame builds the widget; second lets the FutureBuilder complete.
    await tester.pump(); // frame 1: build
    await tester.pump(); // frame 2: Future completes
    await tester.pump(); // frame 3: widget with data
  }

  setUp(() {
    fakeBonusNotifier = FakeBonusInfoNotifier();
    fakeUserNotifier = FakeUserNotifier();
    fakeProductInfoNotifier = FakeProductInfoNotifier(const []);
  });

  testWidgets('WalletRoot top bar only shows wallet tool selectors', (
    tester,
  ) async {
    await pumpWalletRoot(tester);

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('WalletRoot shows zero totals when there is no data', (
    tester,
  ) async {
    await pumpWalletRoot(tester);

    expect(find.text('Hours\n0.00'), findsOneWidget);
    expect(find.text('Bonus\n£0.00'), findsOneWidget);
    expect(find.text('Income\n£0.00'), findsOneWidget);
  });

  testWidgets('WalletRoot updates totals after a bonus is added', (
    tester,
  ) async {
    await pumpWalletRoot(tester);

    // 1️⃣  Nothing yet – still zeros.
    expect(find.text('Bonus\n£0.00'), findsOneWidget);

    // 2️⃣  Add a sample bonus record.
    final sample = BonusInfo(
      userId: 'fakeId',
      id: 'sample',
      date: DateTime(2025),
      workingHours: 8,
      bonus: 150,
      isOvertime: false,
      produced: [Produced(productName: 'WidgetA', amount: 10, ratio: 0)],
    );

    // Because addBonusInfo is async, wrap in runAsync.
    await tester.runAsync(() => fakeBonusNotifier.addBonusInfo(sample));
    await tester.pump(); // frame 1: build
    await tester.pump(); // frame 2: Future completes
    await tester.pump(); // frame 3: widget with data

    // 3️⃣  Totals should now be: hours 8, bonus £150, income £(150+8*100)=£950
    expect(find.text('Hours\n8.00'), findsOneWidget);
    expect(find.text('Bonus\n£150.00'), findsOneWidget);
    expect(find.text('Income\n£950.00'), findsOneWidget);
  });

  testWidgets('WalletRoot reacts when hourly rate changes', (tester) async {
    await pumpWalletRoot(tester);

    // Add two different BonusInfo items (total bonus £200, total hours 12).
    final items = [
      BonusInfo(
        userId: 'fakeId',
        id: 'a',
        date: DateTime(2025, 2, 2),
        workingHours: 8,
        bonus: 100,
        isOvertime: false,
        produced: const [],
      ),
      BonusInfo(
        userId: 'fakeId',
        id: 'b',
        date: DateTime(2025, 2, 3),
        workingHours: 4,
        bonus: 100,
        isOvertime: false,
        produced: const [],
      ),
    ];

    await tester.runAsync(() async {
      for (final b in items) {
        await fakeBonusNotifier.addBonusInfo(b);
      }
    });
    await tester.pump(); // frame 1: build
    await tester.pump(); // frame 2: Future completes
    await tester.pump(); // frame 3: widget with data

    // Currently: hourlyRate = 100  -> salary  (200 + 12*100) = 1400
    expect(find.text('Income\n£1400.00'), findsOneWidget);

    // Now drop hourlyRate to 10 and watch the UI change.
    fakeUserNotifier.state = fakeUserNotifier.state.copyWith(hourlyRate: 10);
    await tester.pump(); // frame 1: build
    await tester.pump(); // frame 2: Future completes
    await tester.pump(); // frame 3: widget with data

    // New salary should be 200 + 12*10 = 320
    expect(find.text('Income\n£320.00'), findsOneWidget);
  });

  testWidgets('WalletRoot shows monthly History summaries', (tester) async {
    await tester.runAsync(() async {
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'march20',
          date: DateTime(2025, 3, 20),
          workingHours: 4,
          bonus: 10,
          isOvertime: false,
          produced: const [],
        ),
      );
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'april17',
          date: DateTime(2025, 4, 17),
          workingHours: 8,
          bonus: 50,
          isOvertime: false,
          produced: const [],
        ),
      );
    });

    await pumpWalletRoot(tester);

    await tester.tap(find.text('History').first);
    await tester.pumpAndSettle();

    expect(find.text('April 2025'), findsOneWidget);
    expect(find.text('£1260.00'), findsWidgets);
    expect(find.text('20 Mar - 19 Apr 2025'), findsOneWidget);
    expect(find.text('19 Mar - 18 Apr 2025'), findsOneWidget);
  });

  testWidgets('Stats tool shows top 3 products and filters by name', (
    tester,
  ) async {
    final now = DateTime.now().subtract(const Duration(days: 1));
    fakeProductInfoNotifier = FakeProductInfoNotifier([
      ProductInfo(
        productName: 'Alpha',
        imageName: 'Alpha',
        target: 50,
        product: [const Pressing('A', 0, 0)],
      ),
      ProductInfo(
        productName: 'Beta',
        imageName: 'Beta',
        target: 40,
        product: [const Pressing('B', 0, 0)],
      ),
      ProductInfo(
        productName: 'Gamma',
        imageName: 'Gamma',
        target: 30,
        product: [const Pressing('C', 0, 0)],
      ),
      ProductInfo(
        productName: 'Delta',
        imageName: 'Delta',
        target: 20,
        product: [const Pressing('D', 0, 0)],
      ),
    ]);

    await tester.runAsync(() async {
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'a',
          date: now,
          workingHours: 8,
          bonus: 10,
          isOvertime: false,
          produced: [Produced(productName: 'Alpha', amount: 40, ratio: 0)],
        ),
      );
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'b',
          date: now,
          workingHours: 8,
          bonus: 10,
          isOvertime: false,
          produced: [Produced(productName: 'Beta', amount: 30, ratio: 0)],
        ),
      );
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'c',
          date: now,
          workingHours: 8,
          bonus: 10,
          isOvertime: false,
          produced: [Produced(productName: 'Gamma', amount: 20, ratio: 0)],
        ),
      );
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'd',
          date: now,
          workingHours: 8,
          bonus: 10,
          isOvertime: false,
          produced: [Produced(productName: 'Delta', amount: 10, ratio: 0)],
        ),
      );
    });

    await pumpWalletRoot(tester);

    await tester.tap(find.text('Stats').first);
    await tester.pumpAndSettle();

    expect(find.text('Per-product productivity'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Delta'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Delta');
    await tester.pump();

    expect(find.text('Delta'), findsAtLeastNWidgets(1));
  });

  testWidgets('Stats chart includes year labels and opens on latest point', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (var i = 0; i < 12; i++) {
      final date = DateTime(2024, 12, 25).add(Duration(days: i));
      await fakeBonusNotifier.addBonusInfo(
        BonusInfo(
          userId: 'fakeId',
          id: 'year-$i',
          date: date,
          workingHours: 8,
          bonus: (10 + i).toDouble(),
          isOvertime: false,
          produced: [Produced(productName: 'Alpha', amount: 40, ratio: 0)],
        ),
      );
    }

    await pumpWalletRoot(tester);
    await tester.tap(find.text('Stats').first);
    await tester.pumpAndSettle();

    expect(find.text('25/12/24'), findsOneWidget);
    expect(find.text('5/1/25'), findsOneWidget);

    final horizontalChart = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalChart, findsOneWidget);

    final scrollView = tester.widget<SingleChildScrollView>(horizontalChart);
    expect(scrollView.controller, isNotNull);
    final position = scrollView.controller!.position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.pixels, position.maxScrollExtent);
  });
}

class FakeUserNotifier extends UserNotifier {
  FakeUserNotifier() : super(_FakeUserRepository()) {
    state = UserState(
      userId: 'fakeId',
      backup: false,
      realWorkingHours: 8,
      workingHours: 8,
      paidBreaks: false,
      hourlyRate: 100,
      avatarUrl: '',
      askForBackup: false,
    );
  }
}

class _FakeUserRepository extends UserRepository {
  @override
  double calculateEffectiveWorkingHours(double workingHours) => workingHours;
}

class FakeBonusInfoNotifier extends BonusInfoNotifier {
  FakeBonusInfoNotifier() : super(_FakeBonusInfoRepository(), 'fakeUserId') {
    state = BonusInfoAndRatio(bonusInfo: []);
  }

  final List<BonusInfo> _bonusList = [];
  final Map<String, double> _productRatios = {};

  @override
  Future<String> addBonusInfo(BonusInfo bonusInfo) async {
    _bonusList.add(bonusInfo);
    await loadBonusInfos();
    return 'Fake bonus added';
  }

  @override
  Future<void> updateBonusInfo(BonusInfo bonusInfo) async {
    final index = _bonusList.indexWhere((b) => b.id == bonusInfo.id);
    if (index != -1) {
      _bonusList[index] = bonusInfo;
      await loadBonusInfos();
    }
  }

  @override
  Future<void> deleteBonusInfo(BonusInfo bonusInfo) async {
    _bonusList.removeWhere((b) => b.id == bonusInfo.id);
    await loadBonusInfos();
  }

  @override
  Future<void> loadBonusInfos() async {
    final totalRatio = _productRatios.values.fold<double>(0, (a, b) => a + b);
    state = BonusInfoAndRatio(
      bonusInfo: List.from(_bonusList),
      ratio: totalRatio,
    );
  }

  @override
  Future<double> getTotalWorkingHours() async =>
      _bonusList.fold<double>(0, (total, b) => total + b.workingHours);

  @override
  Future<double> getTotalBonus() async =>
      _bonusList.fold<double>(0, (total, b) => total + b.bonus);
}

class _FakeBonusInfoRepository extends BonusInfoRepository {
  @override
  Future<Map<String, double>> getAllRatiosToday() async => {};
}

class FakeProductInfoNotifier extends ProductInfoNotifier {
  FakeProductInfoNotifier(List<ProductInfo> initial)
    : super(_FakeProductInfoRepository(initial)) {
    state = initial;
  }
}

class _FakeProductInfoRepository implements ProductInfoRepository {
  _FakeProductInfoRepository(this._products);

  final List<ProductInfo> _products;

  @override
  FirebaseFirestore get db => throw UnimplementedError();

  @override
  Future<List<ProductInfo>> fetchProductInfo() async => _products;

  @override
  Future<void> addProduct(
    String productName,
    int target,
    List<Pressing> pressings, {
    bool ayr = true,
    String? description,
    double? customWeightRangeMinGrams,
    double? customWeightRangeMaxGrams,
  }) async {}

  @override
  Future<bool> editProductInfo(ProductInfo updatedProduct) async => true;

  @override
  Future<void> deleteProduct(String productName) async {}
}
