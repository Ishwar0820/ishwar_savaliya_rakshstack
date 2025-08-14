import 'dart:async';
import 'package:flutter/material.dart';

import 'profile_setup_page.dart';
import '../home/home_page.dart';                         // ⬅ import
import '../../data/auth_repository.dart';
import '../admin/admin_profile_setup_page.dart';
import '../admin/admin_dashboard.dart';

class OtpVerifyPage extends StatefulWidget {
  final String role;           // 'customer' | 'admin'
  final String phone;          // e.g. +91xxxxxxxxxx
  final bool loginFlow;        // ⬅ NEW: true => this is Login, false => Registration
  const OtpVerifyPage({
    super.key,
    required this.role,
    required this.phone,
    this.loginFlow = false,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _nodes  = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _left = 15;

  bool get _canVerify =>
      _digits.every((c) => c.text.trim().length == 1 && RegExp(r'^\d$').hasMatch(c.text));

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = 15);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left == 0) {
        t.cancel();
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      // Paste handling
      final only = v.replaceAll(RegExp(r'\D'), '');
      for (int k = 0; k < only.length && i + k < 6; k++) {
        _digits[i + k].text = only[k];
      }
      final last = (i + only.length - 1).clamp(0, 5);
      _nodes[last].requestFocus();
      setState(() {});
      return;
    }
    if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    setState(() {});
  }

  Future<void> _verify() async {
    if (!_canVerify) return;
    final code = _digits.map((e) => e.text).join();

    // TODO: integrate real Firebase verify
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OTP verified: $code\nRole: ${widget.role}')),
    );

    final repo = AuthRepository();
    await repo.setLoggedIn(role: widget.role, v: true);

    if (!mounted) return;

    // ---------- Role-wise routing ----------
    if (widget.role == 'admin') {
      // Admin: if profile not complete → setup, else dashboard
      final done = await repo.isProfileComplete('admin');
      if (!mounted) return;
      if (!done) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProfileSetupPage(phone: widget.phone),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      }
    } else {
      // Customer:
      if (widget.loginFlow) {
        // Login → directly home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // Registration → go to profile setup (phone prefilled)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupPage(
              role: widget.role,
              phone: widget.phone,
            ),
          ),
        );
      }
    }
  }

  void _resend() {
    if (_left != 0) return;
    // TODO: Firebase resend trigger
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OTP resent to ${widget.phone}')),
    );
    _startTimer();
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
              height: h * 0.28,
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
                children: const [
                  Icon(Icons.lock_outline_rounded, color: Colors.white, size: 52),
                  SizedBox(height: 8),
                  Text(
                    'Verification Code',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
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
                  child: Column(
                    children: [
                      Text(
                        'OTP has been sent to ${widget.phone}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),

                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 44,
                            child: TextField(
                              controller: _digits[i],
                              focusNode: _nodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Color(0xFF5B7CFF), width: 1.4),
                                ),
                              ),
                              onChanged: (v) => _onChanged(i, v),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      // Timer & Resend
                      Column(
                        children: [
                          Text(
                            _left > 0 ? '00:${_left.toString().padLeft(2, '0')}' : 'You can resend now',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _left == 0 ? _resend : null,
                            child: Text(
                              'Resend',
                              style: TextStyle(
                                color: _left == 0 ? const Color(0xFF5B7CFF) : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            backgroundColor: _canVerify ? const Color(0xFF5B7CFF) : const Color(0xFF9CA3AF),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _canVerify ? _verify : null,
                          child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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
