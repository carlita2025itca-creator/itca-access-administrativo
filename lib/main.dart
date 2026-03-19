import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 👇 Asegúrate de que las rutas coincidan con la estructura de tus carpetas
import 'web/screens/login_admin.dart';
import 'web/screens/home_admin.dart';

Future<void> main() async {
  // 1. Aseguramos que Flutter esté listo antes de arrancar los servicios
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Encendemos el motor de Supabase con tus credenciales
  await Supabase.initialize(
    url: 'https://btbzggtbnbkqgyhbdsqx.supabase.co',
    anonKey: 'sb_publishable_LC69zVXpoIOoSG3BZcO9vw_H_rSlP0H',
  );

  // 3. Arrancamos la App
  runApp(const ItcaAccessApp());
}

class ItcaAccessApp extends StatelessWidget {
  const ItcaAccessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el color exacto una sola vez
    const Color azulITCA = Color(0xFF1A73E8);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la cinta roja de "DEBUG"
      title: 'ITCA Access Panel',
      theme: ThemeData(
        // 1. Color general del sistema
        colorScheme: ColorScheme.fromSeed(
          seedColor: azulITCA,
          primary: azulITCA, // Forzamos el primario
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Fuente limpia y moderna
        // ================= REGLAS GLOBALES =================

        // 2. Regla para TODOS los botones (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: azulITCA, // Fondo siempre azul
            foregroundColor: Colors.white, // Letras e íconos siempre blancos
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),

        // 3. Regla para TODOS los campos de texto
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: azulITCA, width: 2),
          ),
          prefixIconColor: azulITCA,
        ),
      ),
      // Controlador inteligente de sesión
      home: const ControlSesion(),
    );
  }
}

// ================= CONTROLADOR INTELIGENTE DE SESIÓN =================
// Este widget decide qué pantalla mostrarte dependiendo de si ya estás logueada o no.
class ControlSesion extends StatefulWidget {
  const ControlSesion({super.key});

  @override
  State<ControlSesion> createState() => _ControlSesionState();
}

class _ControlSesionState extends State<ControlSesion> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    // Le preguntamos a Supabase: "¿Hay alguien conectado ahora mismo?"
    final sesionActual = supabase.auth.currentSession;

    // Si hay una sesión activa, mandamos al panel principal con su correo
    if (sesionActual != null && sesionActual.user.email != null) {
      return HomeAdmin(emailUsuario: sesionActual.user.email!);
    }
    // Si no hay nadie logueado, lo mandamos al Login
    else {
      return const LoginAdmin();
    }
  }
}
