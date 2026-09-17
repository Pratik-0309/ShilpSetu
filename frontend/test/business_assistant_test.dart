import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/language_provider.dart';
import 'package:frontend/screens/artisan/business_assistant_screen.dart';
import 'package:frontend/services/assistant_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestableWidget(Widget child, {LanguageProvider? languageProvider}) {
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

  group('AssistantService Tests', () {
    test('askAssistant returns structured response in mock mode', () async {
      final service = AssistantService(useMock: true);

      final resHi = await service.askAssistant(
        artisanId: 'artisan_test',
        question: 'दीवाली पर क्या दाम रखें?',
        language: 'hi',
      );

      expect(resHi['success'], true);
      expect(resHi['answer'], contains('नमस्ते शिल्पकार जी!'));
      expect(resHi['context_summary']['categories'], contains('Pottery'));

      final resEn = await service.askAssistant(
        artisanId: 'artisan_test',
        question: 'What pricing should I use?',
        language: 'en',
      );

      expect(resEn['success'], true);
      expect(resEn['answer'], contains('Hello Artisan!'));
    });

    test('transcribeVoice returns mock transcription in mock mode', () async {
      final service = AssistantService(useMock: true);

      final res = await service.transcribeVoice(
        audioBytes: [1, 2, 3, 4, 5],
        language: 'hi',
      );

      expect(res['success'], true);
      expect(res['transcription'], isNotEmpty);
    });
  });

  group('BusinessAssistantScreen Widget Tests', () {
    testWidgets('Renders header, quick prompts, mic button, text field, and send button', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lang = LanguageProvider();
      await lang.setLanguage('hi', updateFirestore: false);
      final mockService = AssistantService(useMock: true);

      await tester.pumpWidget(_buildTestableWidget(
        BusinessAssistantScreen(assistantService: mockService),
        languageProvider: lang,
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header title
      expect(find.text('व्यापार सहायक (AI Counselor)'), findsOneWidget);

      // Verify microphone button exists
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      // Verify send button exists
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Verify text input field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify initial welcome message from assistant
      expect(find.textContaining('नमस्ते शिल्पकार जी!'), findsOneWidget);
    });

    testWidgets('Quick prompt chip can be tapped to trigger message sending', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lang = LanguageProvider();
      await lang.setLanguage('hi', updateFirestore: false);
      final mockService = AssistantService(useMock: true);

      await tester.pumpWidget(_buildTestableWidget(
        BusinessAssistantScreen(assistantService: mockService),
        languageProvider: lang,
      ));
      await tester.pump(const Duration(milliseconds: 300));

      // Find first quick prompt chip
      final promptChip = find.text('🪔 दीवाली पर सही दाम क्या रखें?');
      expect(promptChip, findsOneWidget);

      // Tap prompt chip
      await tester.tap(promptChip);
      await tester.pump(); // Start sending

      // The sent query bubble should now appear in chat
      expect(find.text('🪔 दीवाली पर सही दाम क्या रखें?'), findsWidgets);

      // Fast-forward delay for mock response
      await tester.pump(const Duration(milliseconds: 1500));

      // The assistant's answer should appear
      expect(find.textContaining('शिल्पकार जी'), findsWidgets);
    });
  });
}
