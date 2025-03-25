import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  final String _apiUrl = 'https://v6.exchangerate-api.com/v6/fa2f1730d27b2e641dccffa9/latest/qar';

  Future<Map<String, double>> fetchRates() async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Use the correct key: "conversion_rates" instead of "rates"
      final rates = data['conversion_rates'] as Map<String, dynamic>;
      return {
        'QAR': 1.0,
        'SAR': rates['SAR']?.toDouble() ?? 0,
        'AED': rates['AED']?.toDouble() ?? 0,
        'KWT': rates['KWD']?.toDouble() ?? 0,  // Adjust key if needed.
        'OMN': rates['OMR']?.toDouble() ?? 0,
        'USD': rates['USD']?.toDouble() ?? 0,
      };
    } else {
      throw Exception('Failed to fetch currency rates');
    }
  }
  
}
