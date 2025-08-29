// lib/features/auth/phone_auth_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_verify_page.dart';

class PhoneAuthPage extends StatefulWidget {
  final String role;
  const PhoneAuthPage({super.key, required this.role});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _valid = false;
  bool _sending = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() => _valid = digits.length == 10);
  }

  Future<void> _sendOtp() async {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 10) return;
    final phoneE164 = '+91$digits';

    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneE164,

        verificationCompleted: (PhoneAuthCredential credential) async {
        },

        verificationFailed: (FirebaseAuthException e) {
          debugPrint('PHONE-AUTH ERROR: code=${e.code}, message=${e.message}');

          String msg;
          switch (e.code) {
            case 'invalid-phone-number':
              msg = 'Please enter a valid 10-digit phone number.';
              break;
            case 'quota-exceeded':
              msg = 'Daily SMS quota reached. Try again later.';
              break;
            case 'app-not-authorized':
            case 'missing-client-identifier':
            case 'invalid-app-credential':
            case 'play-integrity-check-failed':
              msg = 'App configuration issue (Play Integrity). Please try again.';
              break;
            case 'network-request-failed':
              msg = 'Network issue. Check your internet and try again.';
              break;
            default:
              msg = 'Verification failed. ${e.message ?? ""}'.trim();
          }

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));

          setState(() => _sending = false);
        },



        codeSent: (String verificationId, int? resendToken) {
          setState(() => _sending = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerifyPage(
                role: widget.role,
                phone: phoneE164,
                verificationId: verificationId,
                loginFlow: false,
              ),
            ),
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
        },

        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
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
              height: h * 0.32,
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
                  Image.asset('assets/images/app logo-1.jpg', height: 72, fit: BoxFit.contain),
                  const SizedBox(height: 8),
                  const Text(
                    'StayEasy PG',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Transform.translate(
                offset: const Offset(0, -36),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          'Continue with Phone',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.role == 'admin'
                              ? 'Admin verification via mobile number'
                              : 'Enter your mobile number to get OTP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                              child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: 'Enter 10-digit phone number',
                                  filled: true,
                                  fillColor: Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    borderSide: BorderSide(color: Color(0xFF5B7CFF), width: 1.4),
                                  ),
                                ),
                                onChanged: _onChanged,
                                validator: (v) {
                                  final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                  if (d.length != 10) return 'Enter a valid 10-digit number';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              backgroundColor: _valid && !_sending ? const Color(0xFF5B7CFF) : const Color(0xFF9CA3AF),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: (_valid && !_sending)
                                ? () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _sendOtp();
                              }
                            }
                                : null,
                            child: Text(_sending ? 'Sending...' : 'Get verification code',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
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
