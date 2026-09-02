import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../domain/life_object.dart';
import '../domain/responsibility.dart';
import '../notifications/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController(this._store, this._notifications);

  final LocalStore _store;
  final NotificationService _notifications;

  final List<LifeObject> _objects = [];
  final List<Responsibility> _responsibilities = [];

  List<LifeObject> get objects => List.unmodifiable(_objects);
  List<Responsibility> get responsibilities => List.unmodifiable(_responsibilities);

  Future<void> load() async {
    _objects
      ..clear()
      ..addAll(await _store.loadObjects());
    _responsibilities
      ..clear()
      ..addAll(await _store.loadResponsibilities());

    if (_objects.isEmpty) {
      _objects.addAll([
        const LifeObject(id: 'home', name: 'Casa', type: LifeObjectType.home),
        const LifeObject(id: 'car', name: 'Auto', type: LifeObjectType.vehicle),
        const LifeObject(id: 'me', name: 'Io', type: LifeObjectType.person),
      ]);
      await _store.saveObjects(_objects);
    }
    await _syncNotifications();
    notifyListeners();
  }

  Future<void> addObject({
    required String name,
    required LifeObjectType type,
    String? details,
  }) async {
    _objects.add(
      LifeObject(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        type: type,
        details: _clean(details),
      ),
    );
    await _persistObjects();
  }

  Future<void> updateObject(
    LifeObject object, {
    required String name,
    required LifeObjectType type,
    String? details,
  }) async {
    final index = _objects.indexWhere((item) => item.id == object.id);
    if (index < 0) return;
    _objects[index] = LifeObject(
      id: object.id,
      name: name.trim(),
      type: type,
      details: _clean(details),
    );
    await _persistObjects();
  }

  Future<void> deleteObject(LifeObject object) async {
    _objects.removeWhere((item) => item.id == object.id);
    _responsibilities.removeWhere((item) => item.lifeObjectId == object.id);
    await _store.saveObjects(_objects);
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> addResponsibility({
    required String lifeObjectId,
    required String title,
    required DateTime dueDate,
    double? expectedAmount,
    String? notes,
    RecurrenceUnit recurrenceUnit = RecurrenceUnit.none,
    int recurrenceInterval = 1,
  }) async {
    _responsibilities.add(
      Responsibility(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        lifeObjectId: lifeObjectId,
        title: title.trim(),
        dueDate: dueDate,
        expectedAmount: expectedAmount,
        notes: _clean(notes),
        recurrenceUnit: recurrenceUnit,
        recurrenceInterval: recurrenceInterval,
      ),
    );
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> updateResponsibility(
    Responsibility item, {
    required String lifeObjectId,
    required String title,
    required DateTime dueDate,
    double? expectedAmount,
    String? notes,
    required RecurrenceUnit recurrenceUnit,
    required int recurrenceInterval,
  }) async {
    final index = _responsibilities.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    _responsibilities[index] = item.copyWith(
      lifeObjectId: lifeObjectId,
      title: title.trim(),
      dueDate: dueDate,
      expectedAmount: expectedAmount,
      notes: _clean(notes),
      recurrenceUnit: recurrenceUnit,
      recurrenceInterval: recurrenceInterval,
    );
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> deleteResponsibility(Responsibility item) async {
    _responsibilities.removeWhere((value) => value.id == item.id);
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> completeResponsibility(
    Responsibility item, {
    double? paidAmount,
  }) async {
    final index = _responsibilities.indexWhere((value) => value.id == item.id);
    if (index < 0) return;

    final now = DateTime.now();
    if (item.isRecurring) {
      _responsibilities[index] = item.copyWith(
        dueDate: _nextDueDate(item),
        status: ResponsibilityStatus.pending,
        lastCompletedAt: now,
        lastPaidAmount: paidAmount,
      );
    } else {
      _responsibilities[index] = item.copyWith(
        status: ResponsibilityStatus.completed,
        lastCompletedAt: now,
        lastPaidAmount: paidAmount,
      );
    }

    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> dismissResponsibility(Responsibility item) async {
    final index = _responsibilities.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    _responsibilities[index] = item.copyWith(status: ResponsibilityStatus.dismissed);
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> restoreResponsibility(Responsibility item) async {
    final index = _responsibilities.indexWhere((value) => value.id == item.id);
    if (index < 0) return;
    _responsibilities[index] = item.copyWith(status: ResponsibilityStatus.pending);
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> sendTestNotification() => _notifications.showTestNotification();

  double expectedAmountForMonth(DateTime month) {
    return _responsibilities
        .where(
          (item) =>
              item.status == ResponsibilityStatus.pending &&
              item.dueDate.year == month.year &&
              item.dueDate.month == month.month &&
              item.expectedAmount != null,
        )
        .fold(0, (sum, item) => sum + item.expectedAmount!);
  }

  int dueThisMonth(DateTime month) => _responsibilities
      .where(
        (item) =>
            item.status == ResponsibilityStatus.pending &&
            item.dueDate.year == month.year &&
            item.dueDate.month == month.month,
      )
      .length;

  Future<void> _persistObjects() async {
    await _store.saveObjects(_objects);
    notifyListeners();
  }

  Future<void> _persistResponsibilities() async {
    await _store.saveResponsibilities(_responsibilities);
    await _syncNotifications();
  }

  Future<void> _syncNotifications() => _notifications.sync(_responsibilities);

  DateTime _nextDueDate(Responsibility item) {
    final interval = item.recurrenceInterval;
    switch (item.recurrenceUnit) {
      case RecurrenceUnit.days:
        return item.dueDate.add(Duration(days: interval));
      case RecurrenceUnit.weeks:
        return item.dueDate.add(Duration(days: interval * 7));
      case RecurrenceUnit.months:
        return _safeDate(
          item.dueDate.year,
          item.dueDate.month + interval,
          item.dueDate.day,
        );
      case RecurrenceUnit.years:
        return _safeDate(
          item.dueDate.year + interval,
          item.dueDate.month,
          item.dueDate.day,
        );
      case RecurrenceUnit.none:
        return item.dueDate;
    }
  }

  DateTime _safeDate(int year, int month, int day) {
    final normalized = DateTime(year, month, 1);
    final lastDay = DateTime(normalized.year, normalized.month + 1, 0).day;
    return DateTime(normalized.year, normalized.month, day.clamp(1, lastDay));
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
