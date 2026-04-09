import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final Map<String, Map<String, Map<String, dynamic>>> _schedule = {};
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restaurantId = authProvider.restaurantId;
    if (restaurantId == null) return;

    final doc = await _db.collection('schedules').doc(restaurantId).get();
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
        title: const Text('Schedule Management'),
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
    final daySchedule = _schedule[key] ?? {'isOpen': false, 'openTime': '', 'closeTime': ''};
    final isOpen = daySchedule['isOpen'] ?? false;
    final openTime = daySchedule['openTime'] ?? '';
    final closeTime = daySchedule['closeTime'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          isOpen ? Icons.check_circle : Icons.circle_outlined,
          color: isOpen ? Colors.green : Colors.grey,
        ),
        title: Text(displayName),
        subtitle: isOpen ? 'Open: $openTime - $closeTime' : 'Closed',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Open on this day'),
                  value: isOpen,
                  onChanged: (value) {
                    setState(() {
                      _schedule[key] = {
                        'isOpen': value,
                        'openTime': openTime,
                        'closeTime': closeTime,
                      };
                    });
                  },
                ),
                if (isOpen) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Opening Time'),
                    trailing: Text(openTime.isEmpty ? 'Not set' : openTime),
                    onTap: () => _selectTime(key, 'openTime'),
                  ),
                  ListTile(
                    title: const Text('Closing Time'),
                    trailing: Text(closeTime.isEmpty ? 'Not set' : closeTime),
                    onTap: () => _selectTime(key, 'closeTime'),
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
    final restaurantId = authProvider.restaurantId;
    if (restaurantId == null) return;

    await _db.collection('schedules').doc(restaurantId).set({
      'restaurantId': restaurantId,
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
