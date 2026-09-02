import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/local_store.dart';
import 'src/state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(LocalStore());
  await controller.load();
  runApp(LifeAdminApp(controller: controller));
}
