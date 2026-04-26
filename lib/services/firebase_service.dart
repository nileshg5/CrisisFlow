import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/need_report.dart';
import '../models/volunteer.dart';
import '../models/task_assignment.dart';

/// Singleton service for all Firestore operations.
///
/// Usage:
///   final service = FirebaseService.instance;
///   service.watchNeeds().listen((needs) { ... });
class FirebaseService {
  // ── Singleton ──
  FirebaseService._internal();
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;

  // ── Collection references ──
  final CollectionReference _needsRef =
      FirebaseFirestore.instance.collection('needs');
  final CollectionReference _volunteersRef =
      FirebaseFirestore.instance.collection('volunteers');
  final CollectionReference _tasksRef =
      FirebaseFirestore.instance.collection('tasks');

  // ─────────────────────────────────────────────
  //  NEEDS
  // ─────────────────────────────────────────────

  /// Real‑time stream of all need reports, ordered by urgency (highest first).
  Stream<List<NeedReport>> watchNeeds() {
    return _needsRef
        .orderBy('urgencyScore', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NeedReport.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// Add a new need report to Firestore.
  Future<void> addNeed(NeedReport need) async {
    try {
      await _needsRef.doc(need.id).set(need.toMap());
    } catch (e) {
      throw Exception('Failed to add need report: $e');
    }
  }

  /// Update just the status field of an existing need.
  Future<void> updateNeedStatus(String id, String status) async {
    try {
      await _needsRef.doc(id).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update need status: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  VOLUNTEERS
  // ─────────────────────────────────────────────

  /// Real‑time stream of all volunteers, ordered by reliability.
  Stream<List<Volunteer>> watchVolunteers() {
    return _volunteersRef
        .orderBy('reliabilityScore', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Volunteer.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// Add (or overwrite) a volunteer document.
  Future<void> addVolunteer(Volunteer v) async {
    try {
      await _volunteersRef.doc(v.id).set(v.toMap());
    } catch (e) {
      throw Exception('Failed to add volunteer: $e');
    }
  }

  // ─────────────────────────────────────────────
  //  TASK ASSIGNMENTS
  // ─────────────────────────────────────────────

  /// Assign a task — writes to the 'tasks' collection.
  Future<void> assignTask(TaskAssignment task) async {
    try {
      await _tasksRef.doc(task.id).set(task.toMap());
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  /// Real-time stream of all task assignments ordered by assignment time.
  Stream<List<TaskAssignment>> watchTasks() {
    return _tasksRef.orderBy('assignedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return TaskAssignment.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  /// Update the status of a task and write completedAt when completed.
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _tasksRef.doc(taskId).update({
        'status': status,
        'completedAt': status == 'completed'
            ? FieldValue.serverTimestamp()
            : null,
      });
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  /// Update volunteer availability.
  Future<void> updateVolunteerAvailability(
    String volunteerId,
    bool isAvailable,
  ) async {
    try {
      await _volunteersRef.doc(volunteerId).update({'isAvailable': isAvailable});
    } catch (e) {
      throw Exception('Failed to update volunteer availability: $e');
    }
  }

  /// Real‑time stream of tasks for a specific volunteer.
  Stream<List<TaskAssignment>> watchTasksForVolunteer(String volunteerId) {
    return _tasksRef
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskAssignment.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }
}
