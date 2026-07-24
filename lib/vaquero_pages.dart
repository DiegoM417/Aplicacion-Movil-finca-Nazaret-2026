import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart';

class VaqueroPage extends StatefulWidget {
  const VaqueroPage({super.key});

  @override
  State<VaqueroPage> createState() => _VaqueroPageState();
}

class _VaqueroPageState extends State<VaqueroPage> {
  final _areteController = TextEditingController();
  final _pesoController = TextEditingController();
  String _categoriaSeleccionada = 'Becerro'; 
  
  int _cantidadPendientes = 0;
  bool _sincronizando = false;
  bool _hayInternet = false; // NUEVO: Estado visual del radar
  
  late StreamSubscription<List<ConnectivityResult>> _suscripcionInternet;

  @override
  void initState() {
    super.initState();
    _revisarMochila();

    // Verificación inicial rápida
    Connectivity().checkConnectivity().then((result) {
      if (mounted) setState(() => _hayInternet = !result.contains(ConnectivityResult.none));
    });

    // Radar en segundo plano
    _suscripcionInternet = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (mounted) setState(() => _hayInternet = !result.contains(ConnectivityResult.none));
      
      if (_hayInternet) {
        _sincronizarConNube(); 
      }
    });
  }

  @override
  void dispose() {
    _suscripcionInternet.cancel(); 
    super.dispose();
  }

  Future<void> _revisarMochila() async {
    final pendientes = await DatabaseHelper().obtenerPendientes();
    setState(() {
      _cantidadPendientes = pendientes.length;
    });
  }

  Future<void> _guardarAnimal() async {
    if (_areteController.text.isEmpty || _pesoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, llena todos los campos"), backgroundColor: Colors.red),
      );
      return;
    }

    final nuevoAnimal = {
      'id_animal': _areteController.text.trim(),
      'peso': double.parse(_pesoController.text.trim()),
      'categoria': _categoriaSeleccionada,
    };

    await DatabaseHelper().guardarAnimalLocal(nuevoAnimal);

    _areteController.clear();
    _pesoController.clear();
    FocusScope.of(context).unfocus();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Guardado en el teléfono"), 
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    await _revisarMochila();
    _sincronizarConNube();
  }

  Future<void> _sincronizarConNube() async {
    if (_cantidadPendientes == 0 || _sincronizando) return;

    final conectividad = await Connectivity().checkConnectivity();
    if (conectividad.contains(ConnectivityResult.none)) return; 

    setState(() => _sincronizando = true);

    try {
      final listaPendientes = await DatabaseHelper().obtenerPendientes();

      for (var animal in listaPendientes) {
        String sexoDeducido = (animal['categoria'] == 'Vaca') ? 'Hembra' : 'Macho';

        final datosParaNube = {
          'id_animal': animal['id_animal'],
          'categoria': animal['categoria'],
          'sexo': sexoDeducido,
          'origen': 'Nacido en Finca', 
        };

        await Supabase.instance.client.from('animales').upsert(datosParaNube);
        
        await Supabase.instance.client.from('pesajes').insert({
          'id_animal': animal['id_animal'],
          'peso': animal['peso'],
        });
        
        await DatabaseHelper().marcarSincronizado(animal['id_animal']);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚀 ¡Sincronización Automática Exitosa!"), backgroundColor: Colors.blue),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de la Nube: $e"), 
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      print("Error de sincronización en segundo plano: $e");
    } finally {
      if (mounted) {
        setState(() => _sincronizando = false);
        _revisarMochila();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Módulo Vaquero"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // NUEVO: La Nube Inteligente
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: _sincronizando 
                ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Icon(
                    _hayInternet ? Icons.cloud_done : Icons.cloud_off,
                    color: _hayInternet ? Colors.white : Colors.red[200],
                    size: 30,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _sincronizando || !_hayInternet ? null : _sincronizarConNube,
            tooltip: 'Forzar Sincronización',
          )
        ],
      ),
      body: Column(
        children: [
          if (_cantidadPendientes > 0)
            Container(
              color: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tienes $_cantidadPendientes animal(es) sin subir a internet.",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NUEVO Ícono Ganadero
                  const Icon(Icons.agriculture, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text(
                    "Registro Rápido de Campo", 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 30),
                  
                  TextField(
                    controller: _areteController,
                    decoration: const InputDecoration(
                      labelText: "Número de Arete (ID)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _pesoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Peso (Kg)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: "Categoría",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grass),
                    ),
                    items: ['Becerro', 'Novillo', 'Vaca', 'Toro'].map((String valor) {
                      return DropdownMenuItem<String>(
                        value: valor,
                        child: Text(valor),
                      );
                    }).toList(),
                    onChanged: (nuevoValor) {
                      setState(() {
                        _categoriaSeleccionada = nuevoValor!;
                      });
                    },
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _guardarAnimal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("GUARDAR ANIMAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}