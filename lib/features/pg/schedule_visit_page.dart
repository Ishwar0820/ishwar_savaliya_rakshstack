// lib/features/pg/schedule_visit_page.dart
import 'package:flutter/material.dart';
import '../admin/admin_models.dart';
import 'pg_detail_page.dart';

class ScheduleVisitPage extends StatefulWidget {
  final AdminPg pg;
  const ScheduleVisitPage({super.key, required this.pg});

  @override
  State<ScheduleVisitPage> createState() => _ScheduleVisitPageState();
}

class _ScheduleVisitPageState extends State<ScheduleVisitPage> {
  final _nameCtrl = TextEditingController();
  DateTime? _date;
  String? _slot;
  bool _agreed = false;

  final List<String> _slots = const [
    '9 AM – 12 PM',
    '12 PM – 3 PM',
    '3 PM – 6 PM',
    '6 PM – 9 PM',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final yy = d.year % 100;
    return '${d.day} ${m[d.month]} \u2019$yy';
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty && _date != null && _slot != null && _agreed;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF537FF4),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  Widget _thumb(String src) {
    final isNet = src.startsWith('http');
    return isNet
        ? Image.network(src, fit: BoxFit.cover)
        : Image.asset(src, fit: BoxFit.cover);
  }

  void _showSuccessSheet() {
    final d = widget.pg;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Container(
                height: 66,
                width: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF2FF),
                ),
                child: const Icon(Icons.event_available, size: 34, color: Color(0xFF537FF4)),
              ),
              const SizedBox(height: 16),
              const Text(
                'In–person Visit Scheduled!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Our representative will get in touch with you soon',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3ECFF)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                      child: SizedBox(
                        width: 140,
                        height: 110,
                        child: (d.images.isNotEmpty)
                            ? _thumb(d.images.first)
                            : Container(color: const Color(0xFFEFEFEF)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(d.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, color: Colors.black87)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d.address.isNotEmpty ? d.address : '${d.area}, ${d.city}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Scheduled on  ', style: TextStyle(color: Colors.black54)),
                                Text(
                                  _date != null ? _fmtDate(_date!) : '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Slot Time       ', style: TextStyle(color: Colors.black54)),
                                Text(
                                  _slot ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PgDetailPage(pg: widget.pg),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF537FF4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const lightBlue = Color(0xFFEAF2FF);
    const primaryBlue = Color(0xFF537FF4);

    final d = widget.pg;

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Visit')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PG summary card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                      child: SizedBox(
                        width: 150,
                        height: 110,
                        child: (d.images.isNotEmpty)
                            ? _thumb(d.images.first)
                            : Container(color: const Color(0xFFEFEFEF)),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: lightBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                d.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                d.address.isNotEmpty ? d.address : '${d.area}, ${d.city}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text('Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: _fieldDecoration('Enter Name'),
              ),

              const SizedBox(height: 16),

              const Text('Select Date *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _fieldDecoration(null),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _date != null ? _fmtDate(_date!) : 'Select Date',
                          style: TextStyle(
                            color: _date != null ? Colors.black87 : Colors.black38,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text('Select Time *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _slot,
                items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _slot = v),
                decoration: _fieldDecoration('Select'),
              ),

              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      side: const BorderSide(color: primaryBlue, width: 2),
                      activeColor: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I have read and agreed to the terms and conditions and privacy policy and hereby confirm to proceed',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _showSuccessSheet : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF537FF4),
                    disabledBackgroundColor: const Color(0xFFBFD0FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Schedule Visit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF537FF4), width: 1.4),
      ),
    );
  }
}
