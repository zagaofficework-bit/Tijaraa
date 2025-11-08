import 'package:flutter/material.dart';

class ReportUserScreen extends StatelessWidget {
  const ReportUserScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const ReportUserScreen(),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report User')),
      body: const Center(
        child: Text(
          'Report user functionality will appear here.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
