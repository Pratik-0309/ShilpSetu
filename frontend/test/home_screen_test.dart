import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:frontend/providers/navigation_provider.dart';
import 'package:frontend/providers/product_provider.dart';
import 'package:frontend/screens/home_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/user_model.dart';

Widget _buildTestWidget(Widget child, {
  LanguageProvider? languageProvider,
  AppAuthProvider? authProvider,
  NavigationProvider? navigationProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => navigationProvider ?? NavigationProvider()),
      ChangeNotifierProvider(create: (_) => authProvider ?? AppAuthProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => languageProvider ?? LanguageProvider()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 1600)),
        child: child,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen renders all 8 sections and respects LanguageProvider', (tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final lang = LanguageProvider();
    await tester.pumpWidget(_buildTestWidget(const HomeScreen(), languageProvider: lang));
    await tester.pump();

    // 1. Header
    expect(find.text(lang.getText('app_title')), findsOneWidget);
    expect(find.text(lang.getText('app_tagline')), findsOneWidget);

    // 2. Greeting
    expect(find.textContaining(lang.getText('home_greeting_prefix')), findsOneWidget);
    expect(find.text(lang.getText('home_overview_subtitle')), findsOneWidget);

    // 3. Carousel
    expect(find.text(lang.getText('banner_sell_title')), findsOneWidget);

    // 4. Three Stat Cards
    expect(find.text(lang.getText('stat_products_listed')), findsOneWidget);
    expect(find.text(lang.getText('stat_orders_to_pack')), findsOneWidget);
    expect(find.text(lang.getText('stat_earnings_month')), findsOneWidget);

    // 5. Quick Actions
    expect(find.text(lang.getText('quick_actions_title')), findsOneWidget);
    expect(find.text(lang.getText('qa_add_craft_title')), findsOneWidget);
    expect(find.text(lang.getText('qa_orders_title')), findsOneWidget);
    expect(find.text(lang.getText('qa_analytics_title')), findsOneWidget);
    expect(find.text(lang.getText('qa_cluster_title')), findsOneWidget);

    // 6. AI Business Guide
    expect(find.text(lang.getText('ai_guide_title')), findsOneWidget);
    expect(find.text(lang.getText('ai_guide_btn')), findsOneWidget);

    // 7. Recent Orders Header
    expect(find.text(lang.getText('recent_orders_title')), findsOneWidget);

    // 8. Top Products Header
    expect(find.text(lang.getText('top_products_title')), findsOneWidget);

    // Test Language Switch to English
    await lang.setLanguage('en', updateFirestore: false);
    await tester.pump();

    expect(find.text('HunarSathi'), findsOneWidget);
    expect(find.text('Tradition • Craft • Tomorrow'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('AI Business Guide'), findsOneWidget);
    expect(find.text('Ask AI'), findsOneWidget);
    expect(find.text('Recent Orders'), findsOneWidget);
    expect(find.text('Top Products'), findsOneWidget);
  });

  group('Header Avatar Profile Picture Tests', () {
    testWidgets('(a) User with profile image renders Image.network with BoxFit.cover and navigates on tap', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final nav = NavigationProvider();
      final auth = AppAuthProvider();
      auth.updateUserModel(const UserModel(
        uid: 'user_artisan_img',
        name: 'Radha Devi',
        email: 'radha@example.com',
        role: 'artisan',
        profilePhotoUrl: 'https://images.unsplash.com/photo-radha.jpg',
      ));

      await tester.pumpWidget(_buildTestWidget(
        const HomeScreen(),
        authProvider: auth,
        navigationProvider: nav,
      ));
      await tester.pump();

      // Verify Image.network is rendered
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      final imageWidget = tester.widgetList<Image>(imageFinder).firstWhere(
        (img) {
          final provider = img.image;
          if (provider is NetworkImage) {
            return provider.url.contains('photo-radha.jpg');
          }
          if (provider is ResizeImage && provider.imageProvider is NetworkImage) {
            return (provider.imageProvider as NetworkImage).url.contains('photo-radha.jpg');
          }
          return false;
        },
      );
      expect(imageWidget.fit, BoxFit.cover);
      expect(imageWidget.width, 34.0);
      expect(imageWidget.height, 34.0);

      // Verify ClipOval is used to enclose the image into a circle
      expect(find.byType(ClipOval), findsWidgets);

      // Verify tapping avatar changes NavigationProvider index to 3 (Profile)
      final avatarInkWell = find.ancestor(
        of: find.byType(ClipOval),
        matching: find.byType(InkWell),
      );
      expect(avatarInkWell, findsOneWidget);
      await tester.tap(avatarInkWell);
      await tester.pump();

      expect(nav.currentIndex, 3);
    });

    testWidgets('(b) User with no profile image falls back to initial avatar letter', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = AppAuthProvider();
      auth.updateUserModel(const UserModel(
        uid: 'user_artisan_no_img',
        name: 'Sunita Sharma',
        email: 'sunita@example.com',
        role: 'artisan',
        profilePhotoUrl: '',
      ));

      await tester.pumpWidget(_buildTestWidget(
        const HomeScreen(),
        authProvider: auth,
      ));
      await tester.pump();

      // Should find initial 'S' for Sunita
      expect(find.text('S'), findsOneWidget);

      // Should not render avatar Image.network for profile
      final matchingNetworkImages = tester.widgetList<Image>(find.byType(Image)).where(
        (img) => img.width == 34.0 && img.height == 34.0,
      );
      expect(matchingNetworkImages, isEmpty);
    });

    testWidgets('(c) User with invalid URL falls back gracefully to initial without crashing', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = AppAuthProvider();
      auth.updateUserModel(const UserModel(
        uid: 'user_artisan_invalid_img',
        name: 'Govind Rao',
        email: 'govind@example.com',
        role: 'artisan',
        profilePhotoUrl: 'not_a_valid_http_url',
      ));

      await tester.pumpWidget(_buildTestWidget(
        const HomeScreen(),
        authProvider: auth,
      ));
      await tester.pump();

      // Should safely fall back to initial 'G' for Govind
      expect(find.text('G'), findsOneWidget);

      // Should not render avatar Image.network
      final matchingNetworkImages = tester.widgetList<Image>(find.byType(Image)).where(
        (img) => img.width == 34.0 && img.height == 34.0,
      );
      expect(matchingNetworkImages, isEmpty);
    });
  });
}
