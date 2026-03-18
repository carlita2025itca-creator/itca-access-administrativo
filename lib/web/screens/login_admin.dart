import 'package:flutter/material.dart';
// 👇 Importamos Supabase
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panel_admin_itca/web/screens/home_admin.dart';

class LoginAdmin extends StatefulWidget {
  const LoginAdmin({super.key});

  @override
  State<LoginAdmin> createState() => _LoginAdminState();
}

class _LoginAdminState extends State<LoginAdmin> {
  // Variables para la interfaz
  bool _obscureText = true;
  bool _estaCargando = false;

  // Controladores para capturar los datos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= LÓGICA DE INICIO DE SESIÓN CON SUPABASE =================
  Future<void> _iniciarSesion() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _mostrarMensaje(
        '⚠️ Por favor ingresa correo y contraseña',
        Colors.orange,
      );
      return;
    }

    setState(() => _estaCargando = true);

    try {
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (res.user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeAdmin()),
          );
        }
      }
    } on AuthException catch (e) {
      String mensaje = 'Error al ingresar';
      if (e.message.contains('Invalid login credentials')) {
        mensaje = '❌ Correo o contraseña incorrectos.';
      } else if (e.message.contains('Email not confirmed')) {
        mensaje = '❌ Debes confirmar tu correo electrónico para ingresar.';
      } else {
        mensaje = '❌ ${e.message}';
      }
      _mostrarMensaje(mensaje, Colors.red);
    } catch (e) {
      _mostrarMensaje('❌ Error de conexión: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _mostrarMensaje(String texto, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 80,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary, // Toma el azul del main global
                ),
                const SizedBox(height: 15),
                Text(
                  'ITCA Access',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary, // Toma el azul del main global
                  ),
                ),
                const Text(
                  'Panel de Administración Web',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    // Los bordes y colores ahora se controlan desde el main.dart
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botón de Ingresar súper limpio (El estilo viene del main.dart)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _estaCargando ? null : _iniciarSesion,
                    child: _estaCargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'INGRESAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
