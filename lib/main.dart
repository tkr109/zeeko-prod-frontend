import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zeeko',
      routerConfig: AppRouter.router,
    );
  }
}
