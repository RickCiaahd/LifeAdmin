import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/life_object.dart';
import '../../domain/responsibility.dart';
import '../../state/app_controller.dart';
import '../add/add_life_object_page.dart';
import '../add/add_responsibility_page.dart';
import '../object/life_object_detail_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pending = controller.responsibilities
            .where((item) => item.status == ResponsibilityStatus.pending)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final overdueCount = pending.where((item) => item.isOverdue).length;
        final now = DateTime.now();
        final dueThisMonth = controller.dueThisMonth(now);
        final expectedThisMonth = controller.expectedAmountForMonth(now);

        return Scaffold(
          appBar: AppBar(
            title: const Text('LifeAdmin'),
            actions: [
              IconButton(
                tooltip: 'Impostazioni',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(controller: controller),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddMenu(context),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                overdueCount > 0
                    ? '$overdueCount ${overdueCount == 1 ? 'cosa richiede' : 'cose richiedono'} attenzione'
                    : 'Tutto sotto controllo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${pending.length} scadenze attive',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Questo mese',
                          value: '$dueThisMonth',
                          caption: 'scadenze',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'Previsti',
                          value: expectedThisMonth == 0
                              ? '—'
                              : '€ ${expectedThisMonth.toStringAsFixed(2)}',
                          caption: 'importi inseriti',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Non hai scadenze attive. Aggiungine una dal pulsante in basso.',
                    ),
                  ),
                )
              else
                ...pending.map((item) {
                  final owner = controller.objects.firstWhere(
                    (object) => object.id == item.lifeObjectId,
                    orElse: () => const LifeObject(
                      id: 'unknown',
                      name: 'Altro',
                      type: LifeObjectType.other,
                    ),
                  );
                  return _ResponsibilityCard(
                    item: item,
                    owner: owner,
                    onComplete: () => _complete(context, item),
                    onDismiss: () => controller.dismissResponsibility(item),
                    onEdit: () => _editResponsibility(context, item),
                  );
                }),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Le tue cose',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addObject(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...controller.objects.map((object) {
                final count = controller.responsibilities
                    .where(
                      (item) =>
                          item.lifeObjectId == object.id &&
                          item.status == ResponsibilityStatus.pending,
                    )
                    .length;
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LifeObjectDetailPage(
                          controller: controller,
                          object: object,
                        ),
                      ),
                    ),
                    leading: Icon(_iconFor(object.type)),
                    title: Text(object.name),
                    subtitle: object.details == null
                        ? Text('$count scadenze attive')
                        : Text('${object.details} · $count scadenze attive'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              }),
              const SizedBox(height: 96),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Nuova scadenza'),
                subtitle: const Text('Pagamento, rinnovo o manutenzione'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addResponsibility(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Nuova cosa'),
                subtitle: const Text('Auto, casa, persona, animale o altro'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addObject(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addObject(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddLifeObjectPage(controller: controller),
      ),
    );
  }

  Future<void> _addResponsibility(BuildContext context) async {
    if (controller.objects.isEmpty) {
      await _addObject(context);
      if (controller.objects.isEmpty || !context.mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddResponsibilityPage(controller: controller),
      ),
    );
  }

  Future<void> _editResponsibility(
    BuildContext context,
    Responsibility item,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddResponsibilityPage(
          controller: controller,
          initialResponsibility: item,
        ),
      ),
    );
  }

  Future<void> _complete(
    BuildContext context,
    Responsibility item,
  ) async {
    final amountController = TextEditingController(
      text: item.expectedAmount?.toStringAsFixed(2).replaceAll('.', ','),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.isRecurring ? 'Rinnova ${item.title}' : 'Completa ${item.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.isRecurring
                  ? 'La prossima scadenza verrà calcolata automaticamente.'
                  : 'La scadenza verrà segnata come completata.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo pagato (opzionale)',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(item.isRecurring ? 'RINNOVATA' : 'COMPLETATA'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final raw = amountController.text.trim().replaceAll(',', '.');
      await controller.completeResponsibility(
        item,
        paidAmount: raw.isEmpty ? null : double.tryParse(raw),
      );
    }
    amountController.dispose();
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ResponsibilityCard extends StatelessWidget {
  const _ResponsibilityCard({
    required this.item,
    required this.owner,
    required this.onComplete,
    required this.onDismiss,
    required this.onEdit,
  });

  final Responsibility item;
  final LifeObject owner;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
    final days = due.difference(today).inDays;
    final label = days < 0
        ? 'Scaduta da ${days.abs()} ${days.abs() == 1 ? 'giorno' : 'giorni'}'
        : days == 0
            ? 'Scade oggi'
            : days == 1
                ? 'Scade domani'
                : 'Scade tra $days giorni';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    owner.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Modifica',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                if (item.isRecurring)
                  const Tooltip(
                    message: 'Ricorrente',
                    child: Icon(Icons.autorenew, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('$label · ${DateFormat('dd/MM/yyyy').format(item.dueDate)}'),
            if (item.expectedAmount != null) ...[
              const SizedBox(height: 4),
              Text('€ ${item.expectedAmount!.toStringAsFixed(2)}'),
            ],
            if (item.notes != null) ...[
              const SizedBox(height: 4),
              Text(item.notes!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (item.lastCompletedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ultima volta: ${DateFormat('dd/MM/yyyy').format(item.lastCompletedAt!)}'
                '${item.lastPaidAmount == null ? '' : ' · € ${item.lastPaidAmount!.toStringAsFixed(2)}'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('NON PIÙ NECESSARIA'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onComplete,
                  child: Text(item.isRecurring ? 'RINNOVATA' : 'COMPLETATA'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
