import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? todayStatus;

  @override
  void initState() {
    super.initState();
    _loadAttendance(); // load stored status when app starts
  }

  Future<void> _loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      todayStatus = prefs.getString("todayStatus");
    });
  }

  Future<void> markAttendance(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("todayStatus", status);
    setState(() {
      todayStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employee Attendance")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              todayStatus == null
                  ? "No attendance marked yet"
                  : "Today's Status: $todayStatus",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => markAttendance("Present"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Mark Present"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => markAttendance("Absent"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Mark Absent"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
