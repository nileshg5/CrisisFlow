# CrisisFlow – Project Overview & Report

## 1️⃣ High‑Level Goal
> **CrisisFlow** is a **Flutter prototype** that demonstrates a full‑stack‑like UI for disaster‑response coordination.  It supports two user roles (Coordinator & Volunteer) and showcases multiple data‑intake methods (photo‑OCR, CSV, Google Forms, SMS, voice input). All data is currently mocked for rapid UI development, but the architecture is ready for a real backend (Firebase, Vision API, etc.).

---

## 2️⃣ Directory & File Map
```
CrisisFlow‑main/
├─ lib/
│  ├─ core/
│  │  ├─ theme.dart                ← Central colour & typography system (dark‑mode, Google Fonts)
│  │  └─ mock_data.dart           ← Hard‑coded sample data for needs, volunteers, tasks, intake mocks
│  ├─ models/
│  │  ├─ need_report.dart
│  │  ├─ task_assignment.dart
│  │  └─ volunteer.dart
│  ├─ widgets/
│  │  ├─ shared/
│  │  │  ├─ side_nav.dart        ← **Side navigation widget** (active‑route highlighting, snackbar for unimplemented routes)
│  │  │  ├─ top_nav.dart         ← Horizontal top bar with title, tabs, search, icons
│  │  │  ├─ glass_card.dart      ← Glass‑morphism container used throughout the UI
│  │  │  ├─ status_chip.dart
│  │  │  └─ urgency_badge.dart
│  │  └─ intake/
│  │     ├─ tab_photo_ocr.dart
│  │     ├─ tab_csv_upload.dart
│  │     ├─ tab_google_forms.dart
│  │     ├─ tab_sms_gateway.dart
│  │     └─ tab_voice_input.dart
│  ├─ screens/
│  │  ├─ coordinator/
│  │  │  ├─ dashboard_screen.dart
│  │  │  ├─ intake_hub_screen.dart   ← Uses the four intake tabs
│  │  │  ├─ assignments_board_screen.dart
│  │  │  └─ team_manager_screen.dart
│  │  └─ volunteer/
│  │     ├─ volunteer_home_screen.dart
│  │     ├─ task_detail_screen.dart   ← Start button now shows “IN PROGRESS” when active
│  │     └─ login_screen.dart
│  ├─ router.dart                 ← GoRouter route definitions for all screens
│  └─ main.dart                   ← Entry point, applies AppTheme and GoRouter
├─ pubspec.yaml                    ← Dependencies (go_router, google_fonts, flutter_animate, etc.)
└─ README / other project‑root files (unchanged)
```

---

## 3️⃣ What the Repository Provides
| Layer | Files | Responsibility |
|------|-------|----------------|
| **Entry** | `main.dart` | Boots the `MaterialApp` with `AppTheme` (dark mode) and injects the `GoRouter`. |
| **Routing** | `router.dart` | Declarative navigation map (`/coordinator/*`, `/volunteer/*`, `/login`). |
| **Core** | `theme.dart` & `mock_data.dart` | Global design tokens + in‑memory sample data used by every screen. |
| **Models** | `need_report.dart`, `task_assignment.dart`, `volunteer.dart` | Plain data‑class definitions mirroring the mock data. |
| **Screens** | Coordinator & Volunteer screen files | Full‑page UI for each role (dashboard, intake hub, assignments board, team manager, volunteer home, task detail, login). |
| **Shared Widgets** | `side_nav.dart`, `top_nav.dart`, `glass_card.dart`, `status_chip.dart`, `urgency_badge.dart` | Re‑usable UI components providing navigation, glass‑morphism cards, status chips, urgency badges. |
| **Intake Widgets** | Four tab files (`tab_*`) | Simulate different data‑capture pipelines (photo‑OCR, CSV upload, Google Forms sync, SMS ingestion, voice input). |

---

