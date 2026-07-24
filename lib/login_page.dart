import 'package:flutter/material.dart';
import 'home_page.dart'; // Aquí es donde VS Code se estaba confundiendo
import 'database.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false;

  void _login() async {
    if (_u.text.isEmpty || _p.text.isEmpty) return;
    
    setState(() => _loading = true);

    try {
      final usuariosLocales = await DatabaseHelper().obtenerUsuarios();

      bool encontrado = false;
      String rolUsuario = '';

      for (var usuario in usuariosLocales) {
        if (usuario['nombre'] == _u.text.trim() && usuario['contrasena'] == _p.text.trim()) {
          encontrado = true;
          rolUsuario = usuario['rol'];
          break; 
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);

      if (encontrado) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(rol: rolUsuario)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales incorrectas"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error local: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.agriculture, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              const Text("FINCA NAZARET", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 40),
              TextField(
                controller: _u, 
                textCapitalization: TextCapitalization.none, 
                decoration: const InputDecoration(labelText: "Usuario", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _p, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))
              ),
              const SizedBox(height: 30),
              _loading 
                ? const CircularProgressIndicator(color: Colors.green) 
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55)
                    ),
                    child: const Text("INGRESAR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
            ],
          ),
        ),
      ),
    );
  }
}