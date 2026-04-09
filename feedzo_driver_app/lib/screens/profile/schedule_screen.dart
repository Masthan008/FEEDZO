import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverScheduleScreen extends StatefulWidget {
  const DriverScheduleScreen({super.key});

  @override
  State<DriverScheduleScreen> createState() => _DriverScheduleScreenState();
}

class _DriverScheduleScreenState extends State<DriverScheduleScreen> {
  final Map<String, Map<String, dynamic>> _schedule = {};

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverId = authProvider.driverId;
    if (driverId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('schedules')
        .doc(driverId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        final schedule = data['schedule'] as Map<String, dynamic>?;
        if (schedule != null) {
          schedule.forEach((day, times) {
            _schedule[day] = times as Map<String, dynamic>;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSchedule,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDayCard('Monday', 'monday'),
          _buildDayCard('Tuesday', 'tuesday'),
          _buildDayCard('Wednesday', 'wednesday'),
          _buildDayCard('Thursday', 'thursday'),
          _buildDayCard('Friday', 'friday'),
          _buildDayCard('Saturday', 'saturday'),
          _buildDayCard('Sunday', 'sunday'),
        ],
      ),
    );
  }

  Widget _buildDayCard(String displayName, String key) {
    final daySchedule = _schedule[key] ?? {'isAvailable': false, 'startTime': '', 'endTime': ''};
    final isAvailable = daySchedule['isAvailable'] ?? false;
    final startTime = daySchedule['startTime'] ?? '';
    final endTime = daySchedule['endTime'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          isAvailable ? Icons.check_circle : Icons.circle_outlined,
          color: isAvailable ? Colors.green : Colors.grey,
        ),
        title: Text(displayName),
        subtitle: isAvailable ? 'Available: $startTime - $endTime' : 'Not available',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Available on this day'),
                  value: isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _schedule[key] = {
                        'isAvailable': value,
                        'startTime': startTime,
                        'endTime': endTime,
                      };
                    });
                  },
                ),
                if (isAvailable) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Start Time'),
                    trailing: Text(startTime.isEmpty ? 'Not set' : startTime),
                    onTap: () => _selectTime(key, 'startTime'),
                  ),
                  ListTile(
                    title: const Text('End Time'),
                    trailing: Text(endTime.isEmpty ? 'Not set' : endTime),
                    onTap: () => _selectTime(key, 'endTime'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(String day, String timeType) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        final currentSchedule = _schedule[day] ?? {};
        _schedule[day] = {
          ...currentSchedule,
          timeType: '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
        };
      });
    }
  }

  Future<void> _saveSchedule() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverId = authProvider.driverId;
    if (driverId == null) return;

    await FirebaseFirestore.instance.collection('schedules').doc(driverId).set({
      'driverId': driverId,
      'schedule': _schedule,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule saved successfully')),
      );
    }
  }
}
