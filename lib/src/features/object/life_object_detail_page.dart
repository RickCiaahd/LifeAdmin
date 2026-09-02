import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/life_object.dart';
import '../../domain/responsibility.dart';
import '../../state/app_controller.dart';
import '../add/add_responsibility_page.dart';

class LifeObjectDetailPage extends StatelessWidget {
  const LifeObjectDetailPage({
    super.key,
    required this.controller,
    required this.object,
  });

  final AppController controller;
  final LifeObject object;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final items = controller.responsibilities
            .where((item) => item.lifeObjectId == object.id)
            .toList();
        final active = items
            .where((item) => item.status == ResponsibilityStatus.pending)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final history = items
            .where(
              (item) =>
                  item.status != ResponsibilityStatus.pending ||
                  item.lastCompletedAt != null,
            )
            .toList()
          ..sort((a, b) {
            final aDate = a.lastCompletedAt ?? a.dueDate;
            final bDate = b.lastCompletedAt ?? b.dueDate;
            return bDate.compareTo(aDate);
          });

        return Scaffold(
          appBar: AppBar(title: Text(object.name)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddResponsibilityPage(
                  controller: controller,
                  initialLifeObjectId: object.id,
                ),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Scadenza'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    child: Icon(_iconFor(object.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (object.details != null) Text(object.details!),
                        Text('${active.length} scadenze attive'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Da gestire', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (active.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nessuna scadenza attiva per questa voce.'),
                  ),
                )
              else
                ...active.map(
                  (item) => Card(
                    child: ListTile(
                      leading: Icon(
                        item.isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.event_outlined,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${_dueLabel(item)} · ${DateFormat('dd/MM/yyyy').format(item.dueDate)}'
                        '${item.expectedAmount == null ? '' : '\n€ ${item.expectedAmount!.toStringAsFixed(2)}'}',
                      ),
                      isThreeLine: item.expectedAmount != null,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text('Storico', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Qui compariranno pagamenti, rinnovi e scadenze concluse.',
                    ),
                  ),
                )
              else
                ...history.map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(item.title),
                      subtitle: Text(_historyLabel(item)),
                    ),
                  ),
                ),
              const SizedBox(height: 96),
            ],
          ),
        );
      },
    );
  }

  static String _dueLabel(Responsibility item) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
    final days = due.difference(today).inDays;
    if (days < 0) return 'Scaduta da ${days.abs()} giorni';
    if (days == 0) return 'Scade oggi';
    if (days == 1) return 'Scade domani';
    return 'Scade tra $days giorni';
  }

  static String _historyLabel(Responsibility item) {
    if (item.lastCompletedAt != null) {
      return 'Ultima operazione: ${DateFormat('dd/MM/yyyy').format(item.lastCompletedAt!)}'
          '${item.lastPaidAmount == null ? '' : ' · € ${item.lastPaidAmount!.toStringAsFixed(2)}'}';
    }
    final label = switch (item.status) {
      ResponsibilityStatus.completed => 'Completata',
      ResponsibilityStatus.dismissed => 'Non più necessaria',
      ResponsibilityStatus.renewed => 'Rinnovata',
      ResponsibilityStatus.pending => 'Attiva',
    };
    return '$label · ${DateFormat('dd/MM/yyyy').format(item.dueDate)}';
  }

  static IconData _iconFor(LifeObjectType type) {
    return switch (type) {
      LifeObjectType.home => Icons.home_outlined,
      LifeObjectType.vehicle => Icons.directions_car_outlined,
      LifeObjectType.person => Icons.person_outline,
      LifeObjectType.pet => Icons.pets_outlined,
      LifeObjectType.subscription => Icons.autorenew,
      LifeObjectType.other => Icons.inventory_2_outlined,
    };
  }
}
