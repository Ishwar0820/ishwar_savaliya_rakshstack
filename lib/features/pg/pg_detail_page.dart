// lib/features/pg/pg_detail_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../admin/admin_models.dart';
import 'schedule_visit_page.dart';

class PgDetailPage extends StatefulWidget {
  final AdminPg pg;
  const PgDetailPage({super.key, required this.pg});

  @override
  State<PgDetailPage> createState() => _PgDetailPageState();
}

class _PgDetailPageState extends State<PgDetailPage> {
  final PageController _pageCtrl = PageController();
  int _imgIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    if (widget.pg.images.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_imgIndex + 1) % widget.pg.images.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share coming soon')),
    );
  }

  void _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.pg;

    const kBlue = Color(0xFF007AFF);
    const kTagBg = Color(0xFFEAF6EF);

    final priceChips = <String>[
      'x2  ₹${d.price2x}',
      'x3  ₹${d.price3x}',
      'x4  ₹${d.price4x}',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(d.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Images
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                          itemCount: d.images.length,
                          itemBuilder: (_, i) {
                            final src = d.images[i];
                            final isNetwork = src.startsWith('http');
                            return isNetwork
                                ? Image.network(src, fit: BoxFit.cover)
                                : Image.asset(src, fit: BoxFit.cover);
                          },
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: kTagBg, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: const [
                              Icon(Icons.person_outline, size: 18, color: kBlue),
                              SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ),
                      // dots
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(d.images.length, (i) {
                            final active = i == _imgIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 18 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active ? Colors.white : Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Name + Directions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(d.area, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Open maps coming soon')),
                        );
                      },
                      icon: const Icon(Icons.near_me_outlined, size: 18, color: Colors.white),
                      label: const Text('Directions', style: TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF537FF4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Full Address
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(d.address.isNotEmpty ? d.address : '${d.area}, ${d.city}'),
              ),
            ),

            // Pricing
            _SectionTitle('Pricing'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: priceChips.map((raw) => _PriceBadge(rawText: raw)).toList(),
                ),
              ),
            ),

            // Amenities
            _SectionTitle('Amenities'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: d.amenities.map((t) => _IconChip(text: t, icon: _iconForAmenity(t))).toList(),
                ),
              ),
            ),

            // Services
            _SectionTitle('Services'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: d.services.map((t) => _IconChip(text: t, icon: _iconForService(t))).toList(),
                ),
              ),
            ),

            // Electricity note
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF007AFF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.bolt_outlined, color: Color(0xFF007AFF)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Electricity charges will be applied separately based on individual usage.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _SectionTitle('Owner & Contact'),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3ECFF)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline),
                        title: const Text('PG Owner'),
                        subtitle: Text(
                          (d.ownerName.isNotEmpty ? d.ownerName : '—'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: (d.ownerName.isEmpty)
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copy(d.ownerName, 'Owner name'),
                        ),
                      ),
                      const Divider(height: 12),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.call_outlined),
                        title: const Text('Contact Number'),
                        subtitle: Text(
                          (d.ownerPhone.isNotEmpty ? d.ownerPhone : '—'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: (d.ownerPhone.isEmpty)
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copy(d.ownerPhone, 'Phone number'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ScheduleVisitPage(pg: widget.pg)),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF537FF4),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Schedule Visit'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String rawText;
  const _PriceBadge({required this.rawText});

  (String beds, String price) _parse() {
    final t = rawText.replaceAll('Starts from', '').trim();
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    String beds = 'x2';
    String price = t;
    for (final p in parts) {
      if (p.startsWith('x')) beds = p;
      if (p.contains('₹')) price = p;
    }
    return (beds, price);
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF007AFF);
    final (beds, price) = _parse();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3ECFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.bed_outlined, size: 20, color: blue),
            const SizedBox(width: 6),
            Text(
              beds,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Starts from',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _IconChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF007AFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: blue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForAmenity(String name) {
  final n = name.toLowerCase();
  if (n.contains('air')) return Icons.ac_unit_outlined;
  if (n.contains('washroom') || n.contains('bath')) return Icons.shower_outlined;
  if (n.contains('cupboard') || n.contains('wardrobe')) return Icons.inventory_2_outlined;
  if (n.contains('wifi') || n.contains('wi-fi')) return Icons.wifi_outlined;
  if (n.contains('gym')) return Icons.fitness_center_outlined;
  if (n.contains('cctv') || n.contains('security')) return Icons.videocam_outlined;
  if (n.contains('laundry')) return Icons.local_laundry_service_outlined;
  if (n.contains('meals') || n.contains('food')) return Icons.restaurant_outlined;
  return Icons.check_circle_outline;
}

IconData _iconForService(String name) {
  final n = name.toLowerCase();
  if (n.contains('meals') || n.contains('food')) return Icons.restaurant_outlined;
  if (n.contains('wifi')) return Icons.wifi_outlined;
  if (n.contains('laundry')) return Icons.local_laundry_service_outlined;
  if (n.contains('housekeeping') || n.contains('clean')) return Icons.cleaning_services_outlined;
  if (n.contains('security')) return Icons.shield_outlined;
  return Icons.checklist_rtl;
}
