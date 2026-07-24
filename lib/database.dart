import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finca_nazaret.db');
    
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE animales (
            id_animal TEXT PRIMARY KEY,
            peso REAL,
            categoria TEXT,
            estado TEXT DEFAULT 'Vivo', 
            estatus_sincronizacion INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT,
            contrasena TEXT,
            rol TEXT,
            activo INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE reproduccion (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_animal TEXT,
            tipo_monta TEXT,
            fecha_preñez TEXT,
            fecha_fpp TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sanidad (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_animal TEXT,
            enfermedad TEXT,
            diagnostico TEXT,
            tratamiento TEXT,
            fecha TEXT
          )
        ''');

        await db.rawInsert("INSERT INTO usuarios (nombre, contrasena, rol) VALUES ('vaquero', '1234', 'vaquero')");
        await db.rawInsert("INSERT INTO usuarios (nombre, contrasena, rol) VALUES ('admin', '1234', 'admin')");
        await db.rawInsert("INSERT INTO usuarios (nombre, contrasena, rol) VALUES ('vet', '1234', 'vet')");
      },
    );
  }

  // ==========================================================
  // FUNCIONES DEL ADMINISTRADOR Y KPI GERENCIALES
  // ==========================================================
  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    Database db = await database;
    return await db.query('usuarios');
  }

  Future<int> cambiarEstadoUsuario(int id, int estadoActual) async {
    Database db = await database;
    int nuevoEstado = estadoActual == 1 ? 0 : 1; 
    return await db.update('usuarios', {'activo': nuevoEstado}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> eliminarUsuario(int id) async {
    Database db = await database;
    return await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  // ¡NUEVA FUNCIÓN! El superusuario ahora tiene control total sobre credenciales
  Future<int> editarUsuario(int id, String nuevoNombre, String nuevaClave) async {
    Database db = await database;
    return await db.update(
      'usuarios', 
      {'nombre': nuevoNombre, 'contrasena': nuevaClave}, 
      where: 'id = ?', 
      whereArgs: [id]
    );
  }

  Future<Map<String, dynamic>> obtenerInventarioAdministrador() async {
    Database db = await database;
    
    List<Map<String, dynamic>> animales = await db.query('animales');
    List<Map<String, dynamic>> prenadasQuery = await db.query('reproduccion');

    int totalVivos = animales.where((a) => a['estado'] == 'Vivo').length;
    int vacas = animales.where((a) => a['categoria'] == 'Vaca' && a['estado'] == 'Vivo').length;
    int toros = animales.where((a) => (a['categoria'] == 'Toro' || a['categoria'] == 'Novillo') && a['estado'] == 'Vivo').length;
    int becerros = animales.where((a) => a['categoria'] == 'Becerro' && a['estado'] == 'Vivo').length;
    
    int muertes = animales.where((a) => a['estado'] == 'Muerto').length;
    int ventas = animales.where((a) => a['estado'] == 'Vendido').length;
    
    double gdpMensual = 14.5; 

    return {
      'total': totalVivos,
      'hembras': vacas,
      'machos': toros,
      'becerros': becerros,
      'prenadas': prenadasQuery.length,
      'muertes': muertes,
      'ventas': ventas,
      'gdp': gdpMensual,
    }; 
  }

  // ==========================================================
  // RESTO DE FUNCIONES (VETERINARIO Y MOCHILA) 
  // ==========================================================
  Future<List<Map<String, dynamic>>> obtenerAnimalesVivos() async {
    Database db = await database;
    return await db.query('animales', where: 'estado = ?', whereArgs: ['Vivo']); 
  }

  Future<List<Map<String, dynamic>>> buscarAnimal(String id) async {
    Database db = await database;
    return await db.query('animales', where: 'id_animal = ?', whereArgs: [id]);
  }

  Future<int> insertarReproduccion(Map<String, dynamic> data) async {
    Database db = await database; return await db.insert('reproduccion', data); 
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialRepro(String idAnimal) async {
    Database db = await database; return await db.query('reproduccion', where: 'id_animal = ?', whereArgs: [idAnimal], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> obtenerTodasPrenadas() async {
    Database db = await database; return await db.query('reproduccion', orderBy: 'fecha_fpp ASC'); 
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialSanitario(String idAnimal) async {
    Database db = await database; return await db.query('sanidad', where: 'id_animal = ?', whereArgs: [idAnimal], orderBy: 'id DESC'); 
  }

  Future<int> insertarSanidad(Map<String, dynamic> sanidad) async {
    Database db = await database; return await db.insert('sanidad', sanidad); 
  }

  Future<int> registrarPesaje(String idAnimal, dynamic datosDelPesaje) async {
    return 1; 
  }

  Future<int> guardarAnimalLocal(Map<String, dynamic> animal) async {
    Database db = await database;
    animal['estatus_sincronizacion'] = 0; 
    return await db.insert('animales', animal, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> obtenerPendientes() async {
    Database db = await database;
    return await db.query('animales', where: 'estatus_sincronizacion = ?', whereArgs: [0]);
  }

  Future<void> marcarSincronizado(String idAnimal) async {
    Database db = await database;
    await db.update('animales', {'estatus_sincronizacion': 1}, where: 'id_animal = ?', whereArgs: [idAnimal]);
  }
}