import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/partner_service.dart';

class ManageBarbersScreen extends StatefulWidget {
  const ManageBarbersScreen({super.key});

  @override
  State<ManageBarbersScreen> createState() => _ManageBarbersScreenState();
}

class _ManageBarbersScreenState extends State<ManageBarbersScreen> {
  final PartnerService _partnerService = PartnerService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> _allWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _currentPartnerId => _partnerService.currentUid;
  String get _currentPhone => _partnerService.currentPhone;

  void _showAddOrEditBarberDialog({
    Map<String, dynamic>? barber,
    int? index,
    required List<Map<String, dynamic>> currentList,
    required String docId,
  }) {
    final isEditing = barber != null;
    final nameController = TextEditingController(text: isEditing ? barber['name'] : '');
    bool isAvailable = isEditing ? (barber['isAvailable'] ?? true) : true;

    // Default to all 7 days if not previously configured
    List<String> selectedDays = isEditing
        ? List<String>.from(barber['workingDays'] ?? _allWeekdays)
        : List<String>.from(_allWeekdays);

    // Leave / Holiday Dates
    List<String> leaveDates = isEditing
        ? List<String>.from(barber['leaveDates'] ?? [])
        : [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF262626)),
          ),
          title: Text(
            isEditing ? 'Edit Staff & Leave Calendar' : 'Add New Staff & Schedule',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Barber Name', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    autofocus: !isEditing,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Rahul, Suresh, Vikram...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF262626))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00FF00))),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 1. Weekly Working Days Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Weekly Working Days', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        '${selectedDays.length}/7 Days',
                        style: const TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap days when this barber is on duty:',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 10),

                  // 7 Day Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allWeekdays.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            if (isSelected) {
                              if (selectedDays.length > 1) {
                                selectedDays.remove(day);
                              }
                            } else {
                              selectedDays.add(day);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF00FF00) : const Color(0xFF333333),
                            ),
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF262626)),
                  const SizedBox(height: 12),

                  // 2. Specific Future Leave Dates Calendar Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Planned Leave Dates', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF00FF00),
                                    onPrimary: Colors.black,
                                    surface: Color(0xFF1A1A1A),
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            final isoStr = DateFormat('yyyy-MM-dd').format(picked);
                            if (!leaveDates.contains(isoStr)) {
                              setDialogState(() {
                                leaveDates.add(isoStr);
                                leaveDates.sort();
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00FF00), size: 16),
                        label: const Text('+ Add Leave Date', style: TextStyle(color: Color(0xFF00FF00), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Text(
                    'Select specific future dates when this barber is not available (e.g. 15th of next month):',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),

                  if (leaveDates.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('No specific leaves planned. Available on regular working days.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: leaveDates.map((iso) {
                        DateTime? dt;
                        try {
                          dt = DateTime.parse(iso);
                        } catch (_) {}
                        final display = dt != null ? DateFormat('dd MMM yyyy').format(dt) : iso;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF331616),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy, color: Color(0xFFEF4444), size: 12),
                              const SizedBox(width: 6),
                              Text(display, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => setDialogState(() => leaveDates.remove(iso)),
                                child: const Icon(Icons.close, color: Colors.white70, size: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF262626)),
                  const SizedBox(height: 10),

                  // 3. Daily Available Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Available Today', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('Daily quick on-duty switch', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                        Switch(
                          value: isAvailable,
                          activeColor: const Color(0xFF00FF00),
                          onChanged: (val) => setDialogState(() => isAvailable = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final updatedList = List<Map<String, dynamic>>.from(currentList);
                final offDays = _allWeekdays.where((d) => !selectedDays.contains(d)).toList();

                if (isEditing && index != null) {
                  updatedList[index] = {
                    ...barber,
                    'name': name,
                    'isAvailable': isAvailable,
                    'workingDays': selectedDays,
                    'offDays': offDays,
                    'leaveDates': leaveDates,
                  };
                } else {
                  updatedList.add({
                    'id': 'barber_${DateTime.now().millisecondsSinceEpoch}',
                    'name': name,
                    'isAvailable': isAvailable,
                    'workingDays': selectedDays,
                    'offDays': offDays,
                    'leaveDates': leaveDates,
                    'rating': 5.0,
                  });
                }

                await _partnerService.updateSalonBarbers(docId, updatedList);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF00),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isEditing ? 'Save Changes' : 'Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBarber(int index, List<Map<String, dynamic>> currentList, String docId) async {
    final updatedList = List<Map<String, dynamic>>.from(currentList);
    updatedList.removeAt(index);
    await _partnerService.updateSalonBarbers(docId, updatedList);
  }

  void _toggleAvailability(int index, List<Map<String, dynamic>> currentList, String docId, bool currentVal) async {
    final updatedList = List<Map<String, dynamic>>.from(currentList);
    updatedList[index]['isAvailable'] = !currentVal;
    await _partnerService.updateSalonBarbers(docId, updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final cleanPhone = _currentPhone.replaceAll(RegExp(r'\D'), '');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Barbers & Staff',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('partners').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF00)));
          }

          final docs = snapshot.data!.docs;
          DocumentSnapshot<Map<String, dynamic>>? partnerDoc;

          for (var d in docs) {
            final data = d.data();
            final phone = (data['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
            if (d.id == _currentPartnerId || d.id == 'partner_$cleanPhone' || (cleanPhone.isNotEmpty && phone.contains(cleanPhone))) {
              partnerDoc = d;
              break;
            }
          }

          partnerDoc ??= docs.isNotEmpty ? docs.first : null;

          if (partnerDoc == null) {
            return const Center(
              child: Text('Salon profile not found', style: TextStyle(color: Colors.white54)),
            );
          }

          final salonData = partnerDoc.data() ?? {};
          final docId = partnerDoc.id;
          final rawBarbers = salonData['barbers'] as List<dynamic>?;
          final List<Map<String, dynamic>> barbers = (rawBarbers != null && rawBarbers.isNotEmpty)
              ? rawBarbers.map((b) => Map<String, dynamic>.from(b as Map)).toList()
              : [];

          final availableCount = barbers.where((b) => b['isAvailable'] == true).length;

          return Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Staff & Schedules', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            '$availableCount of ${barbers.length} Barbers Available Today',
                            style: const TextStyle(color: Color(0xFF00FF00), fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddOrEditBarberDialog(currentList: barbers, docId: docId),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Staff'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Salon Staff & Schedules',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: barbers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline_rounded, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              const Text('No Barbers Added Yet', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Add staff and configure their weekly schedules & planned leaves.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _showAddOrEditBarberDialog(currentList: barbers, docId: docId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00FF00),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Add First Staff Member'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: barbers.length,
                          itemBuilder: (context, index) {
                            final b = barbers[index];
                            final name = (b['name'] ?? 'Barber').toString();
                            final isAvailable = (b['isAvailable'] ?? true) as bool;
                            final rawWorkingDays = b['workingDays'] as List<dynamic>?;
                            final workingDays = rawWorkingDays != null
                                ? rawWorkingDays.map((e) => e.toString()).toList()
                                : _allWeekdays;
                            final rawOffDays = b['offDays'] as List<dynamic>?;
                            final offDays = rawOffDays != null
                                ? rawOffDays.map((e) => e.toString()).toList()
                                : _allWeekdays.where((d) => !workingDays.contains(d)).toList();

                            final rawLeaveDates = b['leaveDates'] as List<dynamic>?;
                            final leaveDatesCount = rawLeaveDates?.length ?? 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAvailable ? const Color(0xFF00FF00).withOpacity(0.3) : const Color(0xFF262626),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isAvailable ? const Color(0xFF00FF00).withOpacity(0.15) : const Color(0xFF1E1E1E),
                                      border: Border.all(color: isAvailable ? const Color(0xFF00FF00) : const Color(0xFF333333)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'B',
                                      style: TextStyle(
                                        color: isAvailable ? const Color(0xFF00FF00) : Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAvailable ? const Color(0xFF162B16) : const Color(0xFF222222),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: isAvailable ? const Color(0xFF00FF00).withOpacity(0.3) : const Color(0xFF333333)),
                                              ),
                                              child: Text(
                                                isAvailable ? 'AVAILABLE' : 'ON LEAVE',
                                                style: TextStyle(
                                                  color: isAvailable ? const Color(0xFF00FF00) : Colors.white38,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          workingDays.length == 7
                                              ? 'Schedule: All 7 Days'
                                              : 'Works: ${workingDays.join(", ")}${offDays.isNotEmpty ? " • Off: ${offDays.join(", ")}" : ""}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        if (leaveDatesCount > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '📅 $leaveDatesCount planned leave date(s)',
                                              style: const TextStyle(color: Color(0xFFFF9900), fontSize: 10, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  IconButton(
                                    icon: Icon(
                                      isAvailable ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                      color: isAvailable ? const Color(0xFF00FF00) : Colors.white38,
                                      size: 32,
                                    ),
                                    onPressed: () => _toggleAvailability(index, barbers, docId, isAvailable),
                                    tooltip: 'Toggle Availability',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_calendar_outlined, color: Color(0xFF00FF00), size: 20),
                                    onPressed: () => _showAddOrEditBarberDialog(
                                      barber: b,
                                      index: index,
                                      currentList: barbers,
                                      docId: docId,
                                    ),
                                    tooltip: 'Edit Schedule & Leaves',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                    onPressed: () => _deleteBarber(index, barbers, docId),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
