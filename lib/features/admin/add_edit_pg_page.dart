// lib/features/admin/add_edit_pg_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_models.dart';
import '../../data/auth_repository.dart';

const kAmenityOptions = <String>[
  'Attached Washroom',
  'Spacious Cupboard',
  'Balcony',
  'Parking',
  'AC Room',
  'Study Table',
];

const kServiceOptions = <String>[
  'High-Speed WIFI',
  'Laundry Service',
  'Professional Housekeeping',
  '24x7 Security Surveillance',
  'Hot and Delicious Meals',
];

const kCityOptions = <String>[
  'Ahmedabad', 'Rajkot', 'Vadodara', 'Surat', 'Jamnagar', 'Mumbai'
];

class AddEditPgPage extends StatefulWidget {
  final AdminPg? existing;
  const AddEditPgPage({super.key, this.existing});

  @override
  State<AddEditPgPage> createState() => _AddEditPgPageState();
}

class _AddEditPgPageState extends State<AddEditPgPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late String _city;
  late final TextEditingController _area;
  late final TextEditingController _address;

  late final TextEditingController _gender;

  final _p2 = TextEditingController();
  final _p3 = TextEditingController();
  final _p4 = TextEditingController();

  final List<String> _images = [];
  final _imageCtrl = TextEditingController();

  bool _hidden = false;
  bool _saving = false;

  final Set<String> _amenities = {};
  final Set<String> _services = {};

  // Owner (editable)
  final _ownerNameCtrl  = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ---- Owner auto-fill (optional prefill; admin can edit) ----
    _loadOwner();

    final e = widget.existing;
    _name    = TextEditingController(text: e?.name ?? '');
    _area    = TextEditingController(text: e?.area ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _gender  = TextEditingController(text: e?.genderTag ?? 'Any');

    _city = (e?.city ?? kCityOptions.first).trim();

    if (e != null) {
      if (e.price2x > 0) _p2.text = e.price2x.toString();
      if (e.price3x > 0) _p3.text = e.price3x.toString();
      if (e.price4x > 0) _p4.text = e.price4x.toString();

      _images.addAll(e.images);
      _hidden = e.hidden;
      _amenities.addAll(e.amenities);
      _services.addAll(e.services);

      _ownerNameCtrl.text  = e.ownerName;
      _ownerPhoneCtrl.text = e.ownerPhone;
    }
  }

  Future<void> _loadOwner() async {
    try {
      final profile = await AuthRepository().getCurrentProfile();
      if (!mounted) return;
      if (_ownerNameCtrl.text.trim().isEmpty) {
        _ownerNameCtrl.text  = (profile?.name ?? '').trim();
      }
      if (_ownerPhoneCtrl.text.trim().isEmpty) {
        _ownerPhoneCtrl.text = (profile?.phone ?? '').trim();
      }
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _address.dispose();
    _gender.dispose();
    _p2.dispose();
    _p3.dispose();
    _p4.dispose();
    _imageCtrl.dispose();
    _ownerNameCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    super.dispose();
  }

  String _normalizeGenderTag(String raw) {
    final g = raw.trim().toLowerCase();
    if (g.startsWith('m')) return 'Male';
    if (g.startsWith('f')) return 'Female';
    return 'Any';
  }

  void _addImage() {
    final v = _imageCtrl.text.trim();
    if (v.isEmpty) return;

    final reg = RegExp(r'drive\.google\.com/file/d/([^/]+)/');
    final m = reg.firstMatch(v);
    final url = (m != null)
        ? 'https://drive.google.com/uc?export=view&id=${m.group(1)!}'
        : v;

    setState(() {
      _images.add(url);
      _imageCtrl.clear();
    });
  }

  Widget _chipWrap(List<String> source, Set<String> selected) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in source)
            FilterChip(
              label: Text(s),
              selected: selected.contains(s),
              onSelected: (v) {
                setState(() {
                  v ? selected.add(s) : selected.remove(s);
                });
              },
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ownerName  = _ownerNameCtrl.text.trim();
    final ownerPhone = _ownerPhoneCtrl.text.trim();
    final digitsOnly = ownerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (ownerName.isEmpty) {
      _snack('Please enter PG Owner Name');
      return;
    }
    if (digitsOnly.length != 10) {
      _snack('Owner Contact Number must be 10 digits');
      return;
    }

    if (_images.isEmpty) {
      _snack('Add at least 1 image URL');
      return;
    }
    if (_amenities.isEmpty) {
      _snack('Select at least 1 amenity');
      return;
    }
    if (_services.isEmpty) {
      _snack('Select at least 1 service');
      return;
    }

    final p2 = int.tryParse(_p2.text.trim()) ?? 0;
    final p3 = int.tryParse(_p3.text.trim()) ?? 0;
    final p4 = int.tryParse(_p4.text.trim()) ?? 0;
    if (p2 <= 0 || p3 <= 0 || p4 <= 0) {
      _snack('Enter valid prices for 2x / 3x / 4x (all > 0)');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Please login as Admin to continue');
      return;
    }

    final isEdit = widget.existing != null;
    final genderTag = _normalizeGenderTag(_gender.text);
    final city = _city.trim();
    final cityKey = city.toLowerCase();

    final baseMap = <String, dynamic>{
      'name': _name.text.trim(),
      'city': city,
      'cityKey': cityKey,
      'area': _area.text.trim(),
      'address': _address.text.trim(),
      'genderTag': genderTag,
      'price2x': p2,
      'price3x': p3,
      'price4x': p4,
      'hidden': _hidden,
      'isActive': !_hidden,
      'images': _images,
      'amenities': _amenities.toList(),
      'services': _services.toList(),
      // Owner
      'ownerName': ownerName,
      'ownerPhone': digitsOnly,
      'ownerId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
    };

    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance.collection('pgs');
      String docId;

      if (isEdit) {
        docId = widget.existing!.id;
        await col.doc(docId).set(baseMap, SetOptions(merge: true));
      } else {
        final ref = await col.add(baseMap);
        docId = ref.id;
      }

      final pg = AdminPg(
        id: docId,
        name: _name.text.trim(),
        city: city,
        area: _area.text.trim(),
        address: _address.text.trim(),
        genderTag: genderTag,
        price2x: p2,
        price3x: p3,
        price4x: p4,
        hidden: _hidden,
        images: List.of(_images),
        amenities: _amenities.toList(),
        services: _services.toList(),
        ownerName: ownerName,
        ownerPhone: digitsOnly,
      );

      if (!mounted) return;
      _snack(isEdit ? 'PG updated' : 'PG added');
      Navigator.pop(context, pg);
    } catch (e) {
      if (!mounted) return;
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    // If existing city is not in fixed list, show it as an extra option
    final List<String> cityItems = List.of(kCityOptions);
    if (!cityItems.contains(_city)) {
      cityItems.add(_city);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit PG' : 'Add PG'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              height: 16, width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _tf(_name, 'PG Name', required: true),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _city,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: cityItems
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _city = v ?? kCityOptions.first),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                _tf(_area, 'Area', required: true),
                const SizedBox(height: 12),

                _tf(_address, 'Full Address', maxLines: 2, required: true),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _gender.text.isEmpty ? 'Any' : _gender.text,
                  decoration: const InputDecoration(
                    labelText: 'Preferred By',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Any', child: Text('Any')),
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (v) => setState(() => _gender.text = v ?? 'Any'),
                ),
                const SizedBox(height: 12),

                // 2x / 3x / 4x prices
                Row(
                  children: [
                    Expanded(
                      child: _tf(_p2, '2x Starts from (₹)',
                          keyboard: TextInputType.number, required: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tf(_p3, '3x Starts from (₹)',
                          keyboard: TextInputType.number, required: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tf(_p4, '4x Starts from (₹)',
                          keyboard: TextInputType.number, required: true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _tf(_imageCtrl, 'Add image URL (or asset path)')),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _addImage, child: const Text('Add')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_images.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _images.map((p) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              color: Colors.white,
                            ),
                            child: p.startsWith('http')
                                ? Image.network(p, fit: BoxFit.cover)
                                : Image.asset(p, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: InkWell(
                              onTap: () => setState(() => _images.remove(p)),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),
                SwitchListTile(
                  value: _hidden,
                  onChanged: (v) => setState(() => _hidden = v),
                  title: const Text('Hidden (turn OFF to make Active)'),
                ),

                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Amenities', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                _chipWrap(kAmenityOptions, _amenities),

                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Services', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                _chipWrap(kServiceOptions, _services),

                const SizedBox(height: 16),

                // Owner (editable)
                TextFormField(
                  controller: _ownerNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'PG Owner Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ownerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Owner Contact Number',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(isEdit ? 'Update' : 'Add PG'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tf(
      TextEditingController c,
      String hint, {
        int maxLines = 1,
        bool required = false,
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
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
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF537FF4), width: 1.4),
        ),
      ),
    );
  }
}
