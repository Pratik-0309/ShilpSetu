import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/buyer/buyer_profile_details_screen.dart';
import 'package:frontend/screens/artisan/profile_completion_screen.dart';

Widget _buildProfileTestWidget({
  required UserModel userModel,
  LanguageProvider? languageProvider,
}) {
  final authProvider = AppAuthProvider();
  authProvider.updateUserModel(userModel);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppAuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => languageProvider ?? LanguageProvider(),
      ),
    ],
    child: const MaterialApp(
      home: ProfileScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'TEST 1: BUYER role shows Buyer Profile Details, Help & Support, NO Artisan Story, NO Helpline, NO Bank Account, and 60% completion',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lang = LanguageProvider();
    await lang.setLanguage('en', updateFirestore: false);

    // Test Buyer with 3 fields filled: name, email, phone (3/5 = 60%)
    const buyerUser = UserModel(
      uid: 'buyer_test_123',
      name: 'Priya Sharma',
      email: 'priya.sharma@example.com',
      role: 'buyer',
      phone: '+91 9876543210',
      deliveryAddress: '',
      businessName: '',
    );

    await tester.pumpWidget(_buildProfileTestWidget(
      userModel: buyerUser,
      languageProvider: lang,
    ));
    await tester.pumpAndSettle();

    // 1. Check Identity card displays Buyer info
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text(lang.getText('role_buyer_label')), findsOneWidget);
    expect(find.text('priya.sharma@example.com'), findsOneWidget);

    // 2. Check Profile Completion percentage is 60%
    expect(find.textContaining('60%'), findsWidgets);
    expect(find.text('${lang.getText('profile_completion_banner')} 60%'), findsOneWidget);

    // 3. Confirm BUYER menu items are shown
    expect(find.text(lang.getText('buyer_profile_title')), findsOneWidget);
    expect(find.text(lang.getText('app_language_heading')), findsOneWidget);
    expect(find.text(lang.getText('help_support_title')), findsOneWidget);

    // 4. Confirm ARTISAN menu items are NOT shown
    expect(find.text(lang.getText('profile_completion_title')), findsNothing); // Artisan Profile Details
    expect(find.text(lang.getText('artisan_story_title')), findsNothing);       // Artisan Story
    expect(find.text(lang.getText('helpline_title')), findsNothing);            // Artisan Helpline
    expect(find.text(lang.getText('bank_account_title')), findsNothing);        // Bank Account & Payouts

    // 5. Tap "Buyer Profile Details" -> navigates to BuyerProfileDetailsScreen
    await tester.tap(find.text(lang.getText('buyer_profile_title')));
    await tester.pumpAndSettle();

    expect(find.byType(BuyerProfileDetailsScreen), findsOneWidget);
    expect(find.text('Priya Sharma'), findsWidgets);
    expect(find.text('+91 9876543210'), findsOneWidget);
  });

  testWidgets(
      'TEST 2: BUYER with delivery address and business name shows 100% completion',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lang = LanguageProvider();
    await lang.setLanguage('en', updateFirestore: false);

    // Buyer with all 5 fields filled: name, email, phone, address, business (5/5 = 100%)
    const completeBuyer = UserModel(
      uid: 'buyer_test_complete',
      name: 'Amit Patel',
      email: 'amit.patel@craftstore.in',
      role: 'buyer',
      phone: '+91 9123456780',
      deliveryAddress: '42 Commercial Street, Bangalore, Karnataka 560001',
      businessName: 'Patel Handicrafts Store',
    );

    await tester.pumpWidget(_buildProfileTestWidget(
      userModel: completeBuyer,
      languageProvider: lang,
    ));
    await tester.pumpAndSettle();

    // Check 100% completion badge
    expect(find.textContaining('100%'), findsWidgets);
    expect(find.text(lang.getText('profile_complete_ready')), findsOneWidget);
  });

  testWidgets(
      'TEST 3: ARTISAN role shows Artisan Profile Details, Bank Account, Story, Helpline, and navigates to ProfileCompletionScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lang = LanguageProvider();
    await lang.setLanguage('en', updateFirestore: false);

    // Artisan with 4 fields filled: name, phone, dob, gender (4/10 = 40%)
    const artisanUser = UserModel(
      uid: 'artisan_test_789',
      name: 'Radha Devi',
      email: 'radha@example.com',
      role: 'artisan',
      phone: '+91 9876543210',
      dateOfBirth: '1985-05-12',
      gender: 'Female',
      maritalStatus: '',
      experienceYears: 0,
      profilePhotoUrl: '',
      coverPhotoUrl: '',
      artisanStory: '',
    );

    await tester.pumpWidget(_buildProfileTestWidget(
      userModel: artisanUser,
      languageProvider: lang,
    ));
    await tester.pumpAndSettle();

    // 1. Check Identity card displays Artisan role
    expect(find.text('Radha Devi'), findsOneWidget);
    expect(find.text(lang.getText('role_artisan_label')), findsOneWidget);

    // 2. Check 40% completion
    expect(find.textContaining('40%'), findsWidgets);

    // 3. Confirm ARTISAN menu items are shown
    expect(find.text(lang.getText('profile_completion_title')), findsOneWidget); // Artisan Profile Details
    expect(find.text(lang.getText('app_language_heading')), findsOneWidget);
    expect(find.text(lang.getText('bank_account_title')), findsOneWidget);
    expect(find.text(lang.getText('artisan_story_title')), findsWidgets);
    expect(find.text(lang.getText('helpline_title')), findsOneWidget);

    // 4. Confirm BUYER menu items are NOT shown
    expect(find.text(lang.getText('buyer_profile_title')), findsNothing);
    expect(find.text(lang.getText('help_support_title')), findsNothing);

    // 5. Tap Profile Completion card -> navigates to ProfileCompletionScreen
    await tester.tap(find.text('${lang.getText('profile_completion_banner')} 40%'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileCompletionScreen), findsOneWidget);
  });
}
