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
    this.lastCompletedAt,
    this.lastPaidAmount,
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
  final DateTime? lastCompletedAt;
  final double? lastPaidAmount;

  bool get isOverdue =>
      status == ResponsibilityStatus.pending &&
      dueDate.isBefore(DateTime.now());

  bool get isRecurring => recurrenceUnit != RecurrenceUnit.none;

  Responsibility copyWith({
    String? lifeObjectId,
    String? title,
    DateTime? dueDate,
    double? expectedAmount,
    String? notes,
    ResponsibilityStatus? status,
    RecurrenceUnit? recurrenceUnit,
    int? recurrenceInterval,
    DateTime? lastCompletedAt,
    double? lastPaidAmount,
  }) {
    return Responsibility(
      id: id,
      lifeObjectId: lifeObjectId ?? this.lifeObjectId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      recurrenceUnit: recurrenceUnit ?? this.recurrenceUnit,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      lastPaidAmount: lastPaidAmount ?? this.lastPaidAmount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lifeObjectId': lifeObjectId,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'expectedAmount': expectedAmount,
        'notes': notes,
        'status': status.name,
        'recurrenceUnit': recurrenceUnit.name,
        'recurrenceInterval': recurrenceInterval,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'lastPaidAmount': lastPaidAmount,
      };

  factory Responsibility.fromJson(Map<String, dynamic> json) {
    return Responsibility(
      id: json['id'] as String,
      lifeObjectId: json['lifeObjectId'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      expectedAmount: (json['expectedAmount'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      status: ResponsibilityStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ResponsibilityStatus.pending,
      ),
      recurrenceUnit: RecurrenceUnit.values.firstWhere(
        (value) => value.name == json['recurrenceUnit'],
        orElse: () => RecurrenceUnit.none,
      ),
      recurrenceInterval: (json['recurrenceInterval'] as num?)?.toInt() ?? 1,
      lastCompletedAt: json['lastCompletedAt'] == null
          ? null
          : DateTime.parse(json['lastCompletedAt'] as String),
      lastPaidAmount: (json['lastPaidAmount'] as num?)?.toDouble(),
    );
  }
}
