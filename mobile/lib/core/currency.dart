const currencySymbols = {
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
  'JPY': '¥',
  'CAD': r'C$',
  'AUD': r'A$',
};

String currencySymbol(String code) => currencySymbols[code] ?? r'$';
