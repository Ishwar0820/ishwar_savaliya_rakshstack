// lib/features/auth/login_page.dart
import 'package:flutter/material.dart';
import 'otp_verify_page.dart';
import '../home/home_page.dart';
import '../admin/admin_dashboard.dart';
import 'register_page.dart';

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

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _loginEmail() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: Firebase check later
    if (widget.role == 'admin') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  void _loginPhoneOtp() {
    final d = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length != 10) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerifyPage(
          role: widget.role,
          phone: '+91$d',
          loginFlow: true, // login → direct home/dashboard
        ),
      ),
    );
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
                        final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(s);
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
                        onPressed: _loginEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          backgroundColor: const Color(0xFF5B7CFF),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Log In'),
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
                        child: const Text('+91',
                            style: TextStyle(fontWeight: FontWeight.w600)),
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
                          // 🔧 FIX: typing par UI rebuild → button enable/disable live
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _validPhone ? _loginPhoneOtp : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: _validPhone
                            ? const Color(0xFF5B7CFF)
                            : const Color(0xFF9CA3AF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Get verification code'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () =>
                  setState(() => _emailMode = !_emailMode), // rebuilds
              child: Text(_emailMode
                  ? 'or continue with Phone'
                  : 'or continue with Email'),
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
                      color: Color(0xFF5B7CFF),
                      fontWeight: FontWeight.w700,
                    ),
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
