import '../../../core/database/default_categories.dart';
import 'expense_categorizer.dart';
import 'merchant_normalizer.dart';

/// Rule-based categorizer with an Indian merchant map.
///
/// Keywords are matched on word boundaries (so "ola" does not fire inside
/// "cola") and the *longest* matching keyword wins, which lets specific
/// entries beat generic ones: "uber eats" -> Food, "uber" -> Transport,
/// "amazon pay" -> Bills, "amazon" -> Shopping.
class KeywordCategorizer implements ExpenseCategorizer {
  KeywordCategorizer({Map<String, List<String>>? keywords})
    : _lookup = _buildLookup(keywords ?? defaultKeywords);

  static const merchantMatchConfidence = 0.9;
  static const rawTextMatchConfidence = 0.5;

  final Map<String, String> _lookup; // keyword -> category

  @override
  Future<(String, double)> classify(String merchant, String rawText) async {
    final byMerchant = _match(merchant);
    if (byMerchant != null) return (byMerchant, merchantMatchConfidence);

    final byText = _match(rawText);
    if (byText != null) return (byText, rawTextMatchConfidence);

    return (CategoryNames.other, 0.0);
  }

  String? _match(String input) {
    final haystack = ' ${normalizeMerchant(input)} ';
    if (haystack.trim().isEmpty) return null;
    String? best;
    var bestLength = 0;
    for (final entry in _lookup.entries) {
      if (entry.key.length > bestLength &&
          haystack.contains(' ${entry.key} ')) {
        best = entry.value;
        bestLength = entry.key.length;
      }
    }
    return best;
  }

  static Map<String, String> _buildLookup(Map<String, List<String>> source) => {
    for (final MapEntry(key: category, value: words) in source.entries)
      for (final w in words) normalizeMerchant(w): category,
  };

  /// Keywords are written in normalized form ("domino s", not "domino's").
  static const defaultKeywords = <String, List<String>>{
    CategoryNames.food: [
      'swiggy',
      'zomato',
      'uber eats',
      'eatsure',
      'box8',
      'faasos',
      'behrouz',
      'dominos',
      'domino s',
      'pizza hut',
      'kfc',
      'mcdonalds',
      'mcdonald s',
      'burger king',
      'subway',
      'starbucks',
      'cafe coffee day',
      'ccd',
      'barbeque nation',
      'haldiram',
      'haldirams',
      'chaayos',
      'restaurant',
      'cafe',
      'bakery',
      'dhaba',
      'biryani',
      'kitchen',
    ],
    CategoryNames.groceries: [
      'bigbasket',
      'big basket',
      'blinkit',
      'zepto',
      'instamart',
      'swiggy instamart',
      'jiomart',
      'dmart',
      'd mart',
      'avenue supermarts',
      'reliance fresh',
      'more supermarket',
      'nature s basket',
      'spencer s',
      'licious',
      'freshtohome',
      'country delight',
      'supermarket',
      'kirana',
      'grocery',
      'provision store',
    ],
    CategoryNames.transport: [
      'uber',
      'ola',
      'ola cabs',
      'olacabs',
      'rapido',
      'meru',
      'blu smart',
      'namma yatri',
      'fastag',
      'petrol',
      'diesel',
      'fuel',
      'indian oil',
      'iocl',
      'bharat petroleum',
      'bpcl',
      'hindustan petroleum',
      'hpcl',
      'shell',
      'metro',
      'dmrc',
      'bmtc',
      'ksrtc',
      'parking',
      'toll',
    ],
    CategoryNames.shopping: [
      'amazon',
      'flipkart',
      'myntra',
      'ajio',
      'meesho',
      'nykaa',
      'tata cliq',
      'snapdeal',
      'decathlon',
      'ikea',
      'lifestyle',
      'westside',
      'pantaloons',
      'max fashion',
      'shoppers stop',
      'reliance trends',
      'croma',
      'reliance digital',
      'vijay sales',
      'firstcry',
      'lenskart',
      'zara',
      'uniqlo',
    ],
    CategoryNames.bills: [
      'jio',
      'reliance jio',
      'airtel',
      'bharti airtel',
      'vodafone',
      'vi',
      'vodafone idea',
      'bsnl',
      'act fibernet',
      'hathway',
      'tata play',
      'dish tv',
      'tata power',
      'adani electricity',
      'bses',
      'mseb',
      'bescom',
      'electricity',
      'water bill',
      'gas bill',
      'indane',
      'bharat gas',
      'hp gas',
      'mahanagar gas',
      'recharge',
      'broadband',
      'postpaid',
      'prepaid',
      'amazon pay',
      'lic',
      'insurance',
      'rent',
      'emi',
    ],
    CategoryNames.entertainment: [
      'netflix',
      'amazon prime',
      'prime video',
      'hotstar',
      'disney',
      'jiocinema',
      'sony liv',
      'zee5',
      'spotify',
      'gaana',
      'jiosaavn',
      'youtube premium',
      'bookmyshow',
      'pvr',
      'inox',
      'cinepolis',
      'steam',
      'dream11',
    ],
    CategoryNames.health: [
      'apollo',
      'apollo pharmacy',
      'pharmeasy',
      '1mg',
      'tata 1mg',
      'netmeds',
      'medplus',
      'hospital',
      'clinic',
      'pharmacy',
      'chemist',
      'diagnostic',
      'lal pathlabs',
      'thyrocare',
      'practo',
      'cult fit',
      'cultfit',
      'healthifyme',
    ],
    CategoryNames.travel: [
      'irctc',
      'makemytrip',
      'goibibo',
      'cleartrip',
      'yatra',
      'redbus',
      'abhibus',
      'indigo',
      'air india',
      'spicejet',
      'vistara',
      'akasa',
      'oyo',
      'treebo',
      'airbnb',
      'ixigo',
      'agoda',
      'booking com',
      'easemytrip',
      'hotel',
      'resort',
    ],
    CategoryNames.education: [
      'udemy',
      'coursera',
      'byju s',
      'byjus',
      'unacademy',
      'vedantu',
      'upgrad',
      'school',
      'college',
      'tuition',
      'university',
    ],
  };
}
