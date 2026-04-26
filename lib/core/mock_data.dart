// ─── Mock data ────────────────────────────────────────────────────────────────
// All data below is FRONTEND-ONLY placeholder data.
// TODO(backend): Replace each list/stream with Firestore queries.

import '../models/need_report.dart';
import '../models/volunteer.dart';
import '../models/task_assignment.dart';

// ── Coordinator: priority queue needs ─────────────────────────────────────────
final List<NeedReport> mockNeeds = [
  const NeedReport(
    id: 'N001',
    crisisId: '#4401-X',
    title: 'Oxygen supply depletion at Sector 7 Mobile Clinic',
    category: 'Medical',
    urgencyLabel: 'Critical',
    urgencyScore: 9.8,
    location: 'Sector 7',
    timeAgo: '2m ago',
    status: 'unassigned',
    assignedInitials: ['AR', 'JD'],
    actionLabel: 'DISPATCH',
    notes: 'Evacuation routes Alpha and Charlie are currently submerged. '
        'Redirection to High-Ground Echo is in progress. Communication towers '
        'in the south-west quadrant are offline.',
    aiReason: 'Immediate intervention required. Water levels rising 4.2cm/min. '
        'Multiple civilian structures compromised. Logistical bottleneck '
        'identified in grid A4...',
    reporterName: 'Sgt. Marcus Thorne',
    reportedMinutesAgo: 12,
  ),
  const NeedReport(
    id: 'N002',
    crisisId: '#4402-X',
    title: 'Shelter capacity exceeded: 40 families awaiting relocation',
    category: 'Logistics',
    urgencyLabel: 'High',
    urgencyScore: 7.2,
    location: 'Hub B',
    timeAgo: '14m ago',
    status: 'unassigned',
    assignedInitials: ['SM'],
    actionLabel: 'REASSIGN',
    notes: 'Families are in a temporary holding area. Capacity exceeded by 40%.',
    aiReason: 'Shelter critical — families displaced. Logistical re-routing needed.',
    reporterName: 'Officer Singh',
    reportedMinutesAgo: 14,
  ),
  const NeedReport(
    id: 'N003',
    crisisId: '#4403-X',
    title: 'Water purification tablets request for Hub Delta',
    category: 'Supply',
    urgencyLabel: 'Normal',
    urgencyScore: 4.1,
    location: 'Hub Delta',
    timeAgo: '22m ago',
    status: 'unassigned',
    assignedInitials: [],
    actionLabel: 'BROADCAST',
    notes: 'Running low on purification tablets. Stockpile at 10%.',
    aiReason: 'Supply depletion risk within 6 hours at current usage rate.',
    reporterName: 'Coordinator Rivera',
    reportedMinutesAgo: 22,
  ),
  const NeedReport(
    id: 'N004',
    crisisId: '#4404-X',
    title: 'Secondary generator failure at North Water Tower',
    category: 'Power',
    urgencyLabel: 'High',
    urgencyScore: 6.8,
    location: 'North Tower',
    timeAgo: '28m ago',
    status: 'matched',
    assignedInitials: ['KL'],
    actionLabel: 'MONITOR',
    notes: 'Generator failed during maintenance window. Primary still active.',
    aiReason: 'Single point of failure risk. Needs electrical team within 2 hours.',
    reporterName: 'Tech. Officer Kim',
    reportedMinutesAgo: 28,
  ),
];

// ── Coordinator: recommended volunteers for need detail ────────────────────────
final List<Volunteer> mockVolunteers = [
  const Volunteer(
    id: 'V001',
    name: 'Elena Rodriguez',
    matchScore: 94,
    distanceKm: 1.2,
    skills: ['Trauma Care', 'Flood Rescue'],
  ),
  const Volunteer(
    id: 'V002',
    name: 'David Chen',
    matchScore: 89,
    distanceKm: 0.8,
    skills: ['Logistics', 'Comms'],
  ),
  const Volunteer(
    id: 'V003',
    name: 'Priya Sharma',
    matchScore: 76,
    distanceKm: 3.1,
    skills: ['Medical', 'First Aid'],
  ),
];

