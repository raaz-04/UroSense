import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'edit_patient_screen.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'patient_history_screen.dart';
import '../services/device_logger.dart';
import 'package:intl/intl.dart';

enum TimeRangeOption {
  last30Min,
  last1Hour,
  last6Hours,
  allTime,
}

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  String selectedDuration = '1h';
  TextEditingController _bagVolumeController = TextEditingController();
  String patientName = 'Patient';
  String? deviceSerial;
  double? bagCapacity;
  double bagVolume = 1000;

  Duration getDuration() {
    switch (selectedDuration) {
      case '30m':
        return const Duration(minutes: 30);
      case '1h':
        return const Duration(hours: 1);
      case '2h':
        return const Duration(hours: 2);
      case '3h':
        return const Duration(hours: 3);
      case '6h':
        return const Duration(hours: 6);
      case '24h':
        return const Duration(hours: 24);
      default:
        return const Duration(hours: 1);
    }
  }

  TimeRangeOption _selectedRange = TimeRangeOption.last1Hour;

  Duration getDurationFromOption(TimeRangeOption option) {
    switch (option) {
      case TimeRangeOption.last30Min:
        return Duration(minutes: 30);
      case TimeRangeOption.last1Hour:
        return Duration(hours: 1);
      case TimeRangeOption.last6Hours:
        return Duration(hours: 6);
      case TimeRangeOption.allTime:
        return Duration(days: 3650); // Large duration for 'All time'
    }
  }

  void handleColorAlert({
    required String patientId,
    required String patientName,
    required String colorType,
    required String message,
  }) async {
    final alertsRef = FirebaseFirestore.instance.collection('alerts');
    final now = DateTime.now();

    await alertsRef.add({
      'type': colorType,
      'message': message,
      'time': now,
      'patientId': patientId,
      'patientName': patientName,
    });
  }
  void checkForAbnormalColor(Map<String, dynamic> data) {
    final String colorType = data['color'] ?? 'color_normal';

    if (colorType != 'color_normal') {
      String message;
      switch (colorType) {
        case 'color_blood':
          message = "Possible blood detected in urine.";
          break;
        case 'color_bilirubin':
          message = "Bilirubin color detected.";
          break;
        default:
          message = "Unusual urine color detected.";
      }

      handleColorAlert(
        patientId: widget.patientId,
        patientName: patientName,
        colorType: colorType,
        message: message,
      );
    }
  }


  void initState() {
    super.initState();
    _initDeviceLogging();

  }

  Future<void> _initDeviceLogging() async {
    final doc = await FirebaseFirestore.instance.collection('patients').doc(widget.patientId).get();
    final data = doc.data();
    if (data != null && data['deviceSerial'] != null && data['bagCapacity'] != null) {
      deviceSerial = data['deviceSerial'];
      bagCapacity = (data['bagCapacity'] as num).toDouble();
      DeviceLoggerService.startMonitoring(deviceSerial!, widget.patientId, bagCapacity!);
    }
  }

  @override
  void dispose() {
    if (deviceSerial != null) {
      DeviceLoggerService.stopMonitoring(deviceSerial!);
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final patientRef = FirebaseFirestore.instance.collection('patients').doc(widget.patientId);

    return Scaffold(
      appBar: AppBar(title: const Text("Patient Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: patientRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final deviceSerial = data['deviceSerial'];
          patientName = data['name'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text("Name: ${data['name']}"),
                subtitle: Text("Device: $deviceSerial"),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(
                      data['r'] ?? 200,
                      data['g'] ?? 200,
                      data['b'] ?? 100,
                      1,
                    ),
                  ),
                ),
              ),

              ListTile(
                title: const Text("Set Catheter Bag Volume (mL)"),
                subtitle: TextField(
                  controller: _bagVolumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Enter e.g. 1000"),
                  onSubmitted: (val) async {
                    if (val.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('devices')
                          .doc(deviceSerial)
                          .update({
                        'totalCapacity': int.parse(val),
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bag volume updated")),
                      );
                    }
                  },
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: ['30m', '1h', '2h', '3h', '6h', '24h'].map((label) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selectedDuration == label,
                        onSelected: (_) {
                          setState(() {
                            selectedDuration = label;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Urine Output", style: TextStyle(fontSize: 18)),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButton<TimeRangeOption>(
                  value: _selectedRange,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRange = value;
                      });
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: TimeRangeOption.last30Min,
                      child: Text("Last 30 min"),
                    ),
                    DropdownMenuItem(
                      value: TimeRangeOption.last1Hour,
                      child: Text("Last 1 hour"),
                    ),
                    DropdownMenuItem(
                      value: TimeRangeOption.last6Hours,
                      child: Text("Last 6 hours"),
                    ),
                    DropdownMenuItem(
                      value: TimeRangeOption.allTime,
                      child: Text("All time"),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('devices')
                      .doc(deviceSerial)
                      .collection('volumeReadings')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No data yet."));
                    }

                    final now = DateTime.now();
                    final cutoff = now.subtract(getDurationFromOption(_selectedRange));

                    final docs = _selectedRange == TimeRangeOption.allTime
                        ? snapshot.data!.docs.toList()
                        : snapshot.data!.docs.where((doc) {
                      final ts = (doc['timestamp'] as Timestamp).toDate();
                      return ts.isAfter(cutoff);
                    }).toList();

                    if (docs.isEmpty) {
                      return const Center(child: Text("No data in this time range."));
                    }

                    final spots = <FlSpot>[];
                    const lowThreshold = 25.0;
                    const highThreshold = 300.0;

                    for (var doc in docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      final volume = (d['volume'] ?? 0).toDouble();
                      final time = (d['timestamp'] as Timestamp)
                          .toDate()
                          .millisecondsSinceEpoch
                          .toDouble();
                      spots.add(FlSpot(time, volume));

                      checkForAbnormalColor(d);
                    }

                    spots.sort((a, b) => a.x.compareTo(b.x));

                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            verticalInterval: 5 * 60000,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 60000, // 1 minute = 60,000 ms
                                getTitlesWidget: (value, meta) {
                                  final time = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                  final formattedTime = DateFormat('HH:mm').format(time); // e.g. 21:45
                                  return Text(formattedTime, style: TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5, // 10 mL per tick
                                getTitlesWidget: (value, meta) {
                                  return Text("${value.toInt()} ", style: TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                            minX: spots.first.x,
                            maxX: spots.last.x,
                            minY: 0,
                            maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 20,
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Colors.black87,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final time = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                    final formatted = DateFormat('HH:mm').format(time);
                                    return LineTooltipItem(
                                      "$formatted\n${spot.y.toStringAsFixed(1)} mL",
                                      const TextStyle(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 2,
                              color: Colors.blue,
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color.fromRGBO(33, 150, 243, 0.2),
                              ),
                              dotData: FlDotData(show: false),
                            )
                          ],
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: lowThreshold,
                                color: Colors.orange,
                                strokeWidth: 1,
                                dashArray: [5, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topLeft,
                                  labelResolver: (_) => 'LOW',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ),
                              HorizontalLine(
                                y: highThreshold,
                                color: Colors.red,
                                strokeWidth: 1,
                                dashArray: [5, 5],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  labelResolver: (_) => 'HIGH',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Info"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPatientScreen(patientId: widget.patientId),
                      ),
                    );
                  },
                ),
              ),

              // 📜 View History Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Tare / Reset Bag"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('devices')
                        .doc(deviceSerial)
                        .update({
                      'tareTimestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Device tared – bag reset")),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Discharge Patient"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Discharge"),
                        content: const Text("Are you sure you want to discharge this patient?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('patients')
                          .doc(widget.patientId)
                          .update({
                        'status': 'discharged',
                        'dischargedTime': FieldValue.serverTimestamp(),
                      });

                      final patientDoc = await FirebaseFirestore.instance
                          .collection('patients')
                          .doc(widget.patientId)
                          .get();

                      final deviceSerial =
                      (patientDoc.data()?['deviceSerial'] ?? '') as String;

                      if (deviceSerial.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('devices')
                            .doc(deviceSerial)
                            .update({'assigned': false});
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Patient discharged successfully."),
                          backgroundColor: Colors.green,
                        ));
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
