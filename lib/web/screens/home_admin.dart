import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_admin.dart';
import 'instituciones_admin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _indiceSeleccionado = 0;
  final supabase = Supabase.instance.client;

  // Variables para mostrar en la interfaz
  String _nombreReal = 'Cargando...';
  String _rolReal = 'Administrador';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // ================= FUNCIÓN MAESTRA DE CARGA =================
  Future<void> _cargarDatosUsuario() async {
    try {
      // 1. En lugar de usar el ID raro, vamos a buscar por los metadatos o el correo.
      // Como en tu tabla tienes la cédula, y probablemente sea tu "password" o identificador,
      // la buscaremos directamente.

      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Buscamos en la tabla usuarios donde la cédula coincida con el nombre de usuario (o correo)
      // Ajuste: Si entras con correo, filtramos por una columna de correo.
      // Si entras con cédula, filtramos por la columna cedula.

      final respuesta = await supabase
          .from('usuarios')
          .select('nombres, apellidos, rol')
          .eq(
            'cedula',
            '1003807334',
          ) // 👈 Lo he puesto fijo para probar, cámbialo si usas otros usuarios
          .maybeSingle();

      if (mounted && respuesta != null) {
        setState(() {
          String n = respuesta['nombres'] ?? '';
          String a = respuesta['apellidos'] ?? '';
          _nombreReal = '$n $a'.trim();
          _rolReal = respuesta['rol'] ?? 'superadmin';
        });
      } else {
        // Si no lo encuentra, mostramos algo por defecto para no dejarlo vacío
        setState(() {
          _nombreReal = "CARLA ESTEFANIA";
          _rolReal = "superadmin";
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        _nombreReal = "CARLA PAILLACHO";
        _rolReal = "superadmin";
      });
    }
  }

  // Lista de pantallas principales
  final List<Widget> _pantallas = [
    const Center(
      child: Text(
        'Panel de Inicio',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    ),
    const InstitucionesScreen(),
    const Center(
      child: Text(
        'Módulo de Beacons',
        style: TextStyle(fontSize: 24, color: Colors.grey),
      ),
    ),
  ];

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginAdmin()),
      );
    }
  }

  // ================= VENTANA FLOTANTE DE PERFIL =================
  void _mostrarPerfilFlotante() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Configuración de Perfil',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blue,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📸 Abriendo galería...'),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                TextFormField(
                  initialValue: _nombreReal,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: "1003807334",
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.fingerprint),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'ITCA Access Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<int>(
            offset: const Offset(0, 50),
            onSelected: (v) =>
                v == 1 ? _mostrarPerfilFlotante() : _cerrarSesion(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _nombreReal,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _rolReal,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    child: Icon(Icons.person, size: 20),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Mi Perfil'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 2,
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Salir', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Center(
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => setState(() {
                _indiceSeleccionado = 0;
                Navigator.pop(context);
              }),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Instituciones'),
              onTap: () => setState(() {
                _indiceSeleccionado = 1;
                Navigator.pop(context);
              }),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Beacons'),
              onTap: () => setState(() {
                _indiceSeleccionado = 2;
                Navigator.pop(context);
              }),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ), // Puedes cambiar el 16.0 para más o menos margen
        child: _pantallas[_indiceSeleccionado],
      ),
    );
  }
}
