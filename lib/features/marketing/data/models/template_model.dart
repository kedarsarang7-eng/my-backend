/// Template Category
enum TemplateCategory {
  paymentReminder,
  promotion,
  greeting,
  announcement,
  custom,
}

/// Message Template Model
class TemplateModel {
  final String id;
  final String userId;
  final String name;
  final TemplateCategory category;
  final String content; // With placeholders like {{customer_name}}
  final String? imageUrl;
  final String language;
  final int usageCount;
  final bool isActive;
  final bool isSystemTemplate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const TemplateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.content,
    this.imageUrl,
    this.language = 'en',
    this.usageCount = 0,
    this.isActive = true,
    this.isSystemTemplate = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });
}

/// Predefined system templates
class SystemTemplates {
  static const List<Map<String, dynamic>> templates = [
    {
      'name': 'Payment Reminder',
      'category': 'paymentReminder',
      'content': '''नमस्ते {{customer_name}},

आपके {{shop_name}} से ₹{{amount}} का भुगतान बाकी है।

कृपया जल्द से जल्द भुगतान करें।

धन्यवाद!''',
      'language': 'hi',
    },
    {
      'name': 'Payment Reminder (English)',
      'category': 'paymentReminder',
      'content': '''Hi {{customer_name}},

This is a reminder that you have an outstanding balance of ₹{{amount}} at {{shop_name}}.

Please make the payment at your earliest convenience.

Thank you!''',
      'language': 'en',
    },
    {
      'name': 'Festival Greeting',
      'category': 'greeting',
      'content': '''🎉 शुभकामनाएं {{customer_name}}!

{{shop_name}} की ओर से आपको और आपके परिवार को ढेर सारी शुभकामनाएं!

हमारे साथ जुड़े रहने के लिए धन्यवाद।''',
      'language': 'hi',
    },
    {
      'name': 'New Arrival',
      'category': 'promotion',
      'content': '''🆕 नई आवक!

{{customer_name}}, {{shop_name}} में नए प्रोडक्ट्स आ गए हैं!

अभी विज़िट करें और 10% डिस्काउंट पाएं।

ऑफर सीमित समय के लिए!''',
      'language': 'hi',
    },
    {
      'name': 'Thank You',
      'category': 'custom',
      'content': '''धन्यवाद {{customer_name}}!

{{shop_name}} से खरीदारी के लिए शुक्रिया।

आपका भुगतान ₹{{amount}} प्राप्त हो गया है।

फिर मिलते हैं!''',
      'language': 'hi',
    },
  ];
}
