import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

void main() async {
  // Asegura que los componentes visuales carguen antes de iniciar Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización global del servidor en la nube de tu Finca
  await Supabase.initialize(
    url: 'https://ajbsuzpvbmnbzhqqhfet.supabase.co',
    anonKey: 'sb_publishable_X3RI_jU0wRnI7XXoIWhFjw_5nIcmdzY', // <-- Pega aquí tu clave anon de Supabase
  );

  runApp(const MaterialApp(
    home: LoginPage(),
    debugShowCheckedModeBanner: false,
  ));
}