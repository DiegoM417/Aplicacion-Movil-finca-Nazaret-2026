import 'package:flutter/material.dart';
import 'database.dart';

// ==========================================================
// 1. PANTALLA DE ESTADÍSTICAS DEL ADMINISTRADOR
// ==========================================================
class AdminStatsPage extends StatelessWidget {
  const AdminStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Estadísticas de la Finca", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: DatabaseHelper().obtenerInventarioAdministrador(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));
          var d = s.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.green[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 40),
                        const SizedBox(height: 10),
                        const Text("Ganancia de Peso del Rebaño (GDP)", style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text("+${d['gdp']}%", style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _cardGanadero("Cabezas Totales", "${d['total']}", Colors.green, Icons.agriculture),
                    _cardGanadero("Vacas", "${d['hembras']}", Colors.pink, Icons.female),
                    _cardGanadero("Toros/Novillos", "${d['machos']}", Colors.blue, Icons.male),
                    _cardGanadero("Becerros", "${d['becerros']}", Colors.orange, Icons.grass), // Ícono corregido
                    _cardGanadero("Preñadas", "${d['prenadas']}", Colors.redAccent, Icons.monitor_heart),
                    _cardGanadero("Vendidos", "${d['ventas']}", Colors.teal, Icons.attach_money),
                    _cardGanadero("Muertes", "${d['muertes']}", Colors.grey[800]!, Icons.warning),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cardGanadero(String titulo, String valor, Color color, IconData icono) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(bottom: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 35, color: color),
            const SizedBox(height: 8),
            Text(valor, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(titulo, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 2. PANTALLA DE GESTIÓN DE USUARIOS (NUEVO: Control Total)
// ==========================================================
class GestionUsuariosPage extends StatefulWidget {
  const GestionUsuariosPage({super.key});
  @override 
  State<GestionUsuariosPage> createState() => _GestionUsuariosPageState();
}

class _GestionUsuariosPageState extends State<GestionUsuariosPage> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() async {
    try {
      var r = await DatabaseHelper().obtenerUsuarios();
      setState(() { _usuarios = r; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  void _bloquearDesbloquear(int id, int estadoActual) async {
    await DatabaseHelper().cambiarEstadoUsuario(id, estadoActual);
    _cargarUsuarios();
  }

  void _eliminar(int id) async {
    await DatabaseHelper().eliminarUsuario(id);
    _cargarUsuarios();
  }

  // Dialogo flotante para editar credenciales
  void _mostrarDialogoEdicion(int id, String nombreActual, String claveActual) {
    TextEditingController nomCtrl = TextEditingController(text: nombreActual);
    TextEditingController claveCtrl = TextEditingController(text: claveActual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Credenciales"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: "Usuario")),
            const SizedBox(height: 10),
            TextField(controller: claveCtrl, decoration: const InputDecoration(labelText: "Contraseña")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            onPressed: () async {
              if (nomCtrl.text.isNotEmpty && claveCtrl.text.isNotEmpty) {
                await DatabaseHelper().editarUsuario(id, nomCtrl.text.trim(), claveCtrl.text.trim());
                if (mounted) Navigator.pop(context);
                _cargarUsuarios();
              }
            }, 
            child: const Text("Guardar Cambios")
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Personal"),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _usuarios.length,
              itemBuilder: (c, i) {
                bool estaActivo = _usuarios[i]['activo'] == 1;
                int idUsuario = _usuarios[i]['id'];
                
                return Card(
                  color: estaActivo ? Colors.white : Colors.red[50],
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: estaActivo ? Colors.green : Colors.red,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(_usuarios[i]['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("Rol: ${_usuarios[i]['rol'].toUpperCase()} \nEstado: ${estaActivo ? 'ACTIVO' : 'BLOQUEADO'}\nClave: ${_usuarios[i]['contrasena']}"),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // BOTÓN DE EDICIÓN (NUEVO)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: "Editar credenciales",
                          onPressed: () => _mostrarDialogoEdicion(idUsuario, _usuarios[i]['nombre'], _usuarios[i]['contrasena']),
                        ),
                        IconButton(
                          icon: Icon(estaActivo ? Icons.block : Icons.check_circle),
                          color: estaActivo ? Colors.orange : Colors.green,
                          tooltip: estaActivo ? "Bloquear Acceso" : "Desbloquear",
                          onPressed: () => _bloquearDesbloquear(idUsuario, _usuarios[i]['activo']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Eliminar Usuario",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("¿Eliminar empleado?"),
                                content: Text("Se borrará el acceso de ${_usuarios[i]['nombre']} permanentemente."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _eliminar(idUsuario);
                                    }, 
                                    child: const Text("Eliminar", style: TextStyle(color: Colors.red))
                                  ),
                                ],
                              )
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================================
// 3. BUSCADOR GENERAL DE ANIMALES
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
                    leading: Icon(Icons.agriculture, color: colorEstado, size: 35), // Ícono corregido
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