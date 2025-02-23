import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> dadosCotacoes;

  @override
  void initState() {
    super.initState();
    dadosCotacoes = CotacaoService.getDadosCotacoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotações Brasil'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                dadosCotacoes = CotacaoService.getDadosCotacoes();
              });
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dadosCotacoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data!;
          return CotacoesView(dados: data);
        },
      ),
    );
  }
}

class CotacaoService {
  static Future<Map<String, dynamic>> getDadosCotacoes() async {
    try {
      final res = await http.get(Uri.parse('http://api.hgbrasil.com/finance?key=c09440f1'));
      if (res.statusCode != HttpStatus.ok) {
        throw 'Erro de conexão';
      }
      return jsonDecode(res.body)["results"];
    } catch (e) {
      throw e.toString();
    }
  }
}

class CotacoesView extends StatelessWidget {
  final Map<String, dynamic> dados;
  const CotacoesView({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    final currencies = dados["currencies"];
    final stocks = dados["stocks"];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: CotacaoCard(
              moeda: currencies["USD"]["name"],
              valor: currencies["USD"]["buy"].toStringAsFixed(4),
              variacao: currencies["USD"]["variation"].toStringAsFixed(2),
              isPrincipal: true,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Outras moedas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CotacaoCard(
                  moeda: currencies["EUR"]["name"],
                  valor: currencies["EUR"]["buy"].toStringAsFixed(4),
                  variacao: currencies["EUR"]["variation"].toStringAsFixed(2),
                ),
                CotacaoCard(
                  moeda: currencies["GBP"]["name"],
                  valor: currencies["GBP"]["buy"].toStringAsFixed(4),
                  variacao: currencies["GBP"]["variation"].toStringAsFixed(2),
                ),
                CotacaoCard(
                  moeda: currencies["JPY"]["name"],
                  valor: currencies["JPY"]["buy"].toStringAsFixed(4),
                  variacao: currencies["JPY"]["variation"].toStringAsFixed(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bolsa de Valores',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              BolsaCard(
                nome: stocks["IBOVESPA"]["name"],
                local: "São Paulo, Brazil",
                valor: stocks["IBOVESPA"]["points"].toStringAsFixed(2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CotacaoCard extends StatelessWidget {
  final String moeda;
  final String valor;
  final String variacao;
  final bool isPrincipal;

  const CotacaoCard({
    super.key,
    required this.moeda,
    required this.valor,
    required this.variacao,
    this.isPrincipal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPrincipal ? Colors.black : const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isPrincipal ? double.infinity : 120,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              moeda,
              style: TextStyle(
                fontSize: isPrincipal ? 24 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ $valor',
              style: TextStyle(
                fontSize: isPrincipal ? 28 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              variacao,
              style: TextStyle(
                fontSize: 16,
                color: double.parse(variacao) < 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BolsaCard extends StatelessWidget {
  final String nome;
  final String local;
  final String valor;

  const BolsaCard({
    super.key,
    required this.nome,
    required this.local,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(
                nome,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                local,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
