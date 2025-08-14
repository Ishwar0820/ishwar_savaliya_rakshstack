import 'package:flutter/material.dart';

class SortByPage extends StatefulWidget {
  const SortByPage({super.key});

  @override
  State<SortByPage> createState() => _SortByPageState();
}

class _SortByPageState extends State<SortByPage> {
  String _selectedSort = 'popularity';

  @override
  Widget build(BuildContext context) {
    return SafeArea( // ⬅️ bottom inset ko respect kare
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top indicator bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sort By',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),

            // Options area
            SizedBox(
              height: 300, // fixed list area, buttons stay below
              child: Row(
                children: [
                  // Left side label
                  Container(
                    width: 90,
                    color: const Color(0xFFE6F0FF),
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Sort By',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right side options
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        RadioListTile<String>(
                          title: const Text("Price: Low to High"),
                          value: 'low_to_high',
                          groupValue: _selectedSort,
                          onChanged: (value) =>
                              setState(() => _selectedSort = value!),
                        ),
                        RadioListTile<String>(
                          title: const Text("Price: High to Low"),
                          value: 'high_to_low',
                          groupValue: _selectedSort,
                          onChanged: (value) =>
                              setState(() => _selectedSort = value!),
                        ),
                        RadioListTile<String>(
                          title: const Text("Sort By: Popularity"),
                          value: 'popularity',
                          groupValue: _selectedSort,
                          onChanged: (value) =>
                              setState(() => _selectedSort = value!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom buttons — wrapped in SafeArea so they never sit under nav bar
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
                          setState(() => _selectedSort = 'popularity');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        onPressed: () {
                          Navigator.pop(context, _selectedSort);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}
