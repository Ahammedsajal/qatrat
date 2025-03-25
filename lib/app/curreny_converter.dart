// currency_converter.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// Returns the currency symbol for a given [code].
String currencySymbol(String code) {
  switch (code) {
    case 'QAR':
      return 'ر.ق';
    case 'SAR':
      return 'ر.س';
    case 'AED':
      return 'د.إ';
    case 'KWT':
      return 'د.ك';
    case 'OMN':
      return 'ر.ع.';
    case 'USD':
      return '\$';
    default:
      return ''; // For QAR or if none provided.
  }
}

/// Service to fetch currency conversion rates.
class CurrencyService {
  final String _apiUrl =
      'https://v6.exchangerate-api.com/v6/fa2f1730d27b2e641dccffa9/latest/qar';

  Future<Map<String, double>> fetchRates() async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Note: The API returns the conversion rates under "conversion_rates".
      final rates = data['conversion_rates'] as Map<String, dynamic>;
      return {
        'QAR': 1.0,
        'SAR': rates['SAR']?.toDouble() ?? 0,
        'AED': rates['AED']?.toDouble() ?? 0,
        'KWT': rates['KWD']?.toDouble() ?? 0, // Adjust key if needed.
        'OMN': rates['OMR']?.toDouble() ?? 0,
        'USD': rates['USD']?.toDouble() ?? 0,
      };
    } else {
      throw Exception('Failed to fetch currency rates');
    }
  }
}

/// Provider to manage currency state and conversion.
class CurrencyProvider extends ChangeNotifier {
  final CurrencyService _service = CurrencyService();
  Map<String, double> _rates = {};
  String _selectedCurrency = 'QAR';

  Map<String, double> get rates => _rates;
  String get selectedCurrency => _selectedCurrency;

  CurrencyProvider() {
    loadRates();
  }

  Future<void> loadRates() async {
    try {
      _rates = await _service.fetchRates();
      debugPrint("Fetched rates: $_rates");
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching rates: $e");
      // Set fallback rates in case of error.
      _rates = {
        'QAR': 1.0,
        'SAR': 0.98,
        'AED': 0.99,
        'KWT': 0.07,
        'OMN': 0.11,
        'USD': 0.27,
      };
      notifyListeners();
    }
  }

  /// Change the currently selected currency.
  void changeCurrency(String currency) {
    _selectedCurrency = currency;
    debugPrint("Currency changed to: $_selectedCurrency");
    notifyListeners();
  }

  /// Converts a price (assumed to be in QAR) into the selected currency.
  double convertPrice(double priceInQAR) {
    final rate = _rates[_selectedCurrency] ?? 1.0;
    debugPrint("Converting $priceInQAR QAR using rate $rate for $_selectedCurrency");
    return priceInQAR * rate;
  }
}


/// A widget that displays a converted price.
/// 
/// [basePrice] should be the product’s price in QAR (as provided by your backend).
/// Set [isOriginal] to true if you want to display the original price (e.g. with a strikethrough).
Widget buildConvertedPrice(
  BuildContext context,
  double basePrice, {
  bool isOriginal = false,
  TextStyle? style,
}) {
  return Consumer<CurrencyProvider>(
    builder: (context, currencyProvider, child) {
      double convertedPrice = currencyProvider.convertPrice(basePrice);
      return Text(
        "${currencySymbol(currencyProvider.selectedCurrency)} ${convertedPrice.toStringAsFixed(2)}",
         style: style ??
            (isOriginal
                ? Theme.of(context).textTheme.labelSmall!.copyWith(
                      decoration: TextDecoration.lineThrough,
                      letterSpacing: 0,
                    )
                : Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    )),
      );
    },
  );
}
