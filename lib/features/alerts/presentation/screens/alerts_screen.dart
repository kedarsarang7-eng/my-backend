import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/alert_providers.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(activeAlertsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Alerts')),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts. Great job!'));
          }
          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(alert.message),
                  subtitle: Text(alert.createdAt.toString().split(' ')[0]),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
