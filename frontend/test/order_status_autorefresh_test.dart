import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:frontend/screens/orders_screen.dart';

Widget _buildTestWidget(Widget child, {LanguageProvider? languageProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ChangeNotifierProvider(create: (_) => languageProvider ?? LanguageProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'TEST 1: On "All" tab, tapping Mark Delivered updates badge immediately without reload; switching to Shipped tab excludes it',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lang = LanguageProvider();
    await lang.setLanguage('en', updateFirestore: false);

    final initialOrders = [
      const OrderModel(
        id: 'ord_shipped_123',
        productId: 'prod_1',
        buyerId: 'buyer_1',
        artisanId: 'artisan_1',
        quantity: 2,
        totalPrice: 700.0,
        status: 'shipped',
        productTitle: 'Madhubani Handcrafted Painting',
        buyerName: 'Ramesh Kumar',
        deliveryAddress: 'New Delhi, India',
      ),
    ];

    // Mount screen with initial shipped order and mock status update success
    await tester.pumpWidget(_buildTestWidget(
      OrdersScreen(
        initialOrders: initialOrders,
        onCustomUpdateStatus: (orderId, newStatus) async => true,
      ),
      languageProvider: lang,
    ));
    await tester.pumpAndSettle();

    // Verify initial state: shows "Mark Delivered" button on the card
    expect(find.widgetWithText(ElevatedButton, '📦 Mark Delivered'), findsOneWidget);
    expect(find.text('Madhubani Handcrafted Painting'), findsOneWidget);

    // Tap "Mark Delivered"
    await tester.tap(find.widgetWithText(ElevatedButton, '📦 Mark Delivered'));
    await tester.pumpAndSettle();

    // 1. On "All" tab: status badge updates to "📦 Delivered" immediately with NO manual refresh
    expect(find.text('📦 Delivered'), findsWidgets);
    // Action button should now be gone because order is delivered
    expect(find.widgetWithText(ElevatedButton, '📦 Mark Delivered'), findsNothing);

    // 2. Switch to the "Shipped" filter ChoiceChip
    await tester.tap(find.widgetWithText(ChoiceChip, lang.getText('order_filter_shipped')));
    await tester.pumpAndSettle();

    // Confirm that the same order is NO LONGER listed under "Shipped" (empty state shows)
    expect(find.text('Madhubani Handcrafted Painting'), findsNothing);
    expect(find.text(lang.getText('order_no_orders')), findsOneWidget);

    // 3. Switch to the "Delivered" filter ChoiceChip
    await tester.tap(find.widgetWithText(ChoiceChip, lang.getText('order_filter_delivered')));
    await tester.pumpAndSettle();

    // Confirm the order is present under "Delivered"
    expect(find.text('Madhubani Handcrafted Painting'), findsOneWidget);
    expect(find.text('📦 Delivered'), findsWidgets);
  });

  testWidgets(
      'TEST 2: On "Shipped" tab directly, tapping Mark Delivered immediately removes order from view',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lang = LanguageProvider();
    await lang.setLanguage('en', updateFirestore: false);

    final initialOrders = [
      const OrderModel(
        id: 'ord_shipped_456',
        productId: 'prod_2',
        buyerId: 'buyer_2',
        artisanId: 'artisan_1',
        quantity: 1,
        totalPrice: 350.0,
        status: 'shipped',
        productTitle: 'Blue Pottery Vase',
        buyerName: 'Sunita Sharma',
      ),
    ];

    await tester.pumpWidget(_buildTestWidget(
      OrdersScreen(
        initialOrders: initialOrders,
        onCustomUpdateStatus: (orderId, newStatus) async => true,
      ),
      languageProvider: lang,
    ));
    await tester.pumpAndSettle();

    // Switch to "Shipped" filter ChoiceChip
    await tester.tap(find.widgetWithText(ChoiceChip, lang.getText('order_filter_shipped')));
    await tester.pumpAndSettle();

    // Verify order is present
    expect(find.text('Blue Pottery Vase'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '📦 Mark Delivered'), findsOneWidget);

    // Tap "Mark Delivered" while filtered by Shipped
    await tester.tap(find.widgetWithText(ElevatedButton, '📦 Mark Delivered'));
    await tester.pumpAndSettle();

    // Order must immediately vanish from the Shipped view without manual refresh
    expect(find.text('Blue Pottery Vase'), findsNothing);
    expect(find.text(lang.getText('order_no_orders')), findsOneWidget);
  });

  testWidgets(
      'TEST 3: Confirm Order and Mark Shipped immediately auto-refresh UI and update filter tabs',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lang = LanguageProvider();
    await lang.setLanguage('en', updateFirestore: false);

    final initialOrders = [
      const OrderModel(
        id: 'ord_pending_789',
        productId: 'prod_3',
        buyerId: 'buyer_3',
        artisanId: 'artisan_1',
        quantity: 1,
        totalPrice: 500.0,
        status: 'pending',
        productTitle: 'Terracotta Lamp',
        buyerName: 'Anil Patel',
      ),
    ];

    await tester.pumpWidget(_buildTestWidget(
      OrdersScreen(
        initialOrders: initialOrders,
        onCustomUpdateStatus: (orderId, newStatus) async => true,
      ),
      languageProvider: lang,
    ));
    await tester.pumpAndSettle();

    // Initially pending action button exists
    expect(find.widgetWithText(ElevatedButton, '✅ Confirm'), findsOneWidget);

    // Tap "Confirm"
    await tester.tap(find.widgetWithText(ElevatedButton, '✅ Confirm'));
    await tester.pumpAndSettle();

    // Status immediately updates to "Confirmed" and action button advances to "🚚 Mark In-Transit"
    expect(find.widgetWithText(ElevatedButton, '🚚 Mark In-Transit'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '✅ Confirm'), findsNothing);

    // Tap "Mark In-Transit"
    await tester.tap(find.widgetWithText(ElevatedButton, '🚚 Mark In-Transit'));
    await tester.pumpAndSettle();

    // Status immediately updates to "Shipped" and action button advances to "📦 Mark Delivered"
    expect(find.widgetWithText(ElevatedButton, '📦 Mark Delivered'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '🚚 Mark In-Transit'), findsNothing);
  });
}
