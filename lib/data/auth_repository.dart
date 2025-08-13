// lib/data/auth_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_profile.dart';

class AuthRepository {
  static const _kAdminLoggedIn = 'is_admin_logged_in';
  static const _kAdminProfileComplete = 'is_admin_profile_complete';
  static const _kAdminProfile = 'admin_profile_json';

  // --------- generic helpers (role-based) ----------
  Future<void> setLoggedIn({required String role, required bool v}) async {
    final sp = await SharedPreferences.getInstance();
    if (role == 'admin') {
      await sp.setBool(_kAdminLoggedIn, v);
    } else {
      // customer key bana sakte ho future me
      await sp.setBool('is_customer_logged_in', v);
    }
  }

  Future<bool> isLoggedIn(String role) async {
    final sp = await SharedPreferences.getInstance();
    if (role == 'admin') {
      return sp.getBool(_kAdminLoggedIn) ?? false;
    } else {
      return sp.getBool('is_customer_logged_in') ?? false;
    }
  }

  Future<void> setProfileComplete({required String role, required bool v}) async {
    final sp = await SharedPreferences.getInstance();
    if (role == 'admin') {
      await sp.setBool(_kAdminProfileComplete, v);
    } else {
      await sp.setBool('is_customer_profile_complete', v);
    }
  }

  Future<bool> isProfileComplete(String role) async {
    final sp = await SharedPreferences.getInstance();
    if (role == 'admin') {
      return sp.getBool(_kAdminProfileComplete) ?? false;
    } else {
      return sp.getBool('is_customer_profile_complete') ?? false;
    }
  }

  // --------- admin profile ----------
  Future<void> saveAdminProfile(AdminProfile p) async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(p.toMap());
    await sp.setString(_kAdminProfile, jsonStr);
  }

  Future<AdminProfile?> getAdminProfile() async {
    final sp = await SharedPreferences.getInstance();
    final jsonStr = sp.getString(_kAdminProfile);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AdminProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  // convenience: clear admin data (logout)
  Future<void> clearAdmin() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAdminLoggedIn);
    await sp.remove(_kAdminProfileComplete);
    await sp.remove(_kAdminProfile);
  }
}
