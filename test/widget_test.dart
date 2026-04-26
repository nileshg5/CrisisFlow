// Basic smoke test for CrisisFlow app.

import 'package:flutter_test/flutter_test.dart';
import 'package:crisis_flow/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CrisisFlowApp());
    // If we get here, the app widget tree built successfully.
    expect(find.byType(CrisisFlowApp), findsOneWidget);
  });
}
