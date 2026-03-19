import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RolesPermisosAdminScreen extends StatefulWidget {
  const RolesPermisosAdminScreen({super.key});

  @override
  State<RolesPermisosAdminScreen> createState() =>
      _RolesPermisosAdminScreenState();
}

class _RolesPermisosAdminScreenState extends State<RolesPermisosAdminScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _listaRoles = [];
  bool _estaCargando = true;

  // Mapeo para que los nombres de la base de datos se vean bonitos en pantalla
  final Map<String, String> _nombresBonitos = {
    'ver_instituciones': 'Ver Instituciones',
    'gestionar_instituciones': 'Crear/Editar Instituciones',
    'ver_beacons': 'Ver Mapas y Beacons',
    'gestionar_beacons': 'Dibujar/Editar Beacons',
    'ver_usuarios': 'Ver Lista de Usuarios',
    'gestionar_usuarios': 'Crear/Eliminar Usuarios',
    'resetear_claves': 'Resetear Contraseñas',
  };

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
  }

  Future<void> _cargarPermisos() async {
    try {
      final respuesta = await supabase
          .from('roles_permisos')
          .select()
          .order('rol');
      setState(() {
        _listaRoles = respuesta;
        _estaCargando = false;
      });
    } catch (e) {
      debugPrint("Error cargando permisos: $e");
      setState(() => _estaCargando = false);
    }
  }

  Future<void> _actualizarPermiso(
    String rol,
    String campo,
    bool nuevoValor,
  ) async {
    try {
      // 1. Actualizamos visualmente al instante (para que no se sienta lento)
      setState(() {
        final index = _listaRoles.indexWhere((r) => r['rol'] == rol);
        if (index != -1) {
          _listaRoles[index][campo] = nuevoValor;
        }
      });

      // 2. Guardamos en Supabase en el fondo
      await supabase
          .from('roles_permisos')
          .update({campo: nuevoValor})
          .eq('rol', rol);
    } catch (e) {
      debugPrint("Error actualizando permiso: $e");
      _cargarPermisos(); // Si falla, recargamos los datos reales
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Toma el fondo de tu Home
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Accesos y Permisos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enciende o apaga las funciones a las que cada rol tiene acceso en el Panel Web.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _listaRoles.length,
                itemBuilder: (context, index) {
                  final rolData = _listaRoles[index];
                  return _construirTarjetaRol(rolData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaRol(Map<String, dynamic> rolData) {
    final String nombreRol = rolData['rol'].toString().toUpperCase();

    // Extraemos solo las llaves que son permisos (ignoramos 'rol')
    final permisos = rolData.keys.where((k) => k != 'rol').toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        initiallyExpanded:
            nombreRol == 'CONTROL_SEGURIDAD' || nombreRol == 'ADMINISTRADOR',
        leading: Icon(
          nombreRol == 'SUPERADMIN'
              ? Icons.star
              : nombreRol == 'ADMINISTRADOR'
              ? Icons.manage_accounts
              : nombreRol == 'CONTROL_SEGURIDAD'
              ? Icons.security
              : Icons.person,
          color: Colors.blue.shade700,
          size: 32,
        ),
        title: Text(
          'Rol: $nombreRol',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: const Text('Toca para ver o editar permisos'),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 20,
              runSpacing: 10,
              children: permisos.map((campo) {
                // Si eres Superadmin, todo está bloqueado en "Encendido" por seguridad
                bool esSuperAdmin = nombreRol == 'SUPERADMIN';

                return SizedBox(
                  width:
                      300, // Ancho fijo para que se vean como cuadrícula en web
                  child: SwitchListTile(
                    title: Text(
                      _nombresBonitos[campo] ?? campo,
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: rolData[campo] == true,
                    activeColor: Colors.green,
                    onChanged: esSuperAdmin
                        ? null // El superadmin no se puede apagar a sí mismo
                        : (valor) =>
                              _actualizarPermiso(rolData['rol'], campo, valor),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
