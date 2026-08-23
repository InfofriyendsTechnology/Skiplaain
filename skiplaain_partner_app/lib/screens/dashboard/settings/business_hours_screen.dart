import 'package:flutter/material.dart';

class BusinessHoursScreen extends StatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  final List<Map<String, dynamic>> _days = [
    {'day': 'Monday', 'isOpen': true, 'openTime': '09:00 AM', 'closeTime': '09:00 PM'},
    {'day': 'Tuesday', 'isOpen': true, 'openTime': '09:00 AM', 'closeTime': '09:00 PM'},
    {'day': 'Wednesday', 'isOpen': true, 'openTime': '09:00 AM', 'closeTime': '09:00 PM'},
    {'day': 'Thursday', 'isOpen': true, 'openTime': '09:00 AM', 'closeTime': '09:00 PM'},
    {'day': 'Friday', 'isOpen': true, 'openTime': '09:00 AM', 'closeTime': '09:00 PM'},
    {'day': 'Saturday', 'isOpen': true, 'openTime': '09:00 AM', 'closeTime': '10:00 PM'},
    {'day': 'Sunday', 'isOpen': false, 'openTime': '10:00 AM', 'closeTime': '05:00 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Business Hours'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final dayData = _days[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dayData['day'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: dayData['isOpen'],
                              onChanged: (val) {
                                setState(() {
                                  dayData['isOpen'] = val;
                                });
                              },
                              activeColor: Colors.black,
                              activeTrackColor: const Color(0xFF00FF00),
                              inactiveThumbColor: Colors.black,
                              inactiveTrackColor: Colors.grey,
                            ),
                          ],
                        ),
                        if (dayData['isOpen']) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Color(0xFF2A2A2A)),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'Opens At',
                                  time: dayData['openTime'],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'Closes At',
                                  time: dayData['closeTime'],
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Business hours saved successfully')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({required String label, required String time}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.access_time, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
