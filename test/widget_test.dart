import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Room IoT Monitor Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Karena di awal checkLocalLockStatus() dipanggil secara async, 
    // ia akan memicu CircularProgressIndicator terlebih dahulu (isInitialized = false)
    expect(find.byType(MyApp), findsOneWidget);
  });
}
