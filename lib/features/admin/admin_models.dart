// lib/features/admin/admin_models.dart
import 'package:flutter/foundation.dart';

@immutable
class AdminPg {
  final String id;
  final String name;
  final String city;
  final String area;
  final String address;
  final String genderTag;
  final int minPrice;
  final bool hidden;
  final List<String> images;
  final List<String> amenities;
  final List<String> services;

  const AdminPg({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.address,
    required this.genderTag,
    required this.minPrice,
    required this.hidden,
    required this.images,
    this.amenities = const [],
    this.services = const [],
  });

  AdminPg copyWith({
    String? id,
    String? name,
    String? city,
    String? area,
    String? address,
    String? genderTag,
    int? minPrice,
    bool? hidden,
    List<String>? images,
    List<String>? amenities,
    List<String>? services,
  }) {
    return AdminPg(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      area: area ?? this.area,
      address: address ?? this.address,
      genderTag: genderTag ?? this.genderTag,
      minPrice: minPrice ?? this.minPrice,
      hidden: hidden ?? this.hidden,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      services: services ?? this.services,
    );
  }
}
