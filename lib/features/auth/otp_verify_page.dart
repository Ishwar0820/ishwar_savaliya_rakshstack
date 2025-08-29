// lib/features/auth/otp_verify_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_setup_page.dart';
import '../home/home_page.dart';
import '../admin/admin_dashboard.dart';
import '../../env.dart';

class OtpVerifyPage extends StatefulWidget {
  final String role;
  final String phone;
  final bool loginFlow;
  final String? verificationId;
  final int? resendToken;

  const OtpVerifyPage({
    super.key,
    required this.role,
    required this.phone,
    this.loginFlow = false,
    this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _digits =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _left = 60;
  bool _loading = false;

  String? _verificationId;
  int? _resendToken;

  bool get _canVerify =>
      _digits.every((c) => c.text.trim().length == 1 && RegExp(r'^\d$').hasMatch(c.text));

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _left = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left == 0) {
        t.cancel();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _onChanged(int i, String v) {
    if (v.length > 1) {
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

  String _normalizeTen(String anyPhone) {
    final digits = anyPhone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// users/{uid} doc read
  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDocByUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists ? doc : null;
  }

  Future<void> _routeAfterLogin(DocumentSnapshot<Map<String, dynamic>> userDoc) async {
    final data = userDoc.data() ?? {};
    final role = (data['role'] ?? 'customer').toString();

    if (!mounted) return;
    if (role == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> _goToProfileSetup(String role, String uid, String ten, {required String authMode}) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'phone': '+91$ten',
      'phoneTen': ten,
      'role': role,
      'loginFlow': false,
      'authMode': authMode,
      'profileCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupPage(
          role: role,
          phone: '+91$ten',
          initialEmail: '',
          docId: uid,
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (!_canVerify || _loading) return;
    setState(() => _loading = true);

    final ten = _normalizeTen(widget.phone);
    final code = _digits.map((e) => e.text).join();

    try {
      if (kUseFakePhoneAuth || (_verificationId == null || _verificationId!.isEmpty)) {
        if (code.length != 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter 6-digit code')),
          );
          return;
        }

        User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          try {
            user = (await FirebaseAuth.instance.signInAnonymously()).user;
          } on FirebaseAuthException catch (e) {
            if (e.code == 'operation-not-allowed' || e.code == 'admin-restricted-operation') {
              if (_verificationId != null && _verificationId!.isNotEmpty) {
                final cred = PhoneAuthProvider.credential(
                  verificationId: _verificationId!,
                  smsCode: code,
                );
                await FirebaseAuth.instance.signInWithCredential(cred);
                user = FirebaseAuth.instance.currentUser;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Anonymous sign-in disabled. Enable Anonymous in Firebase Auth, or set kUseFakePhoneAuth=false to use real OTP.',
                    ),
                  ),
                );
                return;
              }
            } else {
              rethrow;
            }
          }
        }

        final selectedRole = (widget.role == 'admin') ? 'admin' : 'customer';
        try {
          if (user != null) {
            final snap = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            final existingRole = (snap.data()?['role'] ?? '').toString();
            if (existingRole.isNotEmpty && existingRole != selectedRole) {
              await FirebaseAuth.instance.signOut();
              user = (await FirebaseAuth.instance.signInAnonymously()).user;
            }
          }
        } catch (_) {
        }

        final uid = user!.uid;
        final role = selectedRole;

        if (widget.loginFlow) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'phone': '+91$ten',
            'phoneTen': ten,
            'role': role,
            'authMode': (_verificationId != null && _verificationId!.isNotEmpty)
                ? 'PHONE_AUTH'
                : 'DEV_BYPASS',
            'profileCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          if (!mounted) return;
          if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }
        } else {
          await _goToProfileSetup(
            role,
            uid,
            ten,
            authMode: (_verificationId != null && _verificationId!.isNotEmpty)
                ? 'PHONE_AUTH'
                : 'DEV_BYPASS',
          );
        }
        return;
      }

      // ---------- REAL FIREBASE OTP MODE ----------
      try {
        final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: code,
        );
        await FirebaseAuth.instance.signInWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        String msg;
        switch (e.code) {
          case 'invalid-verification-code':
          case 'session-expired':
          case 'code-expired':
            msg = 'Wrong or expired OTP. Please request a new code.';
            break;
          case 'too-many-requests':
            msg = 'Too many attempts, try later';
            break;
          default:
            msg = 'Could not verify OTP. ${(e.message ?? '').trim()}'.trim();
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;

      if (widget.loginFlow) {
        final doc = await _getUserDocByUid();
        if (doc == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No account found for this number')),
          );
          return;
        }
        await _routeAfterLogin(doc);
      } else {
        final role = (widget.role == 'admin') ? 'admin' : 'customer';
        await _goToProfileSetup(role, uid, ten, authMode: 'PHONE_AUTH');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not continue: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 🔁 Resend using forceResendingToken (disabled in fake mode)
  Future<void> _resend() async {
    if (_left != 0) return;

    if (kUseFakePhoneAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resend disabled in dev mode')),
      );
      _startTimer();
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resend failed: ${e.code}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resend OTP')),
      );
    }
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
                            backgroundColor: (_canVerify && !_loading)
                                ? const Color(0xFF5B7CFF)
                                : const Color(0xFF9CA3AF),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: (_canVerify && !_loading) ? _verify : null,
                          child: _loading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w600)),
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
