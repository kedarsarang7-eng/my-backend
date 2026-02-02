// Amount to Words Converter - Multi-Language Support
// Converts numeric amounts to words in Indian numbering system (Lakh/Crore)
//
// Created: 2024-12-26
// Author: DukanX Team

import '../../../services/invoice_pdf_service.dart' show InvoiceLanguage;

/// Multi-language amount to words converter
/// Supports Indian numbering system (Lakh, Crore) for all languages
class AmountToWords {
  /// Convert amount to words in specified language
  static String convert(double amount, InvoiceLanguage language) {
    switch (language) {
      case InvoiceLanguage.hindi:
        return _convertToHindi(amount);
      case InvoiceLanguage.marathi:
        return _convertToMarathi(amount);
      default:
        return _convertToEnglish(amount);
    }
  }

  // ========== ENGLISH CONVERSION ==========

  static String _convertToEnglish(double amount) {
    if (amount == 0) return 'Rupees Zero Only';

    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String result = 'Rupees ${_numberToWordsEnglish(rupees)}';
    if (paise > 0) {
      result += ' and ${_numberToWordsEnglish(paise)} Paise';
    }
    result += ' Only';

    return result;
  }

  static String _numberToWordsEnglish(int number) {
    if (number == 0) return 'Zero';

    const ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 20) {
      return ones[number];
    }
    if (number < 100) {
      return '${tens[number ~/ 10]}${number % 10 > 0 ? ' ${ones[number % 10]}' : ''}';
    }
    if (number < 1000) {
      return '${ones[number ~/ 100]} Hundred${number % 100 > 0 ? ' ${_numberToWordsEnglish(number % 100)}' : ''}';
    }
    if (number < 100000) {
      return '${_numberToWordsEnglish(number ~/ 1000)} Thousand${number % 1000 > 0 ? ' ${_numberToWordsEnglish(number % 1000)}' : ''}';
    }
    if (number < 10000000) {
      return '${_numberToWordsEnglish(number ~/ 100000)} Lakh${number % 100000 > 0 ? ' ${_numberToWordsEnglish(number % 100000)}' : ''}';
    }
    return '${_numberToWordsEnglish(number ~/ 10000000)} Crore${number % 10000000 > 0 ? ' ${_numberToWordsEnglish(number % 10000000)}' : ''}';
  }

  // ========== HINDI CONVERSION ==========

  static String _convertToHindi(double amount) {
    if (amount == 0) return 'रुपये शून्य मात्र';

    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String result = 'रुपये ${_numberToWordsHindi(rupees)}';
    if (paise > 0) {
      result += ' और ${_numberToWordsHindi(paise)} पैसे';
    }
    result += ' मात्र';

    return result;
  }

  static String _numberToWordsHindi(int number) {
    if (number == 0) return 'शून्य';

    const ones = [
      '',
      'एक',
      'दो',
      'तीन',
      'चार',
      'पांच',
      'छह',
      'सात',
      'आठ',
      'नौ',
      'दस',
      'ग्यारह',
      'बारह',
      'तेरह',
      'चौदह',
      'पंद्रह',
      'सोलह',
      'सत्रह',
      'अठारह',
      'उन्नीस',
    ];
    const tens = [
      '',
      '',
      'बीस',
      'तीस',
      'चालीस',
      'पचास',
      'साठ',
      'सत्तर',
      'अस्सी',
      'नब्बे',
    ];
    // Special numbers 21-99 in Hindi have unique names for some combinations
    const tensOnesHindi = <int, String>{
      21: 'इक्कीस',
      22: 'बाईस',
      23: 'तेईस',
      24: 'चौबीस',
      25: 'पच्चीस',
      26: 'छब्बीस',
      27: 'सत्ताईस',
      28: 'अट्ठाईस',
      29: 'उनतीस',
      31: 'इकतीस',
      32: 'बत्तीस',
      33: 'तैंतीस',
      34: 'चौंतीस',
      35: 'पैंतीस',
      36: 'छत्तीस',
      37: 'सैंतीस',
      38: 'अड़तीस',
      39: 'उनतालीस',
      41: 'इकतालीस',
      42: 'बयालीस',
      43: 'तैंतालीस',
      44: 'चौवालीस',
      45: 'पैंतालीस',
      46: 'छियालीस',
      47: 'सैंतालीस',
      48: 'अड़तालीस',
      49: 'उनचास',
      51: 'इक्यावन',
      52: 'बावन',
      53: 'तिरपन',
      54: 'चौवन',
      55: 'पचपन',
      56: 'छप्पन',
      57: 'सत्तावन',
      58: 'अट्ठावन',
      59: 'उनसठ',
      61: 'इकसठ',
      62: 'बासठ',
      63: 'तिरसठ',
      64: 'चौंसठ',
      65: 'पैंसठ',
      66: 'छियासठ',
      67: 'सड़सठ',
      68: 'अड़सठ',
      69: 'उनहत्तर',
      71: 'इकहत्तर',
      72: 'बहत्तर',
      73: 'तिहत्तर',
      74: 'चौहत्तर',
      75: 'पचहत्तर',
      76: 'छिहत्तर',
      77: 'सतहत्तर',
      78: 'अठहत्तर',
      79: 'उनासी',
      81: 'इक्यासी',
      82: 'बयासी',
      83: 'तिरासी',
      84: 'चौरासी',
      85: 'पचासी',
      86: 'छियासी',
      87: 'सत्तासी',
      88: 'अट्ठासी',
      89: 'नवासी',
      91: 'इक्यानवे',
      92: 'बानवे',
      93: 'तिरानवे',
      94: 'चौरानवे',
      95: 'पंचानवे',
      96: 'छियानवे',
      97: 'सत्तानवे',
      98: 'अट्ठानवे',
      99: 'निन्यानवे',
    };

    if (number < 20) {
      return ones[number];
    }
    if (number < 100) {
      if (tensOnesHindi.containsKey(number)) {
        return tensOnesHindi[number]!;
      }
      return tens[number ~/ 10];
    }
    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      String result = '';
      if (hundred == 1) {
        result = 'एक सौ';
      } else {
        result = '${ones[hundred]} सौ';
      }
      if (remainder > 0) {
        result += ' ${_numberToWordsHindi(remainder)}';
      }
      return result;
    }
    if (number < 100000) {
      final thousand = number ~/ 1000;
      final remainder = number % 1000;
      String result = '${_numberToWordsHindi(thousand)} हज़ार';
      if (remainder > 0) {
        result += ' ${_numberToWordsHindi(remainder)}';
      }
      return result;
    }
    if (number < 10000000) {
      final lakh = number ~/ 100000;
      final remainder = number % 100000;
      String result = '${_numberToWordsHindi(lakh)} लाख';
      if (remainder > 0) {
        result += ' ${_numberToWordsHindi(remainder)}';
      }
      return result;
    }
    final crore = number ~/ 10000000;
    final remainder = number % 10000000;
    String result = '${_numberToWordsHindi(crore)} करोड़';
    if (remainder > 0) {
      result += ' ${_numberToWordsHindi(remainder)}';
    }
    return result;
  }

  // ========== MARATHI CONVERSION ==========

  static String _convertToMarathi(double amount) {
    if (amount == 0) return 'रुपये शून्य मात्र';

    final rupees = amount.floor();
    final paise = ((amount - rupees) * 100).round();

    String result = 'रुपये ${_numberToWordsMarathi(rupees)}';
    if (paise > 0) {
      result += ' आणि ${_numberToWordsMarathi(paise)} पैसे';
    }
    result += ' मात्र';

    return result;
  }

  static String _numberToWordsMarathi(int number) {
    if (number == 0) return 'शून्य';

    const ones = [
      '',
      'एक',
      'दोन',
      'तीन',
      'चार',
      'पाच',
      'सहा',
      'सात',
      'आठ',
      'नऊ',
      'दहा',
      'अकरा',
      'बारा',
      'तेरा',
      'चौदा',
      'पंधरा',
      'सोळा',
      'सतरा',
      'अठरा',
      'एकोणीस',
    ];
    const tens = [
      '',
      '',
      'वीस',
      'तीस',
      'चाळीस',
      'पन्नास',
      'साठ',
      'सत्तर',
      'ऐंशी',
      'नव्वद',
    ];
    // Special Marathi numbers
    const tensOnesMarathi = <int, String>{
      21: 'एकवीस',
      22: 'बावीस',
      23: 'तेवीस',
      24: 'चोवीस',
      25: 'पंचवीस',
      26: 'सव्वीस',
      27: 'सत्तावीस',
      28: 'अठ्ठावीस',
      29: 'एकोणतीस',
      31: 'एकतीस',
      32: 'बत्तीस',
      33: 'तेहतीस',
      34: 'चौतीस',
      35: 'पस्तीस',
      36: 'छत्तीस',
      37: 'सदतीस',
      38: 'अडतीस',
      39: 'एकोणचाळीस',
      41: 'एक्केचाळीस',
      42: 'बेचाळीस',
      43: 'त्रेचाळीस',
      44: 'चव्वेचाळीस',
      45: 'पंचेचाळीस',
      46: 'सेहेचाळीस',
      47: 'सत्तेचाळीस',
      48: 'अठ्ठेचाळीस',
      49: 'एकोणपन्नास',
      51: 'एक्कावन्न',
      52: 'बावन्न',
      53: 'त्रेपन्न',
      54: 'चोपन्न',
      55: 'पंचावन्न',
      56: 'छप्पन्न',
      57: 'सत्तावन्न',
      58: 'अठ्ठावन्न',
      59: 'एकोणसाठ',
      61: 'एकसष्ट',
      62: 'बासष्ट',
      63: 'त्रेसष्ट',
      64: 'चौसष्ट',
      65: 'पासष्ट',
      66: 'सहासष्ट',
      67: 'सत्तासष्ट',
      68: 'अठ्ठासष्ट',
      69: 'एकोणसत्तर',
      71: 'एक्काहत्तर',
      72: 'बाहात्तर',
      73: 'त्र्याहत्तर',
      74: 'चौऱ्याहत्तर',
      75: 'पंच्याहत्तर',
      76: 'शहात्तर',
      77: 'सत्त्याहत्तर',
      78: 'अठ्ठ्याहत्तर',
      79: 'एकोणऐंशी',
      81: 'एक्क्याऐंशी',
      82: 'ब्याऐंशी',
      83: 'त्र्याऐंशी',
      84: 'चौऱ्याऐंशी',
      85: 'पंच्याऐंशी',
      86: 'शहाऐंशी',
      87: 'सत्त्याऐंशी',
      88: 'अठ्ठ्याऐंशी',
      89: 'एकोणनव्वद',
      91: 'एक्क्याण्णव',
      92: 'ब्याण्णव',
      93: 'त्र्याण्णव',
      94: 'चौऱ्याण्णव',
      95: 'पंच्याण्णव',
      96: 'शहाण्णव',
      97: 'सत्त्याण्णव',
      98: 'अठ्ठ्याण्णव',
      99: 'नव्व्याण्णव',
    };

    if (number < 20) {
      return ones[number];
    }
    if (number < 100) {
      if (tensOnesMarathi.containsKey(number)) {
        return tensOnesMarathi[number]!;
      }
      return tens[number ~/ 10];
    }
    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      String result = '';
      if (hundred == 1) {
        result = 'एकशे';
      } else {
        result = '${ones[hundred]}शे';
      }
      if (remainder > 0) {
        result += ' ${_numberToWordsMarathi(remainder)}';
      }
      return result;
    }
    if (number < 100000) {
      final thousand = number ~/ 1000;
      final remainder = number % 1000;
      String result = '${_numberToWordsMarathi(thousand)} हजार';
      if (remainder > 0) {
        result += ' ${_numberToWordsMarathi(remainder)}';
      }
      return result;
    }
    if (number < 10000000) {
      final lakh = number ~/ 100000;
      final remainder = number % 100000;
      String result = '${_numberToWordsMarathi(lakh)} लाख';
      if (remainder > 0) {
        result += ' ${_numberToWordsMarathi(remainder)}';
      }
      return result;
    }
    final crore = number ~/ 10000000;
    final remainder = number % 10000000;
    String result = '${_numberToWordsMarathi(crore)} कोटी';
    if (remainder > 0) {
      result += ' ${_numberToWordsMarathi(remainder)}';
    }
    return result;
  }
}
