import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHealthService {
  Future<Map<String, dynamic>> checkHealth() async {
    final start = DateTime.now();
    try {
      final docRef =
          FirebaseFirestore.instance.collection('_health').doc('ping');
      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'device': 'health_check',
      });

      final snapshot = await docRef.get();
      if (!snapshot.exists) throw Exception('Write failed');

      await docRef.delete();

      final end = DateTime.now();
      return {
        'status': 'healthy',
        'latencyMs': end.difference(start).inMilliseconds,
        'timestamp': end.toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
