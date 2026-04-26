/// Payroll summary for one paycheck month in wallet history.
class MonthlyData {
  /// Keeps the original positional constructor available for existing callers.
  MonthlyData(this.month, this.totalHours, this.totalBonus)
    : hourlyRate = 0,
      hoursStart = null,
      hoursEnd = null,
      bonusStart = null,
      bonusEnd = null;

  /// Creates a summary with the exact hour and bonus ranges used.
  MonthlyData.detailed({
    required this.month,
    required this.totalHours,
    required this.totalBonus,
    required this.hourlyRate,
    required this.hoursStart,
    required this.hoursEnd,
    required this.bonusStart,
    required this.bonusEnd,
  });

  /// Display label for the paycheck month.
  final String month;

  /// Working hours counted in the 20th-to-19th hour-pay period.
  final double totalHours;

  /// Bonus counted in the payroll-close bonus period.
  final double totalBonus;

  /// Hourly rate used for this summary.
  final double hourlyRate;

  /// First date included in the hour-pay period.
  final DateTime? hoursStart;

  /// Last date included in the hour-pay period.
  final DateTime? hoursEnd;

  /// First date included in the bonus period.
  final DateTime? bonusStart;

  /// Last date included in the bonus period.
  final DateTime? bonusEnd;

  /// Hourly portion of the paycheck.
  double get hourPay => totalHours * hourlyRate;

  /// Hourly pay plus bonus for this paycheck month.
  double get totalIncome => hourPay + totalBonus;

  /// Whether this month has any payable wallet data.
  bool get hasData => totalHours != 0 || totalBonus != 0;
}
