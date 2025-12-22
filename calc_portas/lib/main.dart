import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Eixos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

// Modelo de dados do Tubo
class Tubo {
  final String nome;
  final double I; // mm^4
  final double qTubo; // N/mm
  final double pesoPorMetro; // kg/m

  Tubo(this.nome, this.I, this.qTubo, this.pesoPorMetro);
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final TextEditingController _larguraController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();

  // Variáveis de estado
  String _tipoPorta = 'C'; // C = Comercial, R = Residencial
  Tubo? _melhorTubo;
  double _melhorFlecha = 0;
  double _limiteCalculado = 0;
  double _pesoPortaKg = 0;
  double _pesoTuboTotal = 0;
  String _recomendacaoGuias = "";
  bool _calculado = false;

  // Lista de Tubos (Dados do seu código Java)
final List<Tubo> _tubos = [
  Tubo("4x2",     1210000, 0.08, 8.0),
  Tubo("5x2",     1800000, 0.09, 10.0),
  Tubo("6x2,25",   980000, 0.11, 12.5), // ~9,8 kg/m (peso real aproximado)
  Tubo("6x2,65",  3200000, 0.12, 13.0),
  Tubo("6x3,75",  5200000, 0.16, 15.0),
  Tubo("6x4,75", 18700000, 0.18, 17.0), // ~18,7 kg/m (valor real)
  Tubo("8x3",     6400000, 0.18, 18.0),
  Tubo("8x4,75",10000000, 0.24, 21.0),
];



  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    // Resetar resultados
    setState(() {
      _melhorTubo = null;
      _melhorFlecha = 0;
      _recomendacaoGuias = "";
      _calculado = true;
    });

    double largura = double.parse(_larguraController.text.replaceAll(',', '.'));
    double altura = double.parse(_alturaController.text.replaceAll(',', '.'));

    // Constantes
    double E = 200000; // MPa
    double g = 9.81; // m/s^2
    double pesoLamina = 8; // kg/m²

    // Lógica do Limite
    double limite;
    if (_tipoPorta == 'C') {
      limite = (largura * 1000) / 200.0;
    } else {
      limite = (largura * 1000) / 250.0;
    }

    // Cálculos de Peso
    double areaLaminas = largura * altura;
    double pesoPortaKg = areaLaminas * pesoLamina;
    double pesoPortaN = pesoPortaKg * g;
    double qLaminas = pesoPortaN / (largura * 1000); // N/mm

    // Seleção do Tubo
    Tubo? tempMelhorTubo;
    double tempMelhorFlecha = 0;

    for (var t in _tubos) {
      double qTotal = t.qTubo + qLaminas; // N/mm
      // Fórmula da flecha
      double delta = (5 * qTotal * pow(largura * 1000, 4)) / (384 * E * t.I); 

      if (delta <= limite) {
        // A lógica do Java era: pegar o tubo que tem a maior flecha (delta) 
        // desde que esteja dentro do limite. Isso geralmente seleciona o tubo
        // mais econômico (mais leve/fino) que ainda aguenta.
        if (tempMelhorTubo == null || delta > tempMelhorFlecha) {
          tempMelhorTubo = t;
          tempMelhorFlecha = delta;
        }
      }
    }

    // Lógica Interno/Externo
    String recomendacao = "";
    if (largura < 2.5) {
      recomendacao = "Veja com supervisor";
    } else if (largura <= 4.2) {
      recomendacao = "Interno 50 | Externo 70";
    } else if (largura <= 5) {
      recomendacao = "Interno 70 | Externo 100";
    } else if (largura <= 10) {
      recomendacao = "Interno 150 | Externo 180";
    } else {
      recomendacao = "Veja com supervisor";
    }

    setState(() {
      _melhorTubo = tempMelhorTubo;
      _melhorFlecha = tempMelhorFlecha;
      _limiteCalculado = limite;
      _pesoPortaKg = pesoPortaKg;
      _recomendacaoGuias = recomendacao;
      if (tempMelhorTubo != null) {
        _pesoTuboTotal = tempMelhorTubo.pesoPorMetro * largura;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Eixo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _larguraController.clear();
              _alturaController.clear();
              setState(() {
                _calculado = false;
                _melhorTubo = null;
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildForm(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _calcular,
                  icon: const Icon(Icons.calculate),
                  label: const Text('CALCULAR TUBO'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
                const SizedBox(height: 20),
                if (_calculado) _buildResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _larguraController,
                decoration: const InputDecoration(
                  labelText: 'Largura da porta (m)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.width_full),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite a largura';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alturaController,
                decoration: const InputDecoration(
                  labelText: 'Altura da porta (m)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Digite a altura';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoPorta,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Porta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.garage),
                ),
                items: const [
                  DropdownMenuItem(value: 'C', child: Text('Comercial (L/200)')),
                  DropdownMenuItem(value: 'R', child: Text('Residencial (L/250)')),
                ],
                onChanged: (val) {
                  setState(() {
                    _tipoPorta = val!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_melhorTubo == null) {
      return const Card(
        color: Colors.redAccent,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Nenhum tubo atende ao limite calculado para esta largura.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          color: Colors.green.shade50,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('TUBO RECOMENDADO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(
                  _melhorTubo!.nome,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Peso Aprox. Tubo: ${_pesoTuboTotal.toStringAsFixed(2)} kg'),
                    Text('Peso Porta: ${_pesoPortaKg.toStringAsFixed(2)} kg'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Flecha Calculada:', '${_melhorFlecha.toStringAsFixed(2)} mm'),
                _buildInfoRow('Limite Máximo:', '${_limiteCalculado.toStringAsFixed(2)} mm'),
                const Divider(),
                const Text('Recomendação de Guias:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _recomendacaoGuias,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}