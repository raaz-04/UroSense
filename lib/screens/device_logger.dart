import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceLoggerService {
  static final Map<String, StreamSubscription> _subscriptions = {};
  static final Map<String, List<Map<String, dynamic>>> _hourlyLogs = {};

  static void startMonitoring(String deviceSerial, String patientId, double bagCapacity) {
    if (_subscriptions.containsKey(deviceSerial)) return;

    final deviceRef = FirebaseFirestore.instance.collection('devices').doc(deviceSerial);
    final dataRef = deviceRef.collection('data');

    _subscriptions[deviceSerial] = dataRef.orderBy('timestamp', descending: true).limit(1).snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final latest = snapshot.docs.first.data();
      final timestamp = (latest['timestamp'] as Timestamp).toDate();
      final volume = (latest['volume'] ?? 0).toDouble();
      final r = latest['r'] ?? 0;
      final g = latest['g'] ?? 0;
      final b = latest['b'] ?? 0;

      _logHourlyOutput(deviceSerial, patientId, volume, timestamp);
      _checkVolumeAlert(deviceSerial, patientId, volume, bagCapacity);
      _checkColorAlert(deviceSerial, patientId, r, g, b, timestamp);
    });
  }

  static void _logHourlyOutput(String deviceSerial, String patientId, double volume, DateTime timestamp) {
    final hourKey = "${timestamp.year}-${timestamp.month}-${timestamp.day}-${timestamp.hour}";
    _hourlyLogs.putIfAbsent(deviceSerial, () => []);

    final existing = _hourlyLogs[deviceSerial]!.where((e) => e['key'] == hourKey).toList();
    if (existing.isEmpty) {
      _hourlyLogs[deviceSerial]!.add({
        'key': hourKey,
        'timestamp': timestamp,
        'volume': volume,
      });

      FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('history')
          .add({
        'volume': volume,
        'timestamp': Timestamp.fromDate(timestamp),
        'deviceSerial': deviceSerial,
      });
    }
  }

  static void _checkVolumeAlert(String deviceSerial, String patientId, double volume, double capacity) async {
    final threshold = 0.8 * capacity;
    final alreadySent = await _wasAlertSent(patientId, 'high_volume');

    if (volume >= threshold && !alreadySent) {
      await FirebaseFirestore.instance.collection('alerts').add({
        'type': 'high_volume',
        'patientId': patientId,
        'patientName': await _getPatientName(patientId),
        'message': 'Urine output is above 80% of bag capacity.',
        'deviceSerial': deviceSerial,
        'time': Timestamp.now(),
      });
    }
  }

  static void _checkColorAlert(String deviceSerial, String patientId, int r, int g, int b, DateTime timestamp) async {
    String? type;
    if (r > 180 && g < 80 && b < 80) {
      type = 'color_blood';
    } else if (r > 180 && g > 180 && b < 100) {
      type = 'color_bilirubin';
    } else if (b > 180 && r < 100 && g < 100) {
      type = 'color_abnormal';
    }

    if (type != null) {
      final alreadySent = await _wasAlertSent(patientId, type);
      if (!alreadySent) {
        await FirebaseFirestore.instance.collection('alerts').add({
          'type': type,
          'patientId': patientId,
          'patientName': await _getPatientName(patientId),
          'message': 'Abnormal urine color detected',
          'deviceSerial': deviceSerial,
          'time': Timestamp.fromDate(timestamp),
        });
      }
    }
  }

  static Future<String> _getPatientName(String patientId) async {
    final doc = await FirebaseFirestore.instance.collection('patients').doc(patientId).get();
    return doc.data()?['name'] ?? 'Unknown';
  }

  static Future<bool> _wasAlertSent(String patientId, String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('alerts')
        .where('patientId', isEqualTo: patientId)
        .where('type', isEqualTo: type)
        .orderBy('time', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    final lastTime = (snapshot.docs.first['time'] as Timestamp).toDate();
    final diff = DateTime.now().difference(lastTime);
    return diff.inMinutes < 15; // Throttle: 1 alert every 15 mins
  }

  static void stopMonitoring(String deviceSerial) {
    _subscriptions[deviceSerial]?.cancel();
    _subscriptions.remove(deviceSerial);
    _hourlyLogs.remove(deviceSerial);
  }

  static void stopAll() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _hourlyLogs.clear();
  }
}
