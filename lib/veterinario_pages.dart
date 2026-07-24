import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database.dart';

// ==========================================================
// 1. MÓDULO DE CONTROL SANITARIO
// ==========================================================
class SanidadVetPage extends StatefulWidget {
  const SanidadVetPage({super.key});
  @override State<SanidadVetPage> createState() => _SanidadVetPageState();
}

class _SanidadVetPageState extends State<SanidadVetPage> {
  String? _id;
  final _enf = TextEditingController(), _diag = TextEditingController(), _trat = TextEditingController();
  List<Map<String, dynamic>> _ans = [];
  List<Map<String, dynamic>> _historial = [];
  bool _guardando = false;

  @override void initState() { super.initState(); _cargarAnimales(); }
  void _cargarAnimales() async { var r = await DatabaseHelper().obtenerAnimalesVivos(); setState(() => _ans = r); }
  void _cargarHistorial(String id) async { var h = await DatabaseHelper().obtenerHistorialSanitario(id); setState(() => _historial = h); }

  Future<void> _guardarSanidad() async {
    if (_id == null || _enf.text.isEmpty) return;
    setState(() => _guardando = true);

    String fechaHoy = DateTime.now().toString().substring(0, 10);
    final sanidadData = {
      'id_animal': _id,
      'enfermedad': _enf.text,
      'diagnostico': _diag.text,
      'tratamiento': _trat.text,
      'fecha': fechaHoy
    };

    // 1. Guardado Local (SQLite)
    await DatabaseHelper().insertarSanidad(sanidadData);

    // 2. Intento de Subida a la Nube (Supabase)
    try {
      await Supabase.instance.client.from('control_sanitario').insert(sanidadData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("☁️ Nube: Registro médico subido a Supabase"), backgroundColor: Colors.blue));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Guardado localmente. Error Nube: $e"), backgroundColor: Colors.orange));
      }
    }

    _cargarHistorial(_id!);
    _enf.clear(); _diag.clear(); _trat.clear();
    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Control Sanitario"), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.medical_services, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Seleccionar Animal", border: OutlineInputBorder(), prefixIcon: Icon(Icons.pets)),
                value: _id,
                items: _ans.map((e) => DropdownMenuItem(value: e['id_animal'] as String, child: Text("Arete: ${e['id_animal']}"))).toList(),
                onChanged: (v) { setState(() => _id = v); _cargarHistorial(v!); }),
            const SizedBox(height: 15),
            TextField(controller: _enf, decoration: const InputDecoration(labelText: "Enfermedad", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _diag, decoration: const InputDecoration(labelText: "Diagnóstico", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _trat, decoration: const InputDecoration(labelText: "Tratamiento", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _guardando ? null : _guardarSanidad,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                child: _guardando ? const CircularProgressIndicator(color: Colors.white) : const Text("GUARDAR REGISTRO MÉDICO", style: TextStyle(fontWeight: FontWeight.bold))),
            const Divider(height: 40, thickness: 2),
            const Text("Historial Clínico Local", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
            ..._historial.map((h) => Card(child: ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: Text("${h['fecha']} - ${h['enfermedad']}", style: const TextStyle(fontWeight: FontWeight.bold)), 
              subtitle: Text("Tratamiento: ${h['tratamiento']}")
            ))).toList()
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 2. MÓDULO DE GESTIÓN REPRODUCTIVA
// ==========================================================
class GestacionPage extends StatefulWidget {
  const GestacionPage({super.key});
  @override State<GestacionPage> createState() => _GestacionPageState();
}

class _GestacionPageState extends State<GestacionPage> {
  String? _id; String _monta = 'Natural'; DateTime _fecha = DateTime.now();
  List<Map<String, dynamic>> _hembras = [];
  List<Map<String, dynamic>> _historial = [];
  bool _guardando = false;

  @override void initState() { super.initState(); _cargarHembras(); }
  void _cargarHembras() async { 
    var r = await DatabaseHelper().obtenerAnimalesVivos(); 
    setState(() => _hembras = r.where((e) => e['categoria'] == 'Vaca').toList()); 
  }
  void _cargarHistorial(String id) async { var h = await DatabaseHelper().obtenerHistorialRepro(id); setState(() => _historial = h); }

  Future<void> _guardarPrenez() async {
    if (_id == null) return;
    setState(() => _guardando = true);
    DateTime fpp = _fecha.add(const Duration(days: 283));

    final reproDataLocal = {
      'id_animal': _id,
      'tipo_monta': _monta,
      'fecha_preñez': _fecha.toString().substring(0, 10),
      'fecha_fpp': fpp.toString().substring(0, 10)
    };

    // CORRECCIÓN: Le devolvimos la "ñ" para que coincida con tu Supabase
    final reproDataNube = {
      'id_animal': _id,
      'tipo_monta': _monta,
      'fecha_preñez': _fecha.toString().substring(0, 10), 
      'fecha_fpp': fpp.toString().substring(0, 10)
    };

    await DatabaseHelper().insertarReproduccion(reproDataLocal);

    try {
      await Supabase.instance.client.from('reproduccion').insert(reproDataNube);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("☁️ Nube: Preñez subida a Supabase"), backgroundColor: Colors.blue));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Guardado localmente. Error Nube: $e"), backgroundColor: Colors.orange));
    }

    _cargarHistorial(_id!);
    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    DateTime fpp = _fecha.add(const Duration(days: 283));
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión Reproductiva"), backgroundColor: Colors.pink, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.favorite, size: 60, color: Colors.pink),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Seleccionar Vaca", border: OutlineInputBorder(), prefixIcon: Icon(Icons.female)),
                value: _id,
                items: _hembras.map((e) => DropdownMenuItem(value: e['id_animal'] as String, child: Text("Vaca: ${e['id_animal']}"))).toList(),
                onChanged: (v) { setState(() => _id = v); _cargarHistorial(v!); }),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
                value: _monta,
                items: ['Natural', 'Inseminación Artificial'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _monta = v!),
                decoration: const InputDecoration(labelText: "Tipo de Monta", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.pink),
                title: Text("Fecha de Preñez: ${_fecha.toString().substring(0, 10)}"),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  var p = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (p != null) setState(() => _fecha = p);
                }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text("Parto Estimado (FPP): ${fpp.toString().substring(0, 10)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
            ),
            ElevatedButton(
                onPressed: _guardando ? null : _guardarPrenez,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                child: _guardando ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTRAR PREÑEZ", style: TextStyle(fontWeight: FontWeight.bold))),
            const Divider(height: 40, thickness: 2),
            ..._historial.map((h) => Card(child: ListTile(
              leading: const Icon(Icons.child_friendly, color: Colors.pink),
              title: Text("${h['fecha_preñez']} - ${h['tipo_monta']}"), 
              subtitle: Text("FPP: ${h['fecha_fpp']}", style: const TextStyle(fontWeight: FontWeight.bold))
            ))).toList()
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 3. MÓDULO DE MONITOREO DE PREÑADAS
// ==========================================================
class MonitoreoPrenadasPage extends StatelessWidget {
  const MonitoreoPrenadasPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monitoreo de Partos"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper().obtenerTodasPrenadas(),
          builder: (c, s) => s.hasData
              ? ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: s.data!.length,
                  itemBuilder: (c, i) => Card(
                          child: ListTile(
                        leading: const Icon(Icons.monitor_heart, color: Colors.purple, size: 40),
                        title: Text("Vaca Arete: ${s.data![i]['id_animal']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text("Fecha Probable de Parto: ${s.data![i]['fecha_fpp']}"),
                      )))
              : const Center(child: CircularProgressIndicator())),
    );
  }
}

