import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_logger.dart';

class DeviceMonitorService {
  static final DeviceMonitorService _instance = DeviceMonitorService._internal();
  factory DeviceMonitorService() => _instance;

  DeviceMonitorService._internal();

  final Set<String> _monitoredDevices = {};

  void startMonitoring(String deviceSerial, int bagVolume) {
    if (_monitoredDevices.contains(deviceSerial)) return;


  }
}
