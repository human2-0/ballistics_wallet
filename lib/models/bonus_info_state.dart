// add_bonus_info_state.dart


class AddBonusInfoState {

  AddBonusInfoState({
    required this.producedData,
    this.bonus = 0.0,
    this.workingHours = 0.0,
    this.isOvertime = false,
    this.isLoading = false,
    this.error,
  });
  final List<Map<String, String>> producedData; // Holds productName and amount as strings
  final double bonus;
  final double workingHours;
  final bool isOvertime;
  final bool isLoading;
  final String? error;

  AddBonusInfoState copyWith({
    List<Map<String, String>>? producedData,
    double? bonus,
    double? workingHours,
    bool? isOvertime,
    bool? isLoading,
    String? error,
  }) {
    return AddBonusInfoState(
      producedData: producedData ?? this.producedData,
      bonus: bonus ?? this.bonus,
      workingHours: workingHours ?? this.workingHours,
      isOvertime: isOvertime ?? this.isOvertime,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
