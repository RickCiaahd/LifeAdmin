enum ResponsibilityStatus { pending, completed, renewed, dismissed }

enum RecurrenceUnit { none, days, weeks, months, years }

class Responsibility {
  const Responsibility({
    required this.id,
    required this.lifeObjectId,
    required this.title,
    required this.dueDate,
    this.expectedAmount,
    this.notes,
    this.status = ResponsibilityStatus.pending,
    this.recurrenceUnit = RecurrenceUnit.none,
    this.recurrenceInterval = 1,
  });

  final String id;
  final String lifeObjectId;
  final String title;
  final DateTime dueDate;
  final double? expectedAmount;
  final String? notes;
  final ResponsibilityStatus status;
  final RecurrenceUnit recurrenceUnit;
  final int recurrenceInterval;

  bool get isOverdue =>
      status == ResponsibilityStatus.pending &&
      dueDate.isBefore(DateTime.now());
}
