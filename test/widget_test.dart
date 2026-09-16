import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rentmitra_app/main.dart';
import 'package:rentmitra_app/screens/splash_screen.dart';

void main() {
  testWidgets('App renders the splash screen on launch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RentMitraApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    // The first 200ms is a deliberate plain-white frame (caps how long the
    // near-white native Android launch screen can read as "just white"
    // before the app's own branding takes over) — the logo only mounts
    // once that timer fires.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.image(const AssetImage('assets/images/logo_full.png')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
