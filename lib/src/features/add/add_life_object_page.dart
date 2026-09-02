import 'package:flutter/material.dart';

import '../../domain/life_object.dart';
import '../../state/app_controller.dart';

class AddLifeObjectPage extends StatefulWidget {
  const AddLifeObjectPage({
    super.key,
    required this.controller,
    this.initialObject,
  });

  final AppController controller;
  final LifeObject? initialObject;

  @override
  State<AddLifeObjectPage> createState() => _AddLifeObjectPageState();
}

class _AddLifeObjectPageState extends State<AddLifeObjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  LifeObjectType _type = LifeObjectType.home;

  bool get _isEditing => widget.initialObject != null;

  @override
  void initState() {
    super.initState();
    final object = widget.initialObject;
    if (object != null) {
      _nameController.text = object.name;
      _detailsController.text = object.details ?? '';
      _type = object.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isEditing) {
      await widget.controller.updateObject(
        widget.initialObject!,
        name: _nameController.text,
        type: _type,
        details: _detailsController.text,
      );
    } else {
      await widget.controller.addObject(
        name: _nameController.text,
        type: _type,
        details: _detailsController.text,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifica cosa' : 'Aggiungi cosa')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Es. Fiat Panda, Casa, Io',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Inserisci un nome'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LifeObjectType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: LifeObjectType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_labelFor(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Dettagli opzionali',
                hintText: 'Es. targa, indirizzo, descrizione',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'SALVA MODIFICHE' : 'SALVA'),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(LifeObjectType type) {
    return switch (type) {
      LifeObjectType.home => 'Casa',
      LifeObjectType.vehicle => 'Veicolo',
      LifeObjectType.person => 'Persona',
      LifeObjectType.pet => 'Animale',
      LifeObjectType.subscription => 'Abbonamento',
      LifeObjectType.other => 'Altro',
    };
  }
}
