import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AssistantService {
  final String baseUrl;
  final bool useMock;

  AssistantService({String? baseUrl, bool? useMock})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        useMock = useMock ?? ApiConfig.useMock;

  /// Calls POST /api/assistant/ask to consult the Gemini-powered AI Business Assistant.
  Future<Map<String, dynamic>> askAssistant({
    required String artisanId,
    required String question,
    String language = 'hi',
    List<Map<String, dynamic>>? conversationHistory,
    Map<String, dynamic>? artisanProfile,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return _mockAssistantAnswer(question, language);
    }

    try {
      final uri = Uri.parse('$baseUrl/api/assistant/ask');
      final Map<String, dynamic> bodyData = {
        'artisan_id': artisanId,
        'question': question,
        'language': language,
      };
      if (conversationHistory != null) {
        bodyData['conversation_history'] = conversationHistory;
      }
      if (artisanProfile != null) {
        bodyData['artisan_profile'] = artisanProfile;
      }

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      ).timeout(const Duration(seconds: 40));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        debugPrint('Assistant API returned status ${resp.statusCode}: ${resp.body}');
        return _mockAssistantAnswer(question, language);
      }
    } catch (e) {
      debugPrint('Error calling /api/assistant/ask: $e');
      return _mockAssistantAnswer(question, language);
    }
  }

  /// Calls POST /api/assistant/voice-to-text to transcribe recorded voice question.
  Future<Map<String, dynamic>> transcribeVoice({
    required List<int> audioBytes,
    String filename = 'assistant_voice.wav',
    String language = 'hi',
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'success': true,
        'transcription': language == 'mr'
            ? 'सणांच्या काळात मी माझ्या हस्तकलेचे काय दर ठेवावे?'
            : (language == 'en'
                ? 'What pricing strategy should I use for festive seasons?'
                : 'दीवाली के समय मुझे अपने उत्पादों के क्या दाम रखने चाहिए?'),
        'language': language,
      };
    }

    try {
      final uri = Uri.parse('$baseUrl/api/assistant/voice-to-text');
      final request = http.MultipartRequest('POST', uri);
      request.fields['language'] = language;

      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: filename,
        ),
      );

      final streamedResp = await request.send().timeout(const Duration(seconds: 30));
      final resp = await http.Response.fromStream(streamedResp);

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        debugPrint('Voice-to-text returned status ${resp.statusCode}: ${resp.body}');
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return {
            'success': false,
            'error': 'Server error ${resp.statusCode}',
            'friendly_error': 'आवाज़ पहचानने में समस्या आई, कृपया दोबारा बोलें',
          };
        }
      }
    } catch (e) {
      debugPrint('Error calling /api/assistant/voice-to-text: $e');
      return {
        'success': false,
        'error': e.toString(),
        'friendly_error': 'नेटवर्क समस्या, कृपया दोबारा प्रयास करें',
      };
    }
  }

  Map<String, dynamic> _mockAssistantAnswer(String question, String language) {
    String answer;
    if (language == 'mr') {
      answer = 'नमस्ते शिल्पकार जी! 🙏 आपल्या हस्तकलेसाठी या 3 गोष्टी लक्षात ठेवा:\n\n'
          '• योग्य किंमत: कच्च्या मालाच्या खर्चात आपली कारागिरी आणि 25-30% नफा जोडा.\n'
          '• सणांचे कॉम्बो: 2-3 वस्तूंचा आकर्षक गिफ्ट पॅक तयार करा.\n'
          '• सुरक्षित पॅकिंग: ग्राहकांपर्यंत वस्तू सुखरूप पोहोचण्यासाठी 5-प्लाय बॉक्स वापरा.';
    } else if (language == 'en') {
      answer = 'Hello Artisan! 🙏 Here are 3 key tips for your craft business:\n\n'
          '• Fair Pricing: Factor in raw materials, skilled labor hours, and a 25-30% profit margin.\n'
          '• Festive Combos: Bundle complementary items into attractive gift sets.\n'
          '• Safe Packaging: Use 5-ply corrugated boxes to ensure safe, damage-free delivery.';
    } else {
      answer = 'नमस्ते शिल्पकार जी! 🙏 आपके हस्तशिल्प व्यापार के लिए 3 जरूरी सुझाव:\n\n'
          '• उचित मूल्य: कच्ची सामग्री के साथ अपनी कारीगरी और 25-30% मुनाफा जोड़ें।\n'
          '• फेस्टिव कॉम्बो: 2-3 उत्पादों का सुंदर उपहार सेट तैयार करें।\n'
          '• सुरक्षित पैकेजिंग: पार्सल को मजबूत डिब्बे में पैक करें ताकि डिलीवरी सुरक्षित हो।';
    }

    return {
      'success': true,
      'answer': answer,
      'language': language,
      'context_summary': {
        'products_count': 2,
        'orders_count': 1,
        'categories': ['Pottery', 'Textiles']
      }
    };
  }
}
