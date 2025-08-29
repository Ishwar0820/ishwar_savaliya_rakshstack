// lib/features/auth/login_page.dart
import 'package:flutter/material.dart';
import 'otp_verify_page.dart';
import '../home/home_page.dart';
import '../admin/admin_dashboard.dart';
import 'register_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../env.dart';

class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _emailMode = true;

  // phone
  final _phoneCtrl = TextEditingController();
  bool get _validPhone =>
      _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').length == 10;

  // email
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // loaders
  bool _loginLoading = false; // email login loader
  bool _phoneLoading = false; // phone start loader

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loginLoading = true);
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text.trim();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;
      if (widget.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed, Please try again !';
      if (e.code == 'user-not-found') msg = 'No user found with this email';
      if (e.code == 'wrong-password') msg = 'Incorrect password';
      if (e.code == 'invalid-email') msg = 'Invalid email';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to login right now')),
      );
    } finally {
      if (mounted) setState(() => _loginLoading = false);
    }
  }

  Future<void> _loginPhoneOtp() async {
    final ten = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (ten.length != 10) return;
    final e164 = '+91$ten';

    setState(() => _phoneLoading = true);
    try {
      final users = FirebaseFirestore.instance.collection('users');

      QuerySnapshot<Map<String, dynamic>> q = await users
          .where('phoneTen', isEqualTo: ten)
          .where('role', isEqualTo: widget.role)
          .limit(1)
          .get();

      if (q.docs.isEmpty) {
        q = await users
            .where('phone', isEqualTo: e164)
            .where('role', isEqualTo: widget.role)
            .limit(1)
            .get();
      }

      // 3) Fallback: old data where 'phone' stored as raw 10-digit
      if (q.docs.isEmpty) {
        q = await users
            .where('phone', isEqualTo: ten)
            .where('role', isEqualTo: widget.role)
            .limit(1)
            .get();
      }

      if (q.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No account found for this mobile number. Please sign up or check the selected role.',
            ),
          ),
        );
        return;
      }

      // Extra guard (redundant but safe)
      final data = q.docs.first.data();
      final savedRole = (data['role'] ?? '').toString();
      if (savedRole.isNotEmpty && savedRole != widget.role) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This number is registered as $savedRole. Please switch role to log in.',
            ),
          ),
        );
        return;
      }

      // 4) Navigate to OTP
      if (kUseFakePhoneAuth) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerifyPage(
              role: widget.role,
              phone: e164,
              loginFlow: true,
            ),
          ),
        );
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential _) {},
        verificationFailed: (FirebaseAuthException e) {
          final msg = (e.code == 'invalid-phone-number')
              ? 'Invalid phone number'
              : 'Verification failed. Try again';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerifyPage(
                role: widget.role,
                phone: e164,
                loginFlow: true,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check/start phone login: $e')),
      );
    } finally {
      if (mounted) setState(() => _phoneLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Log In';

    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            if (_emailMode)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Email is required';
                        final ok =
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);
                        return ok ? null : 'Enter a valid email';
                      },
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                        filled: true,
                        fillColor: Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      validator: (v) =>
                      (v ?? '').isEmpty ? 'Password is required' : null,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loginLoading ? null : _loginEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF5B7CFF),
                          foregroundColor: Colors.white,
                        ),
                        child: _loginLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Log In'),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+91',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'Enter 10-digit phone number',
                            filled: true,
                            fillColor: Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          onChanged: (_) =>
                              setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                      (_validPhone && !_phoneLoading) ? _loginPhoneOtp : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: _validPhone
                            ? const Color(0xFF5B7CFF)
                            : const Color(0xFF9CA3AF),
                        foregroundColor: Colors.white,
                      ),
                      child: _phoneLoading
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(kUseFakePhoneAuth
                          ? 'Continue'
                          : 'Get verification code'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _emailMode = !_emailMode),
              child: Text(
                  _emailMode ? 'or continue with Phone' : 'or continue with Email'),
            ),

            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?  "),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => RegisterPage(role: widget.role)),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                        color: Color(0xFF5B7CFF), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
