import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // ✨ Para manejar los textos a encriptar
import 'package:crypto/crypto.dart'; // ✨ El motor de encriptación SHA-256
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

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= LÓGICA DE INICIO DE SESIÓN PROPIA =================
  Future<void> _iniciarSesion() async {
    final correoIngresado = _emailController.text.trim().toLowerCase();
    final passwordIngresada = _passwordController.text.trim();

    if (correoIngresado.isEmpty || passwordIngresada.isEmpty) {
      _mostrarMensaje(
        '⚠️ Por favor ingresa correo y contraseña',
        Colors.orange,
      );
      return;
    }

    setState(() => _estaCargando = true);

    try {
      // 1. ENCRIPTAMOS LA CONTRASEÑA ESCRITA
      var bytes = utf8.encode(passwordIngresada);
      String passwordEncriptada = sha256.convert(bytes).toString();

      // 2. BUSCAMOS AL USUARIO EN NUESTRA TABLA
      final usuarioData = await supabase
          .from('usuarios')
          .select('email, password, rol')
          .eq('email', correoIngresado)
          .maybeSingle();

      // ✨ 3. VALIDAMOS EXISTENCIA (Mensaje Sutil)
      if (usuarioData == null) {
        _mostrarMensaje('❌ Correo o contraseña incorrectos.', Colors.red);
        setState(() => _estaCargando = false);
        return;
      }

      String passwordEnBaseDeDatos = usuarioData['password'] ?? '';

      // ✨ 4. VALIDAMOS CONTRASEÑA (Mensaje Sutil)
      if (passwordEnBaseDeDatos != passwordEncriptada &&
          passwordEnBaseDeDatos != passwordIngresada) {
        _mostrarMensaje('❌ Correo o contraseña incorrectos.', Colors.red);
        setState(() => _estaCargando = false);
        return;
      }

      // ✨ 5. VALIDACIÓN DE PERMISOS DINÁMICA (Lee tu nueva tabla)
      final String rol = usuarioData['rol'] ?? 'usuario';

      if (rol != 'superadmin') {
        // ✨ TRUCO: Convertimos espacios a guiones bajos (ej: "control de seguridad" -> "control_seguridad")
        final String rolParaBuscar = rol.replaceAll(' ', '_');

        // Buscamos usando .ilike() que ignora mayúsculas y minúsculas
        final permisosData = await supabase
            .from('roles_permisos')
            .select()
            .ilike('rol', rolParaBuscar)
            .maybeSingle();

        // Si el rol no existe en la tabla de permisos
        if (permisosData == null) {
          _mostrarMensaje(
            '⛔ Tu rol ($rol) no está configurado en el sistema.',
            Colors.red.shade800,
          );
          setState(() => _estaCargando = false);
          return;
        }

        // Revisamos todas las columnas. Si encuentra al menos UN "true", lo deja pasar.
        bool tieneAcceso = false;
        permisosData.forEach((llave, valor) {
          // Ignoramos las columnas de sistema y buscamos un true
          if (llave != 'rol' &&
              llave != 'id' &&
              llave != 'created_at' &&
              valor == true) {
            tieneAcceso = true;
          }
        });

        if (!tieneAcceso) {
          _mostrarMensaje(
            '⛔ Acceso denegado. No tienes ningún permiso activado en el Panel.',
            Colors.red.shade800,
          );
          setState(() => _estaCargando = false);
          return;
        }
      }
      // 6. ¡ACCESO CONCEDIDO!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // 1. Quitamos 'const' porque el correo es una variable dinámica
            // 2. Pasamos el 'correoIngresado' al parámetro emailUsuario
            builder: (context) => HomeAdmin(emailUsuario: correoIngresado),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      _mostrarMensaje(
        '❌ Error técnico al conectar con el servidor.',
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  void _mostrarMensaje(String texto, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 15),
                Text(
                  'ITCA Access',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
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
                  // ✨ 1. Tecla 'Enter' pasa al siguiente campo (opcional pero buena práctica)
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  // ✨ 2. Si da Enter aquí, también intentamos iniciar sesión
                  onSubmitted: (_) => _iniciarSesion(),
                ),
                const SizedBox(height: 20),
                // --- CAMPO DE CONTRASEÑA ---
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  // ✨ 3. Cambia el ícono del teclado a "Hecho" o "Go"
                  textInputAction: TextInputAction.done,
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
                  // ✨ 4. LA MAGIA: Al presionar Enter, llama a tu función de login
                  onSubmitted: (_) => _iniciarSesion(),
                ),
                const SizedBox(height: 10),
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

                // Botón de Ingresar
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
