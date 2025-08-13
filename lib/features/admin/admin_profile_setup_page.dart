// lib/features/admin/admin_profile_setup_page.dart
import 'package:flutter/material.dart';
import '../../data/auth_repository.dart';
import '../../models/admin_profile.dart';
import 'admin_dashboard.dart';

class AdminProfileSetupPage extends StatefulWidget {
  final String phone;
  const AdminProfileSetupPage({super.key, required this.phone});

  @override
  State<AdminProfileSetupPage> createState() => _AdminProfileSetupPageState();
}

class _AdminProfileSetupPageState extends State<AdminProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String? _gender;

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final email = v.trim();
    final re = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$');
    if (!re.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    try {
      final profile = AdminProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: widget.phone,
        gender: _gender!,
        city: _cityCtrl.text.trim(),
      );

      final repo = AuthRepository();
      await repo.saveAdminProfile(profile);
      await repo.setProfileComplete(role: 'admin', v: true);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (_) => false,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        children: const [
          TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Full Name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  validator: _req,
                  decoration: _dec('Enter Full Name'),
                ),
                const SizedBox(height: 16),

                _label('Email'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  validator: _emailValidator,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Enter Email'),
                ),
                const SizedBox(height: 16),

                _label('Mobile Number'),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: widget.phone,
                  enabled: false,
                  decoration: _dec('Phone'),
                ),
                const SizedBox(height: 16),

                _label('Gender'),
                const SizedBox(height: 6),

                // Gender Validation...
                FormField<String>(
                  validator: (_) =>
                  (_gender == null) ? 'Please select gender' : null,
                  builder: (state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: 'Male',
                              groupValue: _gender,
                              onChanged: (v) {
                                setState(() => _gender = v);
                                state.didChange(v);
                              },
                            ),
                            const Text('Male'),
                            const SizedBox(width: 16),
                            Radio<String>(
                              value: 'Female',
                              groupValue: _gender,
                              onChanged: (v) {
                                setState(() => _gender = v);
                                state.didChange(v);
                              },
                            ),
                            const Text('Female'),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                _label('City'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cityCtrl,
                  validator: _req,
                  decoration: _dec('Enter City'),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF537FF4),
                      disabledBackgroundColor: const Color(0xFFBFD0FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_saving ? 'Saving...' : 'Save & Continue'),
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
