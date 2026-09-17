import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/widgets/delivery_address_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createTestWidget({
    required UserModel user,
    Widget? child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppAuthProvider>(
          create: (_) {
            final auth = AppAuthProvider();
            auth.updateUserModel(user);
            return auth;
          },
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child ??
              DeliveryAddressSheet(
                productId: 'p_101',
                productTitle: 'Handcrafted Madhubani Painting',
                artisanId: 'artisan_456',
                quantity: 2,
                totalPrice: 2400.0,
                initialUser: user,
              ),
        ),
      ),
    );
  }

  testWidgets('DeliveryAddressSheet renders all 7 fields and pre-fills from profile', (WidgetTester tester) async {
    const userWithProfile = UserModel(
      uid: 'buyer_123',
      name: 'Priya Sharma',
      email: 'priya@example.com',
      role: 'buyer',
      phone: '9876543210',
      deliveryAddressMap: {
        'name': 'Priya Sharma',
        'phone': '9876543210',
        'line1': 'Flat 402, Lotus Apartments',
        'line2': 'Near City Mall, MG Road',
        'city': 'Jaipur',
        'state': 'Rajasthan',
        'pincode': '302001',
      },
    );

    await tester.pumpWidget(createTestWidget(user: userWithProfile));
    await tester.pumpAndSettle();

    // Verify Title & Summary
    expect(find.text('Delivery Address'), findsOneWidget);
    expect(find.text('Handcrafted Madhubani Painting'), findsOneWidget);
    expect(find.text('Qty: 2 units'), findsOneWidget);
    expect(find.text('₹2400'), findsOneWidget);

    // Verify Field Pre-fills
    expect(find.text('Priya Sharma'), findsWidgets);
    expect(find.text('9876543210'), findsWidgets);
    expect(find.text('Flat 402, Lotus Apartments'), findsOneWidget);
    expect(find.text('Near City Mall, MG Road'), findsOneWidget);
    expect(find.text('Jaipur'), findsOneWidget);
    expect(find.text('Rajasthan'), findsOneWidget);
    expect(find.text('302001'), findsOneWidget);

    // Verify Proceed to Payment Button
    expect(find.text('Proceed to Payment'), findsOneWidget);
  });

  testWidgets('DeliveryAddressSheet validates required fields (phone 10 digits, pincode 6 digits)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const blankUser = UserModel(
      uid: 'buyer_empty',
      name: '',
      email: 'empty@example.com',
      role: 'buyer',
    );

    await tester.pumpWidget(createTestWidget(user: blankUser));
    await tester.pumpAndSettle();

    // Tap submit without entering anything
    final submitBtn = find.text('Proceed to Payment');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Expect validation errors
    expect(find.text('Please enter recipient name'), findsOneWidget);
    expect(find.text('Please enter phone number'), findsOneWidget);
    expect(find.text('Please enter street address'), findsOneWidget);
    expect(find.text('Enter city'), findsOneWidget);
    expect(find.text('Enter state'), findsOneWidget);
    expect(find.text('Enter PIN code'), findsOneWidget);

    // Enter invalid phone (< 10 digits)
    final phoneField = find.byType(TextFormField).at(1);
    await tester.enterText(phoneField, '12345');

    // Enter invalid pincode (< 6 digits)
    final pincodeField = find.byType(TextFormField).at(6);
    await tester.enterText(pincodeField, '123');

    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid 10-digit phone number'), findsOneWidget);
    expect(find.text('Enter valid 6-digit PIN code'), findsOneWidget);
  });
}
