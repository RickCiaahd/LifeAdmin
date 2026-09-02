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
  List<Responsibility> get responsibilities =>
      List.unmodifiable(_responsibilities);

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
        details: details?.trim().isEmpty == true ? null : details?.trim(),
      ),
    );
    await _store.saveObjects(_objects);
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
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        recurrenceUnit: recurrenceUnit,
        recurrenceInterval: recurrenceInterval,
      ),
    );
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
    _responsibilities[index] =
        item.copyWith(status: ResponsibilityStatus.dismissed);
    await _persistResponsibilities();
    notifyListeners();
  }

  Future<void> _persistResponsibilities() async {
    await _store.saveResponsibilities(_responsibilities);
    await _syncNotifications();
  }

  Future<void> _syncNotifications() =>
      _notifications.sync(_responsibilities);

  DateTime _nextDueDate(Responsibility item) {
    final interval = item.recurrenceInterval;
    switch (item.recurrenceUnit) {
      case RecurrenceUnit.days:
        return item.dueDate.add(Duration(days: interval));
      case RecurrenceUnit.weeks:
        return item.dueDate.add(Duration(days: interval * 7));
      case RecurrenceUnit.months:
        return DateTime(
          item.dueDate.year,
          item.dueDate.month + interval,
          item.dueDate.day,
        );
      case RecurrenceUnit.years:
        return DateTime(
          item.dueDate.year + interval,
          item.dueDate.month,
          item.dueDate.day,
        );
      case RecurrenceUnit.none:
        return item.dueDate;
    }
  }
}
