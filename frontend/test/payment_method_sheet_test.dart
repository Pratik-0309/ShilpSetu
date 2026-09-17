import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/widgets/payment_method_sheet.dart';
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
              PaymentMethodSheet(
                productId: 'p_101',
                productTitle: 'Handcrafted Terracotta Vase',
                artisanId: 'artisan_789',
                quantity: 1,
                totalPrice: 1250.0,
                deliveryAddress: const {
                  'name': 'Aarav Patel',
                  'phone': '9876543210',
                  'city': 'Ahmedabad',
                  'pincode': '380001',
                },
                buyerUser: user,
              ),
        ),
      ),
    );
  }

  testWidgets('PaymentMethodSheet renders COD order confirmation and places order via COD', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const buyer = UserModel(
      uid: 'buyer_test',
      name: 'Aarav Patel',
      email: 'aarav@example.com',
      role: 'buyer',
    );

    await tester.pumpWidget(createTestWidget(user: buyer));
    await tester.pumpAndSettle();

    // Verify Title & Amount
    expect(find.text('Payment Method'), findsWidgets);
    expect(find.text('100% Secure Checkout'), findsOneWidget);
    expect(find.text('Total Amount to Pay'), findsOneWidget);
    expect(find.text('₹1250'), findsOneWidget);

    // Verify Address & Quantity summary
    expect(find.text('1 unit'), findsOneWidget);
    expect(find.text('Aarav Patel, Ahmedabad, 380001'), findsOneWidget);

    // Verify Cash on Delivery card & badges
    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(find.text('Pay with cash when the artisan\'s package arrives at your doorstep.'), findsOneWidget);
    expect(find.text('Zero Advance Payment'), findsOneWidget);
    expect(find.text('Pay at Doorstep'), findsOneWidget);

    // Verify online gateway options are completely absent
    expect(find.text('Pay Online via UPI'), findsNothing);
    expect(find.text('GPay'), findsNothing);
    expect(find.text('PhonePe'), findsNothing);
    expect(find.text('Paytm'), findsNothing);
    expect(find.text('BHIM'), findsNothing);
    expect(find.text('Stripe Secure'), findsNothing);

    // Verify primary action button is directly Confirm & Place Order (COD)
    expect(find.text('Confirm & Place Order (COD)'), findsOneWidget);
  });
}