// ── Team Manager: full volunteer registry ─────────────────────────────────────
// TODO(backend): Replace with Firestore /volunteers collection
final List<Map<String, dynamic>> mockTeamVolunteers = [
  {
    'id': 'V001',
    'name': 'Elena Rodriguez',
    'role': 'Medical Responder',
    'status': 'available',
    'skills': ['Trauma Care', 'Flood Rescue', 'First Aid'],
    'location': 'Sector 7',
    'distanceKm': 1.2,
    'tasksCompleted': 34,
    'matchScore': 94,
    'languages': ['English', 'Spanish'],
    'hasVehicle': true,
    'rating': 4.9,
  },
  {
    'id': 'V002',
    'name': 'David Chen',
    'role': 'Logistics Coordinator',
    'status': 'on_assignment',
    'skills': ['Logistics', 'Comms', 'Driving'],
    'location': 'Hub B',
    'distanceKm': 0.8,
    'tasksCompleted': 28,
    'matchScore': 89,
    'languages': ['English', 'Mandarin'],
    'hasVehicle': true,
    'rating': 4.7,
  },
  {
    'id': 'V003',
    'name': 'Priya Sharma',
    'role': 'Field Medic',
    'status': 'available',
    'skills': ['Medical', 'First Aid', 'Counseling'],
    'location': 'Hub Delta',
    'distanceKm': 3.1,
    'tasksCompleted': 51,
    'matchScore': 76,
    'languages': ['English', 'Hindi', 'Marathi'],
    'hasVehicle': false,
    'rating': 4.8,
  },
  {
    'id': 'V004',
    'name': 'James Okonkwo',
    'role': 'Search & Rescue',
    'status': 'on_leave',
    'skills': ['Rescue', 'Swimming', 'Construction'],
    'location': 'Sector 3',
    'distanceKm': 5.4,
    'tasksCompleted': 19,
    'matchScore': 72,
    'languages': ['English', 'Yoruba'],
    'hasVehicle': false,
    'rating': 4.5,
  },
  {
    'id': 'V005',
    'name': 'Amara Nwosu',
    'role': 'Supply Distribution',
    'status': 'available',
    'skills': ['Food Handling', 'Driving', 'Logistics'],
    'location': 'North Tower',
    'distanceKm': 2.7,
    'tasksCompleted': 42,
    'matchScore': 81,
    'languages': ['English', 'Igbo'],
    'hasVehicle': true,
    'rating': 4.6,
  },
  {
    'id': 'V006',
    'name': 'Rajan Mehta',
    'role': 'Communications',
    'status': 'on_assignment',
    'skills': ['Comms', 'Tech Support', 'Ham Radio'],
    'location': 'HQ',
    'distanceKm': 0.3,
    'tasksCompleted': 67,
    'matchScore': 88,
    'languages': ['English', 'Hindi', 'Gujarati'],
    'hasVehicle': false,
    'rating': 4.9,
  },
];

// ── Kanban: need assignments board ────────────────────────────────────────────
// TODO(backend): Replace with Firestore /assignments collection realtime stream
final List<Map<String, dynamic>> mockKanbanCards = [
  {
    'id': 'K001',
    'title': 'Oxygen Supply — Sector 7',
    'category': 'Medical',
    'urgency': 'Critical',
    'assignee': 'Elena Rodriguez',
    'stage': 'unassigned',
    'timeAgo': '2m',
  },
  {
    'id': 'K002',
    'title': 'Shelter Relocation — Hub B',
    'category': 'Logistics',
    'urgency': 'High',
    'assignee': 'David Chen',
    'stage': 'notified',
    'timeAgo': '14m',
  },
  {
    'id': 'K003',
    'title': 'Supply Delivery — 42nd District',
    'category': 'Supply',
    'urgency': 'Normal',
    'assignee': 'Amara Nwosu',
    'stage': 'accepted',
    'timeAgo': '35m',
  },
  {
    'id': 'K004',
    'title': 'Generator Repair — North Tower',
    'category': 'Power',
    'urgency': 'High',
    'assignee': 'Rajan Mehta',
    'stage': 'in_progress',
    'timeAgo': '28m',
  },
  {
    'id': 'K005',
    'title': 'Water Tablets — Hub Delta',
    'category': 'Supply',
    'urgency': 'Normal',
    'assignee': 'Priya Sharma',
    'stage': 'completed',
    'timeAgo': '1h',
  },
  {
    'id': 'K006',
    'title': 'Medical Kit Delivery — Kurla',
    'category': 'Medical',
    'urgency': 'High',
    'assignee': 'James Okonkwo',
    'stage': 'completed',
    'timeAgo': '2h',
  },
];

// ── Volunteer: task assignments ────────────────────────────────────────────────
final List<TaskAssignment> mockTasks = [
  const TaskAssignment(
    id: 'T001',
    ref: 'OPS-992-DELTA',
    title: 'Emergency Supply Delivery',
    urgency: 'Critical',
    location: '42nd District, Hub A',
    deadline: 'Due in 15m',
    status: 'pending',
    instructions: 'Transport emergency medical kits and potable water to the makeshift '
        'triage center at the Southside Community Hub. Use the secondary access road via 5th Avenue.',
    dropOffPoint: '842 Southside Ave, Unit 4B',
    etaDeadline: '14:30 PM (45 mins remaining)',
    contactName: 'Marcus Chen',
    contactRole: 'Logistics Coordinator',
    checklist: ['Medical Kit (Type A) x 12', 'Potable Water Containers x 20', 'Emergency Ration Packs x 50'],
    hazards: ['Road closures on Main St. Avoid due to debris.',
      'Expected precipitation in 2 hours. Ensure cargo is covered.'],
  ),
  const TaskAssignment(
    id: 'T002',
    ref: '845-RX',
    title: 'Resource Inventory Check',
    urgency: 'Medium',
    location: 'Central Logistics Center',
    deadline: 'Ongoing',
    status: 'in_progress',
    instructions: 'Conduct a full inventory of medical and food supplies at the Central Logistics Center.',
    dropOffPoint: 'Central Logistics Center, Bay 3',
    etaDeadline: 'End of day',
    contactName: 'Sarah Kim',
    contactRole: 'Supply Officer',
    checklist: ['Count medical kits', 'Count food rations', 'Update spreadsheet'],
    hazards: ['Heavy forklift traffic in Bay 2. Wear hi-vis vest.'],
  ),
  const TaskAssignment(
    id: 'T003',
    ref: '721-BX',
    title: 'Communication Link Test',
    urgency: 'Low',
    location: 'Remote Station 4',
    deadline: 'Today, 18:00',
    status: 'scheduled',
    instructions: 'Test all communication channels at Remote Station 4.',
    dropOffPoint: 'Remote Station 4, Grid F9',
    etaDeadline: '18:00 PM',
    contactName: 'Officer Patel',
    contactRole: 'Comms Coordinator',
    checklist: ['Test radio channel A', 'Test radio channel B', 'File test report'],
    hazards: ['Access road unpaved — 4WD vehicle recommended.'],
  ),
];

