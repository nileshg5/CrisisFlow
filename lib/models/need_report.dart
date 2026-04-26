import 'package:cloud_firestore/cloud_firestore.dart';

class NeedReport {
  final String id;
  final String title;
  final String description;
  final String needType;       // maps to old 'category'
  final double urgencyScore;
  final String urgencyLabel;
  final int affectedCount;
  final GeoPoint? geoLocation; // Firebase GeoPoint for map queries
  final String location;       // human-readable address / sector name (legacy-compatible)
  final String status;
  final DateTime? reportedAt;
  final List<String> geminiTags;
  final String reportedBy;
  final String? imageUrl;

  // ── Legacy fields kept for backward compatibility with mock_data ──
  final String? crisisId;
  final String? category;
  final String? timeAgo;
  final List<String> assignedInitials;
  final String? actionLabel;
  final String? notes;
  final String? aiReason;
  final String? reporterName;
  final int? reportedMinutesAgo;

  const NeedReport({
    required this.id,
    required this.title,
    this.description = '',
    this.needType = '',
    this.urgencyScore = 0.0,
    this.urgencyLabel = 'Normal',
    this.affectedCount = 0,
    this.geoLocation,
    this.location = '',
    this.status = 'pending',
    this.reportedAt,
    this.geminiTags = const [],
    this.reportedBy = '',
    this.imageUrl,
    // legacy
    this.crisisId,
    this.category,
    this.timeAgo,
    this.assignedInitials = const [],
    this.actionLabel,
    this.notes,
    this.aiReason,
    this.reporterName,
    this.reportedMinutesAgo,
  });

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'needType': needType,
      'urgencyScore': urgencyScore,
      'urgencyLabel': urgencyLabel,
      'affectedCount': affectedCount,
      'geoLocation': geoLocation,
      'location': location,
      'status': status,
      'reportedAt': reportedAt != null
          ? Timestamp.fromDate(reportedAt!)
          : FieldValue.serverTimestamp(),
      'geminiTags': geminiTags,
      'reportedBy': reportedBy,
      'imageUrl': imageUrl,
    };
  }

  /// Create a NeedReport from a Firestore document snapshot.
  factory NeedReport.fromMap(String docId, Map<String, dynamic> data) {
    return NeedReport(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      needType: data['needType'] ?? '',
      urgencyScore: (data['urgencyScore'] ?? 0).toDouble(),
      urgencyLabel: data['urgencyLabel'] ?? 'Normal',
      affectedCount: data['affectedCount'] ?? 0,
      geoLocation: data['geoLocation'] as GeoPoint?,
      location: data['location'] ?? '',
      status: data['status'] ?? 'pending',
      reportedAt: data['reportedAt'] != null
          ? (data['reportedAt'] as Timestamp).toDate()
          : null,
      geminiTags: List<String>.from(data['geminiTags'] ?? []),
      reportedBy: data['reportedBy'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }
}
