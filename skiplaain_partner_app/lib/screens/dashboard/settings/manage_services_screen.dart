import 'package:flutter/material.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final List<Map<String, dynamic>> _services = [
    {'name': 'Haircut', 'duration': '30 mins', 'price': '₹150', 'active': true},
    {'name': 'Beard Trim & Style', 'duration': '20 mins', 'price': '₹100', 'active': true},
    {'name': 'Hair Color', 'duration': '60 mins', 'price': '₹400', 'active': true},
    {'name': 'Facial', 'duration': '45 mins', 'price': '₹500', 'active': false},
    {'name': 'Head Massage', 'duration': '20 mins', 'price': '₹120', 'active': true},
  ];

  void _showAddServiceDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding new service is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Manage Services'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServiceDialog,
        backgroundColor: const Color(0xFF00FF00),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service['duration']} • ${service['price']}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: service['active'],
                    onChanged: (val) {
                      setState(() {
                        service['active'] = val;
                      });
                    },
                    activeColor: Colors.black,
                    activeTrackColor: const Color(0xFF00FF00),
                    inactiveThumbColor: Colors.black,
                    inactiveTrackColor: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white54),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
