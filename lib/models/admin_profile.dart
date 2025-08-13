// lib/models/admin_profile.dart
import 'package:flutter/foundation.dart';

@immutable
class AdminProfile {
  final String name;
  final String email;
  final String phone;   // OTP वाले flow से आया हुआ
  final String gender;  // 'Male' | 'Female'
  final String city;

  const AdminProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.gender,
    required this.city,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> m) => AdminProfile(
    name: m['name'] as String,
    email: m['email'] as String,
    phone: m['phone'] as String,
    gender: m['gender'] as String,
    city: m['city'] as String,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'gender': gender,
    'city': city,
  };
}
