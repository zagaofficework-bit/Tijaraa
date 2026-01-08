import 'dart:convert';

import 'package:flutter/services.dart';

/// A structured response containing the bot's text and a list of suggestions.
class BotResponse {
  final String text;
  final List<String> suggestions;

  BotResponse({required this.text, this.suggestions = const []});
}

class TijaraaBotService {
  // Singleton Pattern
  static final TijaraaBotService _instance = TijaraaBotService._internal();
  factory TijaraaBotService() => _instance;
  TijaraaBotService._internal();

  Map<String, dynamic>? _botData;

  /// Keywords used to detect broad categories if a specific question isn't matched.
  final Map<String, List<String>> _categoryKeywords = {
    'account': [
      'account',
      'login',
      'otp',
      'sign up',
      'अकाउंट',
      'लॉगिन',
      'تسجيل',
    ],
    'kyc': ['kyc', 'verify', 'document', 'identity', 'केवाईसी', 'توثيق'],
    'ads': ['post', 'ad', 'sell', 'listing', 'views', 'ऐड', 'إعلان'],
    'chat': ['chat', 'call', 'message', 'negotiate', 'चैट', 'دردشة'],
    'payments': ['payment', 'delivery', 'scam', 'refund', 'पेमेंट', 'توصيل'],
    'search': ['search', 'near me', 'location', 'city', 'सर्च', 'بحث'],
    'premium': ['boost', 'featured', 'package', 'promote', 'बूस्ट', 'تمويل'],
    'technical': ['crash', 'error', 'slow', 'notification', 'तकनीकी', 'مشكلة'],
  };

