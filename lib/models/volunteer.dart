import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String name;
  final List<String> skills;
  final GeoPoint? location;
  final String address;
  final bool isAvailable;
  final String phone;
  final List<String> languages;
  final double reliabilityScore;

  // ── Legacy fields kept for backward compatibility with mock_data ──
  final int? matchScore;
  final double? distanceKm;

  const Volunteer({
    required this.id,
    required this.name,
    this.skills = const [],
    this.location,
    this.address = '',
    this.isAvailable = true,
    this.phone = '',
    this.languages = const [],
    this.reliabilityScore = 0.0,
    // legacy
    this.matchScore,
    this.distanceKm,
  });

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'skills': skills,
      'location': location,
      'address': address,
      'isAvailable': isAvailable,
      'phone': phone,
      'languages': languages,
      'reliabilityScore': reliabilityScore,
    };
  }

  /// Create a Volunteer from a Firestore document snapshot.
  factory Volunteer.fromMap(String docId, Map<String, dynamic> data) {
    return Volunteer(
      id: docId,
      name: data['name'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      location: data['location'] as GeoPoint?,
      address: data['address'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      phone: data['phone'] ?? '',
      languages: List<String>.from(data['languages'] ?? []),
      reliabilityScore: (data['reliabilityScore'] ?? 0).toDouble(),
    );
  }
}
