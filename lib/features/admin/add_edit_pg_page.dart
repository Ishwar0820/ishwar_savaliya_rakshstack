// lib/features/admin/add_edit_pg_page.dart
import 'package:flutter/material.dart';
import 'admin_models.dart';

class AddEditPgPage extends StatefulWidget {
  final AdminPg? existing;
  const AddEditPgPage({super.key, this.existing});

  @override
  State<AddEditPgPage> createState() => _AddEditPgPageState();
}

class _AddEditPgPageState extends State<AddEditPgPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _area;
  late final TextEditingController _address;
  late final TextEditingController _gender;
  late final TextEditingController _price;
  final List<String> _images = [];
  final _imageCtrl = TextEditingController();
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _area = TextEditingController(text: e?.area ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _gender = TextEditingController(text: e?.genderTag ?? '');
    _price = TextEditingController(text: e?.minPrice.toString() ?? '');
    _images.addAll(e?.images ?? []);
    _hidden = e?.hidden ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _area.dispose();
    _address.dispose();
    _gender.dispose();
    _price.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.existing != null;
    final id = isEdit ? widget.existing!.id : 'pg_${DateTime.now().millisecondsSinceEpoch}';
    final pg = AdminPg(
      id: id,
      name: _name.text.trim(),
      city: _city.text.trim(),
      area: _area.text.trim(),
      address: _address.text.trim(),
      genderTag: _gender.text.trim().isEmpty ? 'Any' : _gender.text.trim(),
      minPrice: int.tryParse(_price.text.trim()) ?? 0,
      hidden: _hidden,
      images: List.of(_images),
    );
    Navigator.pop(context, pg);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit PG' : 'Add PG'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
                _tf(_name, 'Name', required: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _tf(_city, 'City', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _tf(_area, 'Area', required: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _tf(_address, 'Full Address', maxLines: 2, required: true),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _tf(_gender, 'Gender (Male/Female)')),
                    const SizedBox(width: 12),
                    Expanded(child: _tf(_price, 'Starts From (₹)', keyboard: TextInputType.number, required: true)),
                  ],
                ),
                const SizedBox(height: 12),

                // Images list + add
                Row(
                  children: [
                    Expanded(child: _tf(_imageCtrl, 'Add image path (asset or URL)')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final p = _imageCtrl.text.trim();
                        if (p.isNotEmpty) {
                          setState(() => _images.add(p));
                          _imageCtrl.clear();
                        }
                      },
                      child: const Text('Add'),
                    ),
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

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'Update' : 'Create'),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF537FF4), width: 1.4),
        ),
      ),
    );
  }
}
