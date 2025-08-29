// lib/features/auth/profile_setup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/home_page.dart';
import '../admin/admin_dashboard.dart';

class ProfileSetupPage extends StatefulWidget {
  final String role;
  final String phone;
  final String? initialEmail;
  final String? docId;

  const ProfileSetupPage({
    super.key,
    required this.role,
    required this.phone,
    this.initialEmail,
    this.docId,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _gender;   // 'Male' | 'Female'
  DateTime? _dob;
  bool _showGenderError = false;
  bool _showDobError = false;
  bool _saving = false;

  bool get _isPhonePrefilled => widget.phone.trim().isNotEmpty;
  bool get _isEmailPrefilled => (widget.initialEmail ?? '').trim().isNotEmpty;

  String _normalizeTen(String anyPhone) {
    final digits = anyPhone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = _normalizeTen(widget.phone);
    _emailCtrl.text = widget.initialEmail?.trim() ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final lastDate  = DateTime(now.year - 13, now.month, now.day);
    final firstDate = DateTime(1950, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _showDobError = false;
      });
    }
  }

  Widget _buildAvatar() {
    if (_gender == 'Male') {
      return const CircleAvatar(
        radius: 42,
        backgroundImage: AssetImage('Project_photos/user-avatar-male-5.png'),
        backgroundColor: Colors.transparent,
      );
    } else if (_gender == 'Female') {
      return const CircleAvatar(
        radius: 42,
        backgroundImage: AssetImage('Project_photos/user-avatar-female-6.png'),
        backgroundColor: Colors.transparent,
      );
    } else {
      return const CircleAvatar(
        radius: 42,
        backgroundColor: Color(0xFFE5E7EB),
        child: Icon(Icons.person_outline, size: 42, color: Colors.grey),
      );
    }
  }

  Future<void> _save() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    final genderOk  = _gender != null;
    final dobOk     = _dob != null;

    setState(() {
      _showGenderError = !genderOk;
      _showDobError    = !dobOk;
    });
    if (!(validForm && genderOk && dobOk)) return;

    final tenDigits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final authPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final e164 = authPhone.isNotEmpty
        ? authPhone
        : (tenDigits.isNotEmpty ? '+91$tenDigits' : '');

    final email = _emailCtrl.text.trim();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final data = <String, dynamic>{
      'name':   _nameCtrl.text.trim(),
      'phone':  e164.isEmpty ? null : e164,
      'phoneTen': tenDigits.isEmpty ? null : tenDigits,
      'email':  email.isEmpty ? null : email,
      'gender': _gender,
      'dob':    Timestamp.fromDate(DateTime(_dob!.year, _dob!.month, _dob!.day)),
      'role':   widget.role,
      'avatar': (_gender ?? '').toLowerCase(),
      'profileCompleted': true,
      'authMode': 'FIREBASE_AUTH',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );

      if (widget.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 14),
        children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: h * 0.24,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF74C0FC), Color(0xFF5E8BFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/app logo-1.jpg', height: 90, fit: BoxFit.contain),
                  const SizedBox(height: 10),
                  const Text(
                    'Profile Setup',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _buildAvatar()),
                        const SizedBox(height: 16),

                        _requiredLabel('Full Name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Enter your full name',
                            filled: true,
                            fillColor: Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        _requiredLabel('Mobile Number'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          readOnly: _isPhonePrefilled,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: '10-digit mobile number',
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            suffixIcon: _isPhonePrefilled
                                ? const Icon(Icons.lock_outline, size: 18)
                                : null,
                          ),
                          validator: (v) {
                            final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                            if (d.length != 10) return 'Enter a valid 10-digit number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        _requiredLabel('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: _isEmailPrefilled,
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            suffixIcon: _isEmailPrefilled
                                ? const Icon(Icons.lock_outline, size: 18)
                                : null,
                          ),
                          validator: (v) {
                            final email = (v ?? '').trim();
                            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        _requiredLabel('Gender'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'Male',
                                groupValue: _gender,
                                dense: true,
                                title: const Text('Male'),
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                value: 'Female',
                                groupValue: _gender,
                                dense: true,
                                title: const Text('Female'),
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                            ),
                          ],
                        ),
                        if (_showGenderError)
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 4),
                            child: Text('Please select gender',
                                style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),

                        const SizedBox(height: 4),
                        _requiredLabel('Date of Birth'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDob,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dob == null
                                      ? 'Select your birth date'
                                      : '${_dob!.day.toString().padLeft(2, '0')}-'
                                      '${_dob!.month.toString().padLeft(2, '0')}-'
                                      '${_dob!.year}',
                                  style: TextStyle(
                                    color: _dob == null ? Colors.black54 : Colors.black87,
                                  ),
                                ),
                                const Icon(Icons.calendar_month_rounded),
                              ],
                            ),
                          ),
                        ),
                        if (_showDobError)
                          const Padding(
                            padding: EdgeInsets.only(left: 4, top: 4),
                            child: Text('Please select your birth date',
                                style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),

                        const SizedBox(height: 12),

                        const Text('Role', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Chip(
                          backgroundColor: const Color(0xFFE6F0FF),
                          label: Text(
                            widget.role[0].toUpperCase() + widget.role.substring(1),
                            style: const TextStyle(
                              color: Color(0xFF1F4BFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              backgroundColor: const Color(0xFF5B7CFF),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Text(
                              'Save & Continue',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can change this later in your profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
