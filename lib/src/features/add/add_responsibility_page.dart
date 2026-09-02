import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/life_object.dart';
import '../../domain/responsibility.dart';
import '../../state/app_controller.dart';

class AddResponsibilityPage extends StatefulWidget {
  const AddResponsibilityPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AddResponsibilityPage> createState() => _AddResponsibilityPageState();
}

class _AddResponsibilityPageState extends State<AddResponsibilityPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _lifeObjectId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  RecurrenceUnit _recurrenceUnit = RecurrenceUnit.none;
  int _recurrenceInterval = 1;

  @override
  void initState() {
    super.initState();
    _lifeObjectId = widget.controller.objects.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _dueDate = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final normalizedAmount = _amountController.text.trim().replaceAll(',', '.');
    await widget.controller.addResponsibility(
      lifeObjectId: _lifeObjectId,
      title: _titleController.text,
      dueDate: _dueDate,
      expectedAmount:
          normalizedAmount.isEmpty ? null : double.tryParse(normalizedAmount),
      notes: _notesController.text,
      recurrenceUnit: _recurrenceUnit,
      recurrenceInterval: _recurrenceInterval,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi scadenza')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _lifeObjectId,
              decoration: const InputDecoration(
                labelText: 'Per cosa?',
                border: OutlineInputBorder(),
              ),
              items: widget.controller.objects
                  .map(
                    (object) => DropdownMenuItem(
                      value: object.id,
                      child: Text(object.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _lifeObjectId = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Scadenza',
                hintText: 'Es. Assicurazione, TARI, Revisione',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Inserisci una descrizione'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data di scadenza'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Importo previsto (opzionale)',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceUnit>(
              initialValue: _recurrenceUnit,
              decoration: const InputDecoration(
                labelText: 'Ricorrenza',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceUnit.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_recurrenceLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _recurrenceUnit = value!),
            ),
            if (_recurrenceUnit != RecurrenceUnit.none) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: '1',
                decoration: const InputDecoration(
                  labelText: 'Ogni',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _recurrenceInterval = int.tryParse(value) ?? 1,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 1) return 'Inserisci almeno 1';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Note (opzionali)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('SALVA'),
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceLabel(RecurrenceUnit unit) {
    return switch (unit) {
      RecurrenceUnit.none => 'Nessuna',
      RecurrenceUnit.days => 'Giorni',
      RecurrenceUnit.weeks => 'Settimane',
      RecurrenceUnit.months => 'Mesi',
      RecurrenceUnit.years => 'Anni',
    };
  }
}
