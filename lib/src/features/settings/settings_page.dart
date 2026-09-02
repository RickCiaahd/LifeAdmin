import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  static const _options = <int>[30, 14, 7, 3, 1, 0];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Impostazioni')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Promemoria scadenze',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Scegli quando LifeAdmin deve ricordarti una scadenza. Le notifiche vengono inviate alle 09:00.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: _options
                    .map(
                      (days) => SwitchListTile(
                        value: controller.reminderDays.contains(days),
                        title: Text(_label(days)),
                        onChanged: (value) =>
                            controller.setReminderEnabled(days, value),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.resetReminderDefaults,
              icon: const Icon(Icons.restore),
              label: const Text('Ripristina predefiniti'),
            ),
            const SizedBox(height: 24),
            Text(
              'Diagnostica',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Invia notifica di test'),
                subtitle: const Text('Verifica permessi e ricezione notifiche'),
                onTap: () async {
                  await controller.sendTestNotification();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifica di test inviata.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(int days) {
    if (days == 0) return 'Il giorno della scadenza';
    if (days == 1) return '1 giorno prima';
    return '$days giorni prima';
  }
}