// ==========================================================
// 4. MÓDULO DE PESAJE Y CÁLCULO GDP
// ==========================================================
class PesajeGDPPage extends StatefulWidget {
  const PesajeGDPPage({super.key});
  @override State<PesajeGDPPage> createState() => _PesajeGDPPageState();
}

class _PesajeGDPPageState extends State<PesajeGDPPage> {
  String? _id; 
  double _pesoViejo = 0;
  double _gdpPorcentaje = -1; 
  final _p = TextEditingController();
  List<Map<String, dynamic>> _ans = [];
  bool _guardando = false;

  @override void initState() { super.initState(); _cargarAnimales(); }
  void _cargarAnimales() async { var r = await DatabaseHelper().obtenerAnimalesVivos(); setState(() => _ans = r); }

  Future<void> _calcularYGuardar() async {
    if (_id == null || _p.text.isEmpty) return;
    setState(() => _guardando = true);

    double nuevoPeso = double.parse(_p.text);
    
    // Fórmula Matemática: ((Peso Nuevo - Peso Viejo) / Peso Viejo) * 100
    double calculoGdp = 0;
    if (_pesoViejo > 0) {
      calculoGdp = ((nuevoPeso - _pesoViejo) / _pesoViejo) * 100;
    }

    // 1. Actualiza el peso en la base de datos local SQLite
    final db = await DatabaseHelper().database;
    await db.update('animales', {'peso': nuevoPeso}, where: 'id_animal = ?', whereArgs: [_id]);

    // 2. Intenta subir el Pesaje a Supabase (CORRECCIÓN: Ya no intenta actualizar 'peso' en la tabla 'animales')
    try {
      await Supabase.instance.client.from('pesajes').insert({
        'id_animal': _id,
        'peso': nuevoPeso,
        'fecha': DateTime.now().toString().substring(0, 10)
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("☁️ Nube: Pesaje actualizado con éxito"), backgroundColor: Colors.blue));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ GDP Calculado local. Error Nube: $e"), backgroundColor: Colors.orange));
    }

    setState(() {
      _gdpPorcentaje = calculoGdp;
      _pesoViejo = nuevoPeso; 
      _guardando = false;
    });
    _p.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pesaje y Rendimiento (GDP)"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.scale, size: 70, color: Colors.teal),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Seleccionar Animal", border: OutlineInputBorder()),
              value: _id, 
              items: _ans.map((e) => DropdownMenuItem(value: e['id_animal'] as String, child: Text("Arete: ${e['id_animal']}"))).toList(), 
              onChanged: (v) {
                setState(() {
                  _id = v;
                  // Extraemos el peso anterior del animal seleccionado de la mochila local
                  var animalSeleccionado = _ans.firstWhere((element) => element['id_animal'] == v);
                  _pesoViejo = (animalSeleccionado['peso'] as num).toDouble();
                  _gdpPorcentaje = -1; // Resetea el resultado en pantalla
                });
              }
            ),
            const SizedBox(height: 15),
            
            if (_id != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monitor_weight, color: Colors.teal),
                    const SizedBox(width: 10),
                    Text("Peso Anterior Registrado: $_pesoViejo Kg", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              
            const SizedBox(height: 15),
            TextField(controller: _p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Peso Nuevo (Kg)", border: OutlineInputBorder())),
            const SizedBox(height: 25),
            
            if (_gdpPorcentaje >= 0) 
              Card(
                color: _gdpPorcentaje >= 0 ? Colors.green[100] : Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("Ganancia de Peso Obtenida", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                      Text("${_gdpPorcentaje.toStringAsFixed(2)} %", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.green[900])),
                    ],
                  ),
                ),
              ),
              
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _guardando ? null : _calcularYGuardar,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                child: _guardando ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTRAR Y CALCULAR GDP", style: TextStyle(fontWeight: FontWeight.bold)))
          ]
        )
      ),
    );
  }
}