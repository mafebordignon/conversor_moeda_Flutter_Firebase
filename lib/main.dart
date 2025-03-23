import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAuwZra1CWvlHyb8Giq5sFbiPMxlSWEN-0",
      appId: "1:700610851771:android:1863b0cc5d2ce9e2eeca9e",
      messagingSenderId: "700610851771",
      projectId: "conversao-moeda",
      databaseURL: "https://conversao-moeda-default-rtdb.firebaseio.com",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController();
  double? usd, eur;

  void _convert() async {
    double brl = double.tryParse(_controller.text) ?? 0;
    if (brl <= 0) return;

    CurrencyService service = CurrencyService();
    try {
      double usdRate = await service.getExchangeRate("BRL", "USD");
      double eurRate = await service.getExchangeRate("BRL", "EUR");

      setState(() {
        usd = brl * usdRate;
        eur = brl * eurRate;
      });

      _storeConversionHistory(brl, usd!, eur!);

      print("Valor inserido: R\$ $brl");
      print("Valor convertido: USD \$${usd!.toStringAsFixed(2)}, EUR €${eur!.toStringAsFixed(2)}");

    } catch (e) {
      print("Erro ao buscar taxas de câmbio: $e");
    }
  }

  void _storeConversionHistory(double amount, double usd, double eur) async {
    try {
      await FirebaseFirestore.instance.collection('conversion_history').add({
        'amount_brl': amount,
        'converted_usd': usd,
        'converted_eur': eur,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Histórico salvo no Firestore!");
    } catch (e) {
      print("Erro ao salvar no Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conversor de Moeda',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Conversor de Moeda'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Valor em BRL"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _convert,
                child: Text("Converter"),
              ),
              SizedBox(height: 20),
              if (usd != null && eur != null) ...[
                Text("USD: \$${usd!.toStringAsFixed(2)}", style: TextStyle(fontSize: 20)),
                Text("EUR: €${eur!.toStringAsFixed(2)}", style: TextStyle(fontSize: 20)),
              ],
              SizedBox(height: 20),
              Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoricoScreen()),
                      );
                    },
                    child: Text("Ver Histórico"),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoricoScreen extends StatelessWidget {
  // Função para buscar dados do Firestore
  Stream<List<Map<String, dynamic>>> getHistorico() {
    final historicoRef = FirebaseFirestore.instance.collection('conversion_history');
    return historicoRef.orderBy('timestamp', descending: true).snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Histórico de Conversões")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getHistorico(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar histórico"));
          }

          final historico = snapshot.data;

          if (historico == null || historico.isEmpty) {
            return Center(child: Text("Nenhum histórico disponível"));
          }

          return ListView.builder(
            itemCount: historico.length,
            itemBuilder: (context, index) {
              final item = historico[index];
              return ListTile(
                title: Text("Conversão de BRL para USD/EUR"),
                subtitle: Text(
                  "Valor: R\$${item['amount_brl']} - USD: \$${item['converted_usd']} - EUR: €${item['converted_eur']}",
                ),
                trailing: Text(
                  item['timestamp'] != null
                      ? (item['timestamp'] as Timestamp).toDate().toString()
                      : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
