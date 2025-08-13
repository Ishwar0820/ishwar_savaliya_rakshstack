  // lib/features/sort_filter/filter_page.dart
  import 'package:flutter/material.dart';

  class FilterPage extends StatefulWidget {
    const FilterPage({super.key});

    @override
    State<FilterPage> createState() => _FilterPageState();
  }

  class _FilterPageState extends State<FilterPage> {
    int _selectedTab = 0;

    final List<String> _tabs = const [
      "Locality",
      "Budget",
      "Gender",
      "Preferred By",
      "Occupancy",
      "Amenities",
      "Services",
      "Collection"
    ];

    final Map<String, List<String>> _options = const {
      "Locality": ["Bopal & Shilaj", "Gota", "Navrangpura", "Vastrapur & Thaltej"],
      "Budget": ["< ₹5,000", "₹5,000 - ₹10,000", "₹10,000 - ₹15,000", "> ₹15,000"],
      "Gender": ["Male", "Female"],
      "Preferred By": ["Students", "Working Professionals"],
      "Occupancy": ["Single", "Double", "Triple"],
      "Amenities": ["Wi‑Fi", "Laundry", "Gym", "CCTV"],
      "Services": ["Housekeeping", "Food", "Electricity Included"],
      "Collection": ["Premium", "Budget Friendly"]
    };

    final Map<String, Set<String>> _selected = {};

    @override
    void initState() {
      super.initState();
      for (final tab in _tabs) {
        _selected[tab] = <String>{};
      }
    }

    @override
    Widget build(BuildContext context) {
      final String currentTab = _tabs[_selectedTab];
      final List<String> options = _options[currentTab] ?? const [];

      return SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Material(
              color: Colors.white,
              child: Column(
                children: [

                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // title
                  const Text(
                    "Filters",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  Expanded(
                    child: Row(
                      children: [
                        // Left Tabs
                        Container(
                          width: 110,
                          color: const Color(0xFFE6F0FF),
                          child: ListView.builder(
                            itemCount: _tabs.length,
                            itemBuilder: (context, index) {
                              final bool active = _selectedTab == index;
                              return InkWell(
                                onTap: () => setState(() => _selectedTab = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 16),
                                  color: active ? Colors.white : Colors.transparent,
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: active ? Colors.black : Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Right options (scrollable)
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: options.length,
                            itemBuilder: (_, i) {
                              final opt = options[i];
                              final isSelected = _selected[currentTab]!.contains(opt);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(opt),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected[currentTab]!.add(opt);
                                    } else {
                                      _selected[currentTab]!.remove(opt);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom buttons
                  const Divider(height: 1),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  for (final key in _selected.keys) {
                                    _selected[key]!.clear();
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Clear All"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, _selected),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Apply"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
