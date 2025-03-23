import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  final String _apiKey = '999c4aff344a7611459bb8967'; 

 Future<double> getExchangeRate(String from, String to) async {
    final url = Uri.parse("https://v6.exchangerate-api.com/v6/99c4aff344a7611459bb8967/latest/BRL");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['conversion_rates'] != null && data['conversion_rates'][to] != null) {
        double exchangeRate = (data['conversion_rates'][to] as num).toDouble();
        print("Taxa de câmbio $from -> $to: $exchangeRate"); // Para depuração
        return exchangeRate;
      } else {
        throw Exception("Taxa de câmbio não encontrada para $to.");
      }
    } else {
      throw Exception("Erro ao buscar a taxa de câmbio.");
    }
  }
}