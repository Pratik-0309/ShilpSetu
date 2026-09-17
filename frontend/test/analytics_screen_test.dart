import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:frontend/screens/analytics/analytics_screen.dart';

Widget _buildTestableWidget(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets('AnalyticsScreen renders genuine zero state for new artisan', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pass a brand new test artisan id
    await tester.pumpWidget(_buildTestableWidget(
      const AnalyticsScreen(artisanId: 'brand_new_artisan_zero_data'),
    ));

    // Wait for async load
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('📊 Artisan Business Analytics'), findsOneWidget);

    // Verify Revenue and AOV both show genuine ₹0 (2 widgets: header banner + AOV card)
    expect(find.text('₹0'), findsNWidgets(2));

    // Verify No data yet badge
    expect(find.text('No data yet'), findsOneWidget);

    // Verify KPI grid cards
    expect(find.text('0 orders'), findsOneWidget);
    expect(find.text('0 delivered'), findsOneWidget);
    expect(find.text('per transaction'), findsOneWidget);
    expect(find.text('No sales yet'), findsOneWidget);
    expect(find.text('0 units sold'), findsOneWidget);
    expect(find.text('Not rated yet'), findsWidgets);

    // Verify empty state for chart: "Start selling to see your trend"
    expect(find.text('Start selling to see your trend'), findsOneWidget);
    expect(find.text('Your monthly sales and revenue chart will appear here as orders arrive.'), findsOneWidget);

    // Verify pipeline status shows 0 for all counts
    expect(find.text('Live Pipeline Status'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
  });
}
