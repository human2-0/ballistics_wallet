import 'package:ballistics_wallet_flutter/models/bonus_info.dart';

class BonusInfoAndRatio {
  BonusInfoAndRatio({this.bonusInfo = const [], this.ratio = 0.0});

  List<BonusInfo> bonusInfo;
  double ratio;
}
