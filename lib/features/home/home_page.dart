// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile/profile_view_page.dart';
import '../sort_filter/sort_by_page.dart';
import '../sort_filter/filter_page.dart';
import '../pg/pg_detail_page.dart';
import '../../data/pg_repository.dart';
import '../admin/admin_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color kPrimaryBlue = const Color(0xFF007AFF);

  static const List<String> kAmenityOptions = <String>[
    'Attached Washroom',
    'Spacious Cupboard',
    'Balcony',
    'Parking',
    'AC Room',
    'Study Table',
  ];

  static const List<String> kServiceOptions = <String>[
    'High-Speed WIFI',
    'Laundry Service',
    'Professional Housekeeping',
    '24x7 Security Surveillance',
    'Hot and Delicious Meals',
  ];

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Widget _buildAvatarFromData(Map<String, dynamic>? data) {
    final v = ((data?['avatar'] ?? data?['gender']) ?? '').toString().toLowerCase();
    if (v == 'male') {
      return const CircleAvatar(
        radius: 18,
        backgroundImage: AssetImage('Project_photos/user-avatar-male-5.png'),
        backgroundColor: Colors.transparent,
      );
    }
    if (v == 'female') {
      return const CircleAvatar(
        radius: 18,
        backgroundImage: AssetImage('Project_photos/user-avatar-female-6.png'),
        backgroundColor: Colors.transparent,
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: kPrimaryBlue),
    );
  }

  final List<String> _cities = const [
    'Ahmedabad', 'Rajkot', 'Vadodara', 'Surat', 'Jamnagar', 'Mumbai'
  ];
  String _city = 'Ahmedabad';

  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSuggestions = false;

  String _selectedSort = 'popularity'; // UI mapping
  Map<String, Set<String>> _selectedFilters = {};

  List<AdminPg> _applyClientFilters(List<AdminPg> list) {
    // City match (normalized): prevents accidental empty list on case/space mismatches
    final cityNorm = _city.toLowerCase().trim();
    var res = list.where((e) => e.city.toLowerCase().trim() == cityNorm).toList();

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((e) =>
      e.name.toLowerCase().contains(q) || e.area.toLowerCase().contains(q)
      ).toList();
    }


    final bud = _selectedFilters['Budget'];
    if (bud != null && bud.isNotEmpty) {
      res = res.where((e) => _inAnyBudget(e.price4x, bud)).toList();
    }

    final genders = _selectedFilters['Gender'];
    if (genders != null && genders.isNotEmpty) {
      // pick first meaningful (ignore 'Any')
      final picked = genders.firstWhere(
            (g) => g.trim().toLowerCase() != 'any',
        orElse: () => '',
      ).toLowerCase();
      if (picked.isNotEmpty) {
        res = res.where((pg) => pg.genderTag.toLowerCase() == picked).toList();
      }
    }

    final occ = _selectedFilters['Occupacy'];
    if (occ != null && occ.isNotEmpty) {
      res = res.where((pg) => _matchesOccupancy(pg, occ)).toList();
    }

    final am = _selectedFilters['Amenities'];
    if (am != null && am.isNotEmpty) {
      final wanted = am.map(_norm).toSet();
      res = res.where((pg) {
        final have = pg.amenities
            .where((x) => kAmenityOptions.contains(x)) // only canonical
            .map(_norm).toSet();
        return wanted.every(have.contains);
      }).toList();
    }

    // Services (must include all selected)
    final sv = _selectedFilters['Services'];
    if (sv != null && sv.isNotEmpty) {
      final wanted = sv.map(_norm).toSet();
      res = res.where((pg) {
        final have = pg.services
            .where((x) => kServiceOptions.contains(x)) // only canonical
            .map(_norm).toSet();
        return wanted.every(have.contains);
      }).toList();
    }

    // sort map
    switch (_selectedSort) {
      case 'low_to_high':
        res.sort((a, b) => a.price4x.compareTo(b.price4x));
        break;
      case 'high_to_low':
        res.sort((a, b) => b.price4x.compareTo(a.price4x));
        break;
      case 'popularity':
      default:
        break;
    }

    return res;
  }

  bool _inAnyBudget(int price, Set<String> ranges) {
    for (final r in ranges) {
      switch (r) {
        case '< ₹5,000':
          if (price < 5000) return true;
          break;
        case '₹5,000 - ₹10,000':
          if (price >= 5000 && price <= 10000) return true;
          break;
        case '₹10,000 - ₹15,000':
          if (price >= 10000 && price <= 15000) return true;
          break;
        case '> ₹15,000':
          if (price > 15000) return true;
          break;
      }
    }
    return false;
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _matchesOccupancy(AdminPg pg, Set<String> occRaw) {
    // support: 2x / x2 / "2 Sharing" / "2" etc.
    final normNums = occRaw
        .map((e) => RegExp(r'(\d)').firstMatch(e)?.group(1) ?? '')
        .where((e) => e.isNotEmpty)
        .toSet();

    bool ok2 = normNums.contains('2') && pg.price2x > 0;
    bool ok3 = normNums.contains('3') && pg.price3x > 0;
    bool ok4 = normNums.contains('4') && pg.price4x > 0;

    // If user selected multiple, match ANY selected occupancy
    return ok2 || ok3 || ok4;
  }

  // suggestions: current stream result se
  List<String> _suggestionsFrom(List<AdminPg> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final allTokens = {
      ...list.map((e) => e.area),
      ...list.map((e) => e.name),
    }.toList();
    return allTokens
        .where((s) => s.toLowerCase().contains(q))
        .toSet()
        .take(8)
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCitySheet() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Change City',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cities.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (ctx, i) {
                  final c = _cities[i];
                  final selected = c == _city;
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, c),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: selected ? kPrimaryBlue : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city, size: 28, color: kPrimaryBlue),
                          const SizedBox(height: 6),
                          Text(
                            c,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selected ? kPrimaryBlue : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (picked != null && picked != _city) {
      setState(() => _city = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double kSearchFieldH = 56;
    const double kHeaderVPad = 20;
    const double kGapToList = 8;
    const double kSugItemH = 52;

    final size = MediaQuery.of(context).size;
    final expandedH = (size.height * 0.24).clamp(160.0, 220.0);

    const double bottomBarH = 76;
    final double listBottomPad =
        bottomBarH + MediaQuery.of(context).padding.bottom + 12;

    final repo = PgRepository();
    final serverQuery = PgQuery(
      city: _city,
      onlyActive: true,
      budgetMin: _selectedFilters['Budget']?.contains('> ₹15,000') == true ? 15001 : null,
      sort: _selectedSort == 'high_to_low'
          ? 'priceDesc'
          : _selectedSort == 'popularity'
          ? 'newest'
          : 'priceAsc',
      searchText: _searchCtrl.text,
    );

    return Scaffold(
      body: StreamBuilder<List<AdminPg>>(
        stream: repo.streamPgs(serverQuery, limit: 100),
        builder: (context, snap) {
          final allServer = snap.data ?? const <AdminPg>[];
          final filtered = _applyClientFilters(allServer);
          final suggestions = _suggestionsFrom(allServer);

          final int sugCount = suggestions.length.clamp(0, 6);
          final double suggestionsH =
          (_showSuggestions && sugCount > 0) ? (kGapToList + kSugItemH * sugCount) : 0;
          final double searchHeaderH = kSearchFieldH + kHeaderVPad + suggestionsH;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ======= Header =======
                  SliverAppBar(
                    pinned: false,
                    floating: false,
                    expandedHeight: expandedH,
                    backgroundColor: kPrimaryBlue,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryBlue, const Color(0xFF6DB9FD)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Hey there!',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          InkWell(
                                            onTap: _openCitySheet,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(_city,
                                                    style: const TextStyle(
                                                        color: Colors.white, fontSize: 14)),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.keyboard_arrow_down,
                                                    color: Colors.white, size: 18),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ProfileViewPage(),
                                          ),
                                        );
                                      },
                                      child: _userDocStream() == null
                                          ? _buildAvatarFromData(null)
                                          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                        stream: _userDocStream(),
                                        builder: (context, s) {
                                          if (s.connectionState == ConnectionState.waiting) {
                                            return CircleAvatar(
                                              radius: 18,
                                              backgroundColor: Colors.white,
                                              child: SizedBox(
                                                height: 14,
                                                width: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: kPrimaryBlue,
                                                ),
                                              ),
                                            );
                                          }
                                          final data = s.data?.data();
                                          return _buildAvatarFromData(data);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Text('Homey Comfort',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                const Text('Conveniently Yours!',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ======= Search bar + suggestions =======
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SearchHeaderDelegate(
                      height: searchHeaderH,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Column(
                          children: [
                            Container(
                              height: kSearchFieldH,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 12),
                                  const Icon(Icons.search, color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      decoration: const InputDecoration(
                                        hintText: 'Search for locality or PG name',
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (v) => setState(() => _showSuggestions = v.isNotEmpty),
                                      onTap: () => setState(() => _showSuggestions = _searchCtrl.text.isNotEmpty),
                                    ),
                                  ),
                                  if (_searchCtrl.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        FocusScope.of(context).unfocus();
                                        setState(() => _showSuggestions = false);
                                      },
                                    ),
                                ],
                              ),
                            ),
                            if (_showSuggestions && suggestions.isNotEmpty) ...[
                              const SizedBox(height: kGapToList),
                              Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: kSugItemH * suggestions.length.clamp(0, 6),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: suggestions.length.clamp(0, 6),
                                    itemExtent: kSugItemH,
                                    itemBuilder: (_, i) {
                                      final s = suggestions[i];
                                      return ListTile(
                                        leading: const Icon(Icons.place_outlined),
                                        title: Text(s),
                                        onTap: () {
                                          _searchCtrl.text = s;
                                          FocusScope.of(context).unfocus();
                                          setState(() => _showSuggestions = false);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Text(
                        "Great! We've picked the best stays for you",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  // ======= List =======
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                        if (snap.hasError) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 60),
                            child: Text('Something went wrong'),
                          );
                        }

                        if (filtered.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                const Icon(Icons.search_off, size: 36, color: Colors.black38),
                                const SizedBox(height: 8),
                                Text('No PGs in $_city',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 4),
                                const Text('Try a different area or update filters',
                                    style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          );
                        }

                        final p = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _PgCard(pg: p),
                        );
                      },
                      childCount: (filtered.isEmpty ? 1 : filtered.length),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: listBottomPad)),
                ],
              ),

              // ======= Bottom sort/filter bar =======
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: bottomBarH,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.sort, color: kPrimaryBlue),
                            label: const Text('Sort By'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryBlue,
                              side: BorderSide(color: kPrimaryBlue, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async {
                              final res = await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                useSafeArea: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => const SortByPage(),
                              );
                              if (!mounted) return;
                              if (res != null && res.isNotEmpty) {
                                setState(() => _selectedSort = res);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sort: $res')),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.filter_list, color: kPrimaryBlue),
                            label: const Text('Filters'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryBlue,
                              side: BorderSide(color: kPrimaryBlue, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async {
                              final res = await showModalBottomSheet<Map<String, Set<String>>>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                useSafeArea: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => const FilterPage(),
                              );
                              if (!mounted) return;
                              if (res != null) {
                                setState(() => _selectedFilters = res);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Filters applied')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _SearchHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _PgCard extends StatelessWidget {
  final AdminPg pg;
  const _PgCard({required this.pg});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PgDetailPage(pg: pg)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _PgImageCarousel(images: pg.images),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pg.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(pg.area, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Spacer(),
                        const Text('Starts from ', style: TextStyle(color: Colors.black45)),
                        Text('₹${pg.price4x}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: -6,
                      children: pg.amenities.take(2).map((a) {
                        return Chip(
                          label: Text(a),
                          backgroundColor: const Color(0xFFF3F4F6),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PgImageCarousel extends StatefulWidget {
  final List<String> images;
  const _PgImageCarousel({required this.images});

  @override
  State<_PgImageCarousel> createState() => _PgImageCarouselState();
}

class _PgImageCarouselState extends State<_PgImageCarousel> {
  late final PageController _pc;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.images.length <= 1) return;
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return false;
        final next = (_index + 1) % widget.images.length;
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _index = next;
        return mounted;
      });
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFFEFEFEF),
          child: const Center(child: Icon(Icons.photo, size: 48, color: Colors.black26)),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final src = widget.images[i];
              return _pgImage(src, fit: BoxFit.cover);
            },
          ),
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _pgImage(String src, {BoxFit fit = BoxFit.cover}) {
  final isNet = src.startsWith('http');
  final placeholder = Container(
    color: const Color(0xFFEFEFEF),
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image_outlined, color: Colors.black45),
  );

  if (isNet) {
    return Image.network(
      src,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  } else {
    return Image.asset(
      src,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}
