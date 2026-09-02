import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'state/app_controller.dart';

class LifeAdminApp extends StatelessWidget {
  const LifeAdminApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeAdmin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: HomePage(controller: controller),
    );
  }
}
