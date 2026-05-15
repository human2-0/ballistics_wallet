class SplitCalculator {
  SplitCalculator(this.required, this.perBatch, this.hours);
  final int required;
  final int perBatch;
  final double hours;

  int get batches => (perBatch > 0 ? (required / perBatch).floor() : 1);
  int get extra => (perBatch > 0 ? (required % perBatch) : 0);
  int get timePerBatch =>
      batches > 0 ? ((hours - 0.25) / batches * 60).ceil() : 1;
}
