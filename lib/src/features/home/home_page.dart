import 'package:flutter/material.dart';

import '../../domain/life_object.dart';
import '../../domain/responsibility.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final _objects = <LifeObject>[
    const LifeObject(id: 'car', name: 'Auto', type: LifeObjectType.vehicle),
    const LifeObject(id: 'home', name: 'Casa', type: LifeObjectType.home),
    const LifeObject(id: 'me', name: 'Io', type: LifeObjectType.person),
  ];

  static final _responsibilities = <Responsibility>[
    Responsibility(
      id: 'insurance',
      lifeObjectId: 'car',
      title: 'Assicurazione',
      dueDate: DateTime.now().add(const Duration(days: 12)),
      expectedAmount: 463,
      recurrenceUnit: RecurrenceUnit.years,
    ),
    Responsibility(
      id: 'tari',
      lifeObjectId: 'home',
      title: 'TARI',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      expectedAmount: 126.40,
    ),
    Responsibility(
      id: 'id-card',
      lifeObjectId: 'me',
      title: "Carta d'identità",
      dueDate: DateTime.now().add(const Duration(days: 46)),
      recurrenceUnit: RecurrenceUnit.years,
      recurrenceInterval: 10,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = [..._responsibilities]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final overdueCount = pending.where((item) => item.isOverdue).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeAdmin'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            overdueCount > 0
                ? '$overdueCount cosa richiede attenzione'
                : 'Tutto sotto controllo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...pending.map((item) {
            final owner = _objects.firstWhere(
              (object) => object.id == item.lifeObjectId,
            );
            return _ResponsibilityCard(item: item, owner: owner);
          }),
          const SizedBox(height: 24),
          Text('Le tue cose', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._objects.map(
            (object) => Card(
              child: ListTile(
                leading: Icon(_iconFor(object.type)),
                title: Text(object.name),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
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

class _ResponsibilityCard extends StatelessWidget {
  const _ResponsibilityCard({required this.item, required this.owner});

  final Responsibility item;
  final LifeObject owner;

  @override
  Widget build(BuildContext context) {
    final days = item.dueDate.difference(DateTime.now()).inDays;
    final label = item.isOverdue
        ? 'Scaduta da ${days.abs()} giorni'
        : days == 0
            ? 'Scade oggi'
            : 'Scade tra $days giorni';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(owner.name, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(label),
            if (item.expectedAmount != null) ...[
              const SizedBox(height: 4),
              Text('€ ${item.expectedAmount!.toStringAsFixed(2)}'),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () {},
                child: Text(item.isOverdue ? 'RISOLVI' : 'GESTISCI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
