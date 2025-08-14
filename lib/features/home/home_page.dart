// lib/features/home/home_page.dart
import 'package:flutter/material.dart';
import '../profile/profile_view_page.dart';
import '../sort_filter/sort_by_page.dart';
import '../sort_filter/filter_page.dart';
import '../pg/pg_detail_page.dart';
import '../pg/pg_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color kPrimaryBlue = const Color(0xFF007AFF);

  final List<String> _cities = const [
    'Ahmedabad', 'Rajkot', 'Vadodara', 'Surat', 'Jamnagar', 'Mumbai'
  ];
  String _city = 'Ahmedabad';

  final List<_Pg> _all = [
    _Pg(
      'Sonoma House',
      'Gota',
      'Ahmedabad',
      15799,
      ['Attached Washroom', 'Spacious Cupboard'],
      images: const [
        'assets/images/pg1_1.jpg',
        'assets/images/pg1_2.jpg',
        'assets/images/pg1_3.jpg',
      ],
    ),
    _Pg(
      'Wilmington House',
      'Navrangpura',
      'Ahmedabad',
      16099,
      ['Air Conditioning', 'Attached Washroom'],
      images: const [
        'assets/images/pg1_4.jpg',
        'assets/images/pg1_5.jpg',
        'assets/images/pg1_6.jpg',
      ],
    ),
    _Pg(
      'Elgin House',
      'Bopal & Shilaj',
      'Ahmedabad',
      12399,
      ['Laundry', 'Meals'],
      images: const [
        'assets/images/pg1_2.jpg',
        'assets/images/pg1_3.jpg',
        'assets/images/pg1_4.jpg',
      ],
    ),
    _Pg(
      'Marine Stay',
      'Andheri',
      'Mumbai',
      18999,
      ['WiFi', 'Housekeeping'],
      images: const [
        'assets/images/pg1_5.jpg',
        'assets/images/pg1_6.jpg',
        'assets/images/pg1_1.jpg',
      ],
    ),
    _Pg(
      'Green Nest',
      'Alkapuri',
      'Vadodara',
      12999,
      ['Meals', 'Security'],
      images: const [
        'assets/images/pg1_3.jpg',
        'assets/images/pg1_4.jpg',
        'assets/images/pg1_5.jpg',
      ],
    ),
    _Pg(
      'City Comfort',
      'Adajan',
      'Surat',
      11999,
      ['Cupboard', 'Laundry'],
      images: const [
        'assets/images/pg1_6.jpg',
        'assets/images/pg1_1.jpg',
        'assets/images/pg1_2.jpg',
      ],
    ),
  ];

  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSuggestions = false;

  String _selectedSort = 'popularity';
  Map<String, Set<String>> _selectedFilters = {};

  List<_Pg> get _filtered {
    // 1) City
    var list = _all.where((e) => e.city == _city).toList();

    // 2) Search
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) =>
      e.name.toLowerCase().contains(q) ||
          e.area.toLowerCase().contains(q))
          .toList();
    }

    // 3) Filters
    list = _applyFilters(list);

    // 4) Sort
    return _applySort(list);
  }


  List<_Pg> _applySort(List<_Pg> list) {
    final copy = [...list];
    switch (_selectedSort) {
      case 'low_to_high':
        copy.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'high_to_low':
        copy.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popularity':
      default:
        break;
    }
    return copy;
  }
  List<_Pg> _applyFilters(List<_Pg> list) {
    var res = [...list];

    // --- Locality ---
    final loc = _selectedFilters['Locality'];
    if (loc != null && loc.isNotEmpty) {
      final locSet = loc.map((s) => s.toLowerCase()).toSet();
      res = res.where((e) => locSet.contains(e.area.toLowerCase())).toList();
    }

    // --- Budget ---
    final bud = _selectedFilters['Budget'];
    if (bud != null && bud.isNotEmpty) {
      res = res.where((e) => _inAnyBudget(e.price, bud)).toList();
    }

    // --- Amenities ---
    final am = _selectedFilters['Amenities'];
    if (am != null && am.isNotEmpty) {
      final wanted = am.map(_norm).toSet();
      res = res.where((pg) {
        final have = pg.amenities.map(_norm).toSet();
        // require ALL selected amenities
        return wanted.every(have.contains);
      }).toList();
    }

    // --- Services ---
    final sv = _selectedFilters['Services'];
    if (sv != null && sv.isNotEmpty) {
      final wanted = sv.map(_norm).toSet();

      res = res.where((pg) {
        final have = pg.amenities.map(_norm).toSet();
        return wanted.every(have.contains);
      }).toList();
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

  String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }


  List<String> get _suggestions {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final allTokens = {
      ..._all.map((e) => e.area),
      ..._all.map((e) => e.name),
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
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                            color: selected
                                ? kPrimaryBlue
                                : const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city,
                              size: 28, color: kPrimaryBlue),
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
    final int sugCount = _suggestions.length.clamp(0, 6);
    final double suggestionsH =
    (_showSuggestions && sugCount > 0) ? (kGapToList + kSugItemH * sugCount) : 0;
    final double searchHeaderH = kSearchFieldH + kHeaderVPad + suggestionsH;

    final size = MediaQuery.of(context).size;
    final expandedH = (size.height * 0.24).clamp(160.0, 220.0);

    const double bottomBarH = 76;
    final double listBottomPad =
        bottomBarH + MediaQuery.of(context).padding.bottom + 12;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
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
                                                    color: Colors.white,
                                                    fontSize: 14)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.keyboard_arrow_down,
                                                color: Colors.white, size: 18),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child:
                                    Icon(Icons.person, color: kPrimaryBlue),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                          const ProfileViewPage()),
                                    );
                                  },
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
                              BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3))
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
                                  onChanged: (v) => setState(
                                          () => _showSuggestions = v.isNotEmpty),
                                  onTap: () => setState(() =>
                                  _showSuggestions =
                                      _searchCtrl.text.isNotEmpty),
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
                        if (_showSuggestions && _suggestions.isNotEmpty) ...[
                          const SizedBox(height: kGapToList),
                          Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: kSugItemH * sugCount,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sugCount,
                                itemExtent: kSugItemH,
                                itemBuilder: (_, i) {
                                  final s = _suggestions[i];
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

              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                    final items = _filtered;
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 60),
                        child: Column(
                          children: [
                            SizedBox(height: 20),
                            Icon(Icons.search_off,
                                size: 36, color: Colors.black38),
                            SizedBox(height: 8),
                            Text('Not Found',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Try a different area or PG name',
                                style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      );
                    }
                    final p = items[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _PgCard(pg: p),
                    );
                  },
                  childCount: _filtered.isEmpty ? 1 : _filtered.length,
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: listBottomPad)),
            ],
          ),

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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          final res = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            useSafeArea: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle:
                          const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          final res =
                          await showModalBottomSheet<Map<String, Set<String>>>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            useSafeArea: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _PgCard extends StatelessWidget {
  final _Pg pg;
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
            MaterialPageRoute(
              builder: (_) => PgDetailPage(
                data: PgDetailData(
                  name: pg.name,
                  city: pg.city,
                  area: pg.area,
                  address: '${pg.area}, ${pg.city}',
                  genderTag: 'Male',
                  images: pg.images.isNotEmpty
                      ? pg.images
                      : const ['assets/images/pg1_1.jpg'],
                  priceChips: const ['x2  ₹19,799', 'x3  ₹17,499', 'x4  ₹16,099'],
                  amenities: pg.amenities,
                  services: const [
                    'Hot and Delicious Meals',
                    'High-Speed WIFI',
                    'Laundry Service',
                    'Professional Housekeeping',
                    '24x7 Security Surveillance',
                  ],
                ),
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))
            ],
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
                    Text(pg.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(pg.area, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Spacer(),
                        const Text('Starts from ',
                            style: TextStyle(color: Colors.black45)),
                        Text('₹${pg.price}',
                            style: const TextStyle(fontWeight: FontWeight.w800)),
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
        _pc.animateToPage(next,
            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
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
    // If no images, show placeholder (prevents null/empty issues)
    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFFEFEFEF),
          child: const Center(
            child: Icon(Icons.photo, size: 48, color: Colors.black26),
          ),
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
            itemBuilder: (_, i) => Image.asset(
              widget.images[i],
              fit: BoxFit.cover,
            ),
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

class _Pg {
  final String name;
  final String area;
  final String city;
  final int price;
  final List<String> amenities;
  final List<String> images;

  _Pg(this.name, this.area, this.city, this.price, this.amenities,
      {List<String>? images})
      : images = images ?? const [];
}
