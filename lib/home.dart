import 'package:flutter/material.dart';
import 'api.dart';  
import 'package:firebase_database/firebase_database.dart';  

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();
  double _convertedAmount = 0.0;
  String _fromCurrency = 'BRL';
  String _toCurrency = 'USD';

  void _convertCurrency() async {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return;

    try {
      final rate = await CurrencyService().getExchangeRate(_fromCurrency, _toCurrency);
      setState(() {
        _convertedAmount = amount * rate;
      });
      // Armazenar histórico no Firestore
      _storeConversionHistory(amount, _convertedAmount);
    } catch (e) {
      // Exiba algum erro se a API falhar
      print('Erro: $e');
    }
  }

 void _storeConversionHistory(double amount, double convertedAmount) async {
  try {
    final databaseReference = FirebaseDatabase.instance.ref();

    // Adicionando histórico de conversões na árvore do Realtime Database
    await databaseReference.child('conversion_history').push().set({
      'amount': amount,
      'converted_amount': convertedAmount,
      'from_currency': _fromCurrency,
      'to_currency': _toCurrency,
      'timestamp': ServerValue.timestamp,  // Utiliza o timestamp do servidor
    });

    print("Histórico de conversão salvo com sucesso.");
  } catch (e) {
    print('Erro ao salvar no Realtime Database: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversor de Moeda'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Valor em $_fromCurrency'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _convertCurrency,
              child: Text('Converter'),
            ),
            SizedBox(height: 20),
            Text('$_convertedAmount $_toCurrency', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}