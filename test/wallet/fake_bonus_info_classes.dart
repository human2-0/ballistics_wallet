import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/ratio_and_bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bonus_info_list_test.mocks.dart';

class FakeUserNotifier extends UserNotifier {
  FakeUserNotifier() : super(MockUserRepository()) {
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

class FakeProductInfoRepository implements ProductInfoRepository {
  /// Pass in an initial list of products. If none is provided,
  /// the fake will start with an empty list.
  FakeProductInfoRepository([List<ProductInfo>? initialProducts])
      : _products = initialProducts ?? [];
  final List<ProductInfo> _products;

  @override
  Future<List<ProductInfo>> fetchProductInfo() async {
    return _products;
  }

  /// Optionally, add a method to update the products list,

  /// Update an existing product. For example, match by productName.
  void updateProduct(ProductInfo updatedProduct) {
    final index = _products.indexWhere(
      (p) => p.productName == updatedProduct.productName,
    );
    if (index != -1) {
      _products[index] = updatedProduct;
    }
  }

  /// Remove a product by name.
  void removeProduct(String productName) {
    _products.removeWhere((p) => p.productName == productName);
  }

  @override
  // TODO: implement db
  FirebaseFirestore get db => throw UnimplementedError();

  @override
  Future<void> deleteProduct(String productName) {
    // TODO: implement deleteProduct
    throw UnimplementedError();
  }

  @override
  Future<bool> editProductInfo(ProductInfo updatedProduct) {
    // TODO: implement editProductInfo
    throw UnimplementedError();
  }

  @override
  Future<void> addProduct(
    String productName,
    int target,
    List<Pressing> pressings, {
    bool ayr = true,
    String? description,
  }) {
    // TODO: implement addProduct
    throw UnimplementedError();
  }
}

/// A fake repository that implements BonusInfoRepository with minimal functionality.
class FakeBonusInfoRepositoryForBonusInfo extends BonusInfoRepository {
  @override
  Future<Map<String, double>> getAllRatiosToday() async {
    // Return an empty map (or pre-populate with some fake ratios if needed)
    return {};
  }

  @override
  Future<Box<BonusInfo>> openBox() async {
    // For our fake, we won’t use a Hive box.
    // If your FakeBonusInfoNotifier doesn’t call openBox(), you can throw or return a dummy.
    throw UnimplementedError('openBox is not used in the fake');
  }

  @override
  Future<String> addBonusInfo(BonusInfo bonusInfo) async {
    return 'Fake bonus added';
  }

  @override
  Future<void> updateBonusInfo(BonusInfo bonusInfo) async {
    // No-op in fake.
  }

  @override
  Future<void> deleteBonusInfo(BonusInfo bonusInfo) async {
    // No-op in fake.
  }

// If there are other methods, implement them minimally or throw UnimplementedError.
}

/// A fake notifier that extends BonusInfoNotifier so that it is acceptable for the provider override.
/// It bypasses repository/Hive calls by using internal in-memory storage.
class FakeBonusInfoNotifier extends BonusInfoNotifier {
  /// We call the super constructor with our fake repository and a dummy userId.
  FakeBonusInfoNotifier()
      : super(FakeBonusInfoRepositoryForBonusInfo(), 'fakeUserId') {
    // Override the initial state without triggering async initialization.
    state = BonusInfoAndRatio(bonusInfo: []);
  }
  // Internal in-memory storage for bonus info items.
  final List<BonusInfo> _bonusList = [];
  // Internal map for product ratios.
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
    // Recalculate the total ratio from _productRatios.
    final totalRatio = _productRatios.values.fold<double>(0, (a, b) => a + b);
    // Update the state with the in-memory bonus list and calculated ratio.
    state =
        BonusInfoAndRatio(bonusInfo: List.from(_bonusList), ratio: totalRatio);
  }

  @override
  Future<double> getTotalWorkingHours() async {
    return _bonusList.fold<double>(0, (sum, b) => sum + b.workingHours);
  }

  @override
  Future<double> getTotalBonus() async {
    return _bonusList.fold<double>(0, (sum, b) => sum + b.bonus);
  }

  @override
  void updateRatio(
    String productName,
    int productTarget,
    int userNumber,
    double workingHours,
    double allowanceProvided,
  ) {
    var productTargetAdjusted = 0;
    if (workingHours > 0) {
      productTargetAdjusted =
          (productTarget * ((workingHours - allowanceProvided) / workingHours))
              .ceil();
    } else {
      productTargetAdjusted = productTarget;
    }
    if (userNumber == 0 || productTargetAdjusted == 0) {
      _productRatios.remove(productName);
    } else {
      final newRatio = userNumber / productTargetAdjusted.toDouble();
      _productRatios[productName] = newRatio;
    }
    final totalRatio = _productRatios.values.fold<double>(0, (a, b) => a + b);
    state =
        BonusInfoAndRatio(bonusInfo: List.from(_bonusList), ratio: totalRatio);
  }

// Optionally, override other methods (like getTotalWorkingHours, getHistoricalMonthlyData, etc.)
// with in-memory calculations if your tests need them.
}
