/// Canonical key for a merchant: lower-case, punctuation collapsed to single
/// spaces. "Domino's Pizza #42" -> "domino s pizza 42".
String normalizeMerchant(String merchant) =>
    merchant.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