  /// Loads the JSON data from assets.
  Future<void> loadBotData() async {
    if (_botData != null) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/tijaraa_model.json',
      );
      _botData = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print("🤖 TijaraaBot Error: $e");
    }
  }

  BotResponse getReply(String userMessage) {
    if (_botData == null || _botData!['responses'] == null) {
      return BotResponse(text: "🤖 Just a moment, I'm getting ready...");
    }

    final text = userMessage.toLowerCase().trim();
    final lang = _detectLanguage(text);
    final responses = _botData!['responses'] as Map<String, dynamic>;

    // 1. First, check for simple greetings if the user just says "hi" or "hello"
    if (text == "hi" ||
        text == "hello" ||
        text == "hey" ||
        text == "नमस्ते" ||
        text == "مرحبا") {
      return BotResponse(
        text: lang == 'hi'
            ? "नमस्ते! मैं तिजारा बॉट हूँ। मैं आपकी कैसे मदद कर सकता हूँ?"
            : lang == 'ar'
            ? "مرحباً! أنا بوت تيجارا. كيف يمكنني مساعدتك؟"
            : "Hello! I am the Tijaraa Bot. How can I help you today?",
        suggestions: ["Post an Ad", "KYC Help", "Create Account"],
      );
    }

    // 2. Search keyword_intents (Phase 1)
    final intents = responses['keyword_intents'] as Map<String, dynamic>? ?? {};
    String? bestIntentKey;
    int bestScore = 0;
    List<String>? bestPath;

    intents.forEach((key, value) {
      if (value is Map && value.containsKey('keywords')) {
        final List keywords = value['keywords'];
        for (final k in keywords) {
          String keyword = k.toString().toLowerCase().trim();
          if (text.contains(keyword)) {
            // Priority: Longer keyword matches get higher scores
            if (keyword.length > bestScore) {
              bestScore = keyword.length;
              bestIntentKey = key;
              bestPath = List<String>.from(value['reply_path'] ?? []);
            }
          }
        }
      }
    });

    if (bestPath != null) {
      final replyText = _resolvePath(bestPath!, lang);
      final category = bestPath!.length > 2 ? bestPath![2] : null;
      return BotResponse(
        text: replyText,
        suggestions: _getSuggestions(category, bestIntentKey, lang),
      );
    }

    // 3. Category detection (Phase 2)
    String? detectedCategory = _detectCategory(text);
    if (detectedCategory != null) {
      return BotResponse(
        text: _getCategorySummary(detectedCategory, lang),
        suggestions: _getSuggestions(detectedCategory, null, lang),
      );
    }

    // 4. Fallback (Phase 3)
    return BotResponse(text: _fallback(lang));
  }

  // ================= HELPERS =================

  /// Detects category based on broad keywords.
  String? _detectCategory(String text) {
    for (var entry in _categoryKeywords.entries) {
      if (entry.value.any((k) => text.contains(k))) return entry.key;
    }
    return null;
  }

  /// Provides a category-specific introductory text.
  String _getCategorySummary(String categoryKey, String lang) {
    switch (categoryKey) {
      case 'account':
        return lang == 'hi'
            ? "🔐 अकाउंट संबंधी सवाल? नीचे दिए गए विकल्प चुनें:"
            : "🔐 Account questions? Pick a topic below:";
      case 'kyc':
        return lang == 'hi'
            ? "🆔 KYC और सुरक्षा के लिए ये जानकारी देखें:"
            : "🆔 For KYC and Safety, check these:";
      case 'ads':
        return lang == 'hi'
            ? "📢 ऐड मैनेजमेंट के लिए ये सुझाव हैं:"
            : "📢 Here is help for Managing Ads:";
      case 'payments':
        return lang == 'hi'
            ? "💰 पेमेंट और डिलीवरी संबंधी जानकारी:"
            : "💰 Payment and Delivery info:";
      default:
        return _fallback(lang);
    }
  }

  /// Generates clickable suggestion titles from the JSON.
  List<String> _getSuggestions(
    String? category,
    String? excludeKey,
    String lang,
  ) {
    if (category == null || _botData == null) return [];
    try {
      final faqGroup =
          _botData!['responses']['faq_multilingual'][category]
              as Map<String, dynamic>?;
      if (faqGroup == null) return [];

      // Find up to 3 other questions in this category
      return faqGroup.keys
          .where((qId) => qId != excludeKey)
          .take(3)
          .map((qId) => _getHumanReadableTitle(qId, lang))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Maps internal Q-IDs to user-friendly titles for suggestions.
  String _getHumanReadableTitle(String qId, String lang) {
    final titles = {
      'q1': {'en': 'Create Account', 'hi': 'नया अकाउंट', 'ar': 'إنشاء حساب'},
      'q2': {'en': 'OTP Issues', 'hi': 'OTP समस्या', 'ar': 'مشكلة الكود'},
      'q7': {
        'en': 'What is KYC?',
        'hi': 'KYC क्या है?',
        'ar': 'ما هو التوثيق؟',
      },
      'q8': {'en': 'Start KYC', 'hi': 'KYC कैसे करें', 'ar': 'بدء التوثيق'},
      'q12': {'en': 'Safety Tips', 'hi': 'सुरक्षा टिप्स', 'ar': 'نصائح الأمان'},
      'q13': {'en': 'Post an Ad', 'hi': 'ऐड कैसे डालें', 'ar': 'نشر إعلان'},
      'q15': {
        'en': 'Rejected Ads',
        'hi': 'ऐड रिजेक्ट क्यों?',
        'ar': 'رفض الإعلان',
      },
      'q23': {'en': 'Delivery', 'hi': 'डिलीवरी', 'ar': 'التوصيل'},
      'q25': {'en': 'Avoid Scams', 'hi': 'ठगी से बचें', 'ar': 'تجنب الاحتيال'},
      'q31': {'en': 'Boost Ads', 'hi': 'ऐड बूस्ट करें', 'ar': 'تميز الإعلان'},
    };
    return titles[qId]?[lang] ?? titles[qId]?['en'] ?? "Learn More";
  }

  /// Safe navigation for JSON paths.
  String _resolvePath(List<String> path, String lang) {
    try {
      dynamic current = _botData;
      for (final key in path) {
        current = current[key];
      }
      if (current is Map) {
        return current[lang]?.toString() ??
            current['en']?.toString() ??
            "Translation error.";
      }
      return current?.toString() ?? "Data error.";
    } catch (_) {
      return _fallback(lang);
    }
  }

  String _detectLanguage(String text) {
    for (final rune in text.runes) {
      if (rune >= 0x0600 && rune <= 0x06FF) return 'ar';
      if (rune >= 0x0900 && rune <= 0x097F) return 'hi';
    }
    return 'en';
  }

  String _fallback(String lang) {
    switch (lang) {
      case 'hi':
        return "🤖 मैं अभी सीख रहा हूँ। आप अकाउंट, KYC या ऐड के बारे में पूछ सकते हैं।";
      case 'ar':
        return "🤖 أنا ما زلت أتعلم. يمكنك سؤالي عن الحساب، التوثيق، أو الإعلانات.";
      default:
        return "🤖 I'm still learning. You can ask me about Accounts, KYC, or Posting Ads.";
    }
  }
}