## 4️⃣ Detailed Look – `SideNav` (`lib/widgets/shared/side_nav.dart`)
```dart
class SideNav extends StatelessWidget {
  final String activeRoute;                 // Current route supplied by parent
  const SideNav({required this.activeRoute});

  static const _mainItems = [
    {'icon': Icons.dashboard_outlined,   'label': 'Dashboard',    'route': '/coordinator/dashboard'},
    {'icon': Icons.input_outlined,      'label': 'Intake Hub',   'route': '/coordinator/intake'},
    {'icon': Icons.view_kanban_outlined,'label': 'Assignments',  'route': '/coordinator/assignments'},
    {'icon': Icons.group_outlined,      'label': 'Team Manager', 'route': '/coordinator/team'},
  ];

  Widget _navItem(BuildContext ctx,
      {required IconData icon, required String label,
       required String route, bool isFooter = false}) {
    final bool isActive = activeRoute == route;   // highlight logic
    return InkWell(
      onTap: () {
        if (!isActive) {
          if (route.startsWith('/coordinator') ||
              route.startsWith('/volunteer')) {
            ctx.go(route);                     // real navigation
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 32, right: 32, left: 32),
                backgroundColor: AppColors.surface,
                content: Text('$label — coming soon',
                    style: AppTextStyles.technical()),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
        border: isActive ? Border.all(color: Colors.white.withOpacity(0.12)) : null,
        // ...icon + label + optional active indicator dot
      ),
    );
  }
  // …build() creates the column of navigation items and the footer
}
```
* **Purpose** – Provides a consistent vertical navigation UI for both roles. 
* **Active‑state handling** – Highlights the route that matches `activeRoute`. 
* **User feedback** – For future/placeholder routes, a small SnackBar appears: *“X — coming soon”*. 
* **Extensible** – Add new items to `_mainItems` or footer items and the UI adapts automatically. 

---

## 5️⃣ How to Run the Project
1. **Generate missing platform folders** (run once):
   ```powershell
   cd "C:\Users\NILESH\Documents\solution challenge\CrisisFlow-main"
   flutter create . --project-name crisis_flow   # creates android/, ios/, windows/, web/
   ```
2. **Install dependencies**:
   ```powershell
   flutter pub get
   ```
3. **Run in a web browser (Chrome by default)**:
   ```powershell
   flutter run -d chrome
   ```
   *The command compiles Dart → JavaScript, starts a local dev server, and opens Chrome pointing to `http://localhost:<port>/`.*

### Running in **Firefox**
If you prefer Firefox, start a generic web‑server instead of the Chrome driver:
```powershell
flutter run -d web-server
```
Copy the printed URL (e.g., `http://localhost:53012`) and paste it into Firefox.

### Running as a **Windows desktop app** (after step 1):
```powershell
flutter run -d windows
```
A native Windows window will launch, using the same codebase.

---

## 6️⃣ Current State of the Codebase
- **Static analysis**: `flutter analyze` now reports **no warnings or errors**. 
- **Bug fixes applied**: 
  - `TaskDetailScreen` button label now shows **“IN PROGRESS”** after start. 
  - `SideNav` now shows a Snackbar for unimplemented routes. 
  - Unused imports removed (`glass_card.dart`, `intake_hub_screen.dart`). 
  - Deprecated `Color.withOpacity` calls replaced by `Color.withValues(alpha:)` where feasible, eliminating deprecation warnings. 
- **No new files** were created; all modifications were edits to existing source files. 
- **Dependencies**: `percent_indicator` is declared but unused; you may want to prune it later. 

---

## 7️⃣ Next Steps (optional)
1. **Backend integration** – Replace `mock_data.dart` with a real datastore (Firebase/Firestore) and hook up the TODO comments. 
2. **Clean up `pubspec.yaml`** – remove `percent_indicator` and any version constraints that block newer packages. 
3. **Add tests** – unit tests for models and widget tests for `SideNav`, `TaskDetailScreen`, and intake tabs. 
4. **Asset handling** – add image assets (logo, icons) and reference them in `pubspec.yaml`. 
5. **Responsive design** – ensure the UI works on tablets and mobile screens (Flutter’s `LayoutBuilder`/`MediaQuery`). 

---

### 📌 TL;DR for a LLM
- **Purpose**: A dark‑mode, role‑based Flutter prototype for crisis coordination, with mock data and multiple intake pipelines. 
- **Key components**: `main.dart` → `router.dart` → role‑specific screens → shared UI widgets (`SideNav`, `TopNav`, `GlassCard`, badges). 
- **SideNav**: vertical navigation, active‑item highlight, snackbar for future routes. 
- **Running**: generate platforms (`flutter create .`), `flutter pub get`, then `flutter run -d chrome` (or `-d web-server` for Firefox). 
- **Current status**: Clean compile, zero analyzer warnings, ready for backend integration.

---

*Report generated automatically by Antigravity.*
