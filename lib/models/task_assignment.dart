import 'package:cloud_firestore/cloud_firestore.dart';

class TaskAssignment {
  final String id;
  final String needId;
  final String volunteerId;
  final String status;         // pending | in_progress | scheduled | completed
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String notes;

  // ── Legacy fields kept for backward compatibility with mock_data ──
  final String? ref;
  final String? title;
  final String? urgency;
  final String? location;
  final String? deadline;
  final String? instructions;
  final String? dropOffPoint;
  final String? etaDeadline;
  final String? contactName;
  final String? contactRole;
  final List<String> checklist;
  final List<String> hazards;

  const TaskAssignment({
    required this.id,
    this.needId = '',
    this.volunteerId = '',
    this.status = 'pending',
    this.assignedAt,
    this.completedAt,
    this.notes = '',
    // legacy
    this.ref,
    this.title,
    this.urgency,
    this.location,
    this.deadline,
    this.instructions,
    this.dropOffPoint,
    this.etaDeadline,
    this.contactName,
    this.contactRole,
    this.checklist = const [],
    this.hazards = const [],
  });

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'needId': needId,
      'volunteerId': volunteerId,
      'status': status,
      'assignedAt': assignedAt != null
          ? Timestamp.fromDate(assignedAt!)
          : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'notes': notes,
    };
  }

  /// Create a TaskAssignment from a Firestore document snapshot.
  factory TaskAssignment.fromMap(String docId, Map<String, dynamic> data) {
    return TaskAssignment(
      id: docId,
      needId: data['needId'] ?? '',
      volunteerId: data['volunteerId'] ?? '',
      status: data['status'] ?? 'pending',
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] ?? '',
    );
  }
}