// ── Dashboard stats ────────────────────────────────────────────────────────────
// TODO(backend): Replace with Firestore aggregated queries
const mockStats = {
  'needsResolved': 1284,
  'activeVolunteers': 452,
  'matchRate': 94,
  'trendText': '+12% from last cycle',
};

// ── Resource allocation bars ───────────────────────────────────────────────────
// TODO(backend): Replace with real-time resource tracking data
const mockResources = [
  {'label': 'MEDICAL_UNITS',   'value': 0.82, 'color': 'white'},
  {'label': 'FOOD_&_WATER',    'value': 0.45, 'color': 'amber'},
  {'label': 'SHELTER_ASSETS',  'value': 0.68, 'color': 'white'},
  {'label': 'COMM_NODES',      'value': 0.91, 'color': 'green'},
];

// ── Intake: OCR mock result ────────────────────────────────────────────────────
// TODO(backend): Replace with Vision API Cloud Function response
const mockOcrResult = {
  'location':      '40.7128° N, 74.0060° W [VALIDATED]',
  'timestamp':     '2023-10-24T14:32:00Z',
  'incidentType':  'Structural Instability',
  'casualtyCount': '03 [CONFIRMED]',
  'confidence':    94,
  'tags':          ['#SITREP', '#Zone7', '#Urgent', '#BridgeA'],
};

// ── Intake: SMS mock messages ──────────────────────────────────────────────────
// TODO(backend): Replace with Twilio/WhatsApp Business webhook stream
const mockSmsMessages = [
  {
    'phone': '+91-98XXXXXXXX',
    'timeAgo': '2 min ago',
    'message': 'NEED:medical,location:Dharavi,count:40,notes:insulin shortage elderly',
  },
  {
    'phone': '+91-87XXXXXXXX',
    'timeAgo': '15 min ago',
    'message': 'NEED:food,location:Govandi,count:80,urgent:yes',
  },
  {
    'phone': '+91-76XXXXXXXX',
    'timeAgo': '32 min ago',
    'message': 'NEED:water,location:Kurla,count:25,notes:pipe broke near school',
  },
];

// ── Intake: Google Forms mock responses ───────────────────────────────────────
// TODO(backend): Replace with Sheets API call using OAuth token
const mockFormsResponses = [
  {'timestamp': 'Apr 22  2:30 PM', 'location': 'Dharavi',  'need': 'Medical', 'count': 40,  'isNew': true},
  {'timestamp': 'Apr 22  1:10 PM', 'location': 'Govandi',  'need': 'Food',    'count': 80,  'isNew': true},
  {'timestamp': 'Apr 21  5:00 PM', 'location': 'Kurla',    'need': 'Water',   'count': 25,  'isNew': false},
  {'timestamp': 'Apr 21  2:00 PM', 'location': 'Andheri',  'need': 'Shelter', 'count': 12,  'isNew': false},
];

// ── Intake: CSV column mapping ─────────────────────────────────────────────────
// TODO(backend): Replace with actual uploaded CSV headers
const mockCsvHeaders = ['Date', 'Region', 'Issue Type', 'No. of People', 'Reporter', 'Severity', 'Notes'];
const mockCsvMapping = {
  'Date':          'timestamp',
  'Region':        'location',
  'Issue Type':    'need_type',
  'No. of People': 'affected_count',
  'Reporter':      'reporter_name',
  'Severity':      'urgency_level',
  'Notes':         'raw_notes',
};

// ── Intake: Recent intake history ─────────────────────────────────────────────
const mockIntakeHistory = [
  {'icon': 'description', 'file': 'REPORT_0921.jpg',         'detail': '2 mins ago • OCR Success'},
  {'icon': 'table_chart', 'file': 'LOGISTICS_EXPORT_V2.csv', 'detail': '1 hour ago • Mapping Auto'},
];

// ── Volunteer impact stats ─────────────────────────────────────────────────────
// TODO(backend): Replace with Firestore aggregated stats for currentUser
const mockVolunteerStats = {
  'tasksCompleted': 124,
  'trendPercent':   12,
  'peopleHelped':   892,
  'hoursContributed': 340,
  'activeHotspots': 3,
};
