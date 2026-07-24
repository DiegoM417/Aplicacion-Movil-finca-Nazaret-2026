import 'package:flutter/material.dart';

// Importamos la base de datos para que el Buscador funcione aquí
import 'database.dart'; 

import 'administrador_pages.dart';
import 'vaquero_pages.dart';
import 'veterinario_pages.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  final String rol;
  const HomePage({super.key, required this.rol});

  Widget _crearBoton(BuildContext context, String titulo, IconData icono, Color color, Widget pagina) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(65),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
        icon: Icon(icono, size: 30),
        label: Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => pagina)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String rolLimpio = rol.toLowerCase().trim();

    // 1. El buscador lo ven todos (Ahora está programado aquí mismo abajo)
    List<Widget> botonesMenu = [
      _crearBoton(context, "BUSCADOR DE GANADO", Icons.search, Colors.blueGrey, const BuscadorAnimalPage()),
    ];

    if (rolLimpio == 'vaquero') {
      botonesMenu.add(_crearBoton(context, "REGISTRAR ANIMAL", Icons.add_to_photos, Colors.green[700]!, const VaqueroPage()));
      
    } else if (rolLimpio == 'veterinario' || rolLimpio == 'vet') {
      botonesMenu.add(_crearBoton(context, "CONTROL SANITARIO", Icons.medical_services, Colors.blue, const SanidadVetPage()));
      botonesMenu.add(_crearBoton(context, "GESTIÓN REPRODUCTIVA", Icons.favorite, Colors.pink, const GestacionPage()));
      botonesMenu.add(_crearBoton(context, "MONITOREO PREÑADAS", Icons.monitor_heart, Colors.purple, const MonitoreoPrenadasPage()));
      botonesMenu.add(_crearBoton(context, "PESAJE Y GDP", Icons.scale, Colors.teal, const PesajeGDPPage()));
      
    } else if (rolLimpio == 'administrador' || rolLimpio == 'admin') {
      botonesMenu.add(_crearBoton(context, "INVENTARIO REAL (NUBE)", Icons.bar_chart, Colors.indigo, const AdminStatsPage()));
      botonesMenu.add(_crearBoton(context, "GESTIÓN DE PERSONAL", Icons.people, Colors.brown, const GestionUsuariosPage()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Panel: $rol", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginPage())),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: botonesMenu,
        ),
      ),
    );
  }
}

// ==========================================================
// BUSCADOR GENERAL DE ANIMALES
// Lo movimos directamente aquí para matar el error de raíz.
// ==========================================================
class BuscadorAnimalPage extends StatefulWidget {
  const BuscadorAnimalPage({super.key});
  @override State<BuscadorAnimalPage> createState() => _BuscadorAnimalPageState();
}

class _BuscadorAnimalPageState extends State<BuscadorAnimalPage> {
  final _s = TextEditingController();
  List<Map<String, dynamic>> _res = [];
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buscador de Ganado"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _s,
              onChanged: (v) async {
                if (v.isEmpty) { setState(() => _res = []); return; }
                setState(() => _searching = true);
                var r = await DatabaseHelper().buscarAnimal(v);
                setState(() { _res = r; _searching = false; });
              },
              decoration: const InputDecoration(
                hintText: "Escriba Número de Arete...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _res.length,
              itemBuilder: (c, i) {
                String estado = _res[i]['estado'] ?? 'Vivo';
                Color colorEstado = Colors.green;
                if (estado == 'Muerto') colorEstado = Colors.black;
                if (estado == 'Vendido') colorEstado = Colors.blue;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Icon(Icons.pets, color: colorEstado, size: 35),
                    title: Text("Arete: ${_res[i]['id_animal']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Categoría: ${_res[i]['categoria']} - Estado: $estado \nPeso Actual: ${_res[i]['peso']} Kg"),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}