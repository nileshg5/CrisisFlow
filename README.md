# crisis_flow

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase setup for live CrisisFlow data

1. Create a Firebase project and add a Flutter app.
2. Enable **Authentication -> Sign-in method -> Anonymous**.
3. Create **Firestore Database** (Native mode).
4. Publish `firestore.rules` from this repo:
   ```bash
   firebase deploy --only firestore:rules
   ```
5. Ensure the app uses your generated `lib/firebase_options.dart` (from FlutterFire CLI).

### Firestore collections used

- `needs`
- `volunteers`
- `tasks`

The app reads these collections in real time via Firestore snapshots.

## Voice transcription setup (Whisper server)

1. Install Python dependencies:
   ```bash
   pip install -r requirements-whisper.txt
   ```
2. Start the server from project root:
   ```bash
   python whisper_server.py
   ```
3. Keep it running while using **Voice Input** tab.

### Endpoint notes

- Web/Desktop: `http://localhost:8000`
- Android emulator: `http://10.0.2.2:8000`
