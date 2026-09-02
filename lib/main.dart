import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/local_store.dart';
import 'src/notifications/notification_service.dart';
import 'src/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService();
  await notifications.initialize();

  final controller = AppController(LocalStore(), notifications);
  await controller.load();

  runApp(LifeAdminApp(controller: controller));
}
