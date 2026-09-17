import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/screens/buyer/buyer_orders_screen.dart';

void main() {
  testWidgets('Order Tracking Timeline renders stages and timestamps properly', (WidgetTester tester) async {
    // 1. Order in 'placed' state
    final placedOrder = OrderModel(
      id: 'order_1',
      buyerId: 'b_1',
      artisanId: 'a_1',
      productId: 'p_1',
      productTitle: 'Handcrafted Clay Pot',
      quantity: 1,
      totalPrice: 450.0,
      status: 'pending',
      createdAt: '2026-09-10T10:00:00.000Z',
      updatedAt: '2026-09-10T10:00:00.000Z',
      statusHistory: [
        StatusHistoryEntry(status: 'placed', timestamp: '2026-09-10T10:00:00.000Z'),
      ],
    );

    // 2. Order in 'shipped' state
    final shippedOrder = OrderModel(
      id: 'order_2',
      buyerId: 'b_1',
      artisanId: 'a_1',
      productId: 'p_2',
      productTitle: 'Brass Diya',
      quantity: 2,
      totalPrice: 1200.0,
      status: 'shipped',
      createdAt: '2026-09-08T09:00:00.000Z',
      updatedAt: '2026-09-09T14:30:00.000Z',
      statusHistory: [
        StatusHistoryEntry(status: 'placed', timestamp: '2026-09-08T09:00:00.000Z'),
        StatusHistoryEntry(status: 'packed', timestamp: '2026-09-08T16:00:00.000Z'),
        StatusHistoryEntry(status: 'shipped', timestamp: '2026-09-09T14:30:00.000Z'),
      ],
    );

    // 3. Cancelled order
    final cancelledOrder = OrderModel(
      id: 'order_3',
      buyerId: 'b_1',
      artisanId: 'a_1',
      productId: 'p_3',
      productTitle: 'Silk Stole',
      quantity: 1,
      totalPrice: 1500.0,
      status: 'cancelled',
      createdAt: '2026-09-07T08:00:00.000Z',
      updatedAt: '2026-09-07T09:00:00.000Z',
      statusHistory: [
        StatusHistoryEntry(status: 'placed', timestamp: '2026-09-07T08:00:00.000Z'),
        StatusHistoryEntry(status: 'cancelled', timestamp: '2026-09-07T09:00:00.000Z'),
      ],
    );

    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BuyerOrdersScreen(
          initialOrders: [placedOrder, shippedOrder, cancelledOrder],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 5 stages labels exist for the active orders
    expect(find.text('Order Placed'), findsWidgets);
    expect(find.text('Packed'), findsWidgets);
    expect(find.text('Shipped'), findsWidgets);
    expect(find.text('Out for Delivery'), findsWidgets);
    expect(find.text('Delivered'), findsWidgets);

    // Check timestamps exist for placed and shipped stages (containing 'Sep')
    expect(find.textContaining('Sep'), findsWidgets);

    // Check cancelled banner
    expect(find.text('Order Cancelled'), findsOneWidget);
    expect(find.textContaining('Cancelled on'), findsOneWidget);
  });
}
