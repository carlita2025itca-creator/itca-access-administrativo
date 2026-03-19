import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Importaciones de tus otras pantallas
import 'package:panel_admin_itca/web/screens/beacons_admin.dart';
import 'package:panel_admin_itca/web/screens/usuarios_admin.dart';
import 'login_admin.dart';
import 'inicio_admin.dart';
import 'instituciones_admin.dart';
import 'package:panel_admin_itca/web/screens/roles_permisos_admin.dart';
// (Asegúrate de que la ruta coincida con cómo tienes las demás)

class HomeAdmin extends StatefulWidget {
  final String emailUsuario; // Recibido desde el Login

  const HomeAdmin({super.key, required this.emailUsuario});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _indiceSeleccionado = 0;
  final supabase = Supabase.instance.client;

  // Variables de perfil
  String _nombreReal = 'Cargando...';
  String _rolReal = 'Usuario';
  String? _fotoUrl;
  bool _subiendoFoto = false;
  // Variable para guardar los permisos dinámicos
  Map<String, dynamic> _misPermisos = {};
  String _miInstitucionId = '';
  String? _idInstitucionReal;

  // Controladores para el diálogo de perfil
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  // ================= CARGA DE DATOS DESDE SUPABASE =================
  Future<void> _cargarDatosUsuario() async {
    try {
      final correo = widget.emailUsuario.trim().toLowerCase();

      final res = await supabase
          .from('usuarios')
          .select()
          .eq('email', correo)
          .maybeSingle();

      if (mounted && res != null) {
        setState(() {
          // 1. Obtenemos los textos crudos de la base de datos
          String nCompleto = res['nombres'] ?? '';
          String aCompleto = res['apellidos'] ?? '';

          // ✨ 2. EL TRUCO ESTÉTICO: Extraemos solo la primera palabra para el banner
          String primerNombre = nCompleto.trim().isNotEmpty
              ? nCompleto.trim().split(' ').first
              : '';
          String primerApellido = aCompleto.trim().isNotEmpty
              ? aCompleto.trim().split(' ').first
              : '';

          // Nombre corto para el diseño principal ("Carla Paillacho")
          _nombreReal = '$primerNombre $primerApellido'.trim();
          _rolReal = res['rol'] ?? 'usuario';
          _fotoUrl = res['foto_url'];

          // 3. Llenamos los controladores con la info COMPLETA por si va a editar su perfil
          _nombreCtrl.text = '$nCompleto $aCompleto'.trim();
          _cedulaCtrl.text = res['cedula']?.toString() ?? '';
          _telefonoCtrl.text = res['telefono']?.toString() ?? '';

          // 4. Guardamos su institución para los filtros
          _miInstitucionId = res['institucion_id']?.toString() ?? '';
        });

        // ✨ MAGIA AQUÍ: Inmediatamente después de saber tu rol, descargamos tus permisos
        await _cargarMisPermisos(_rolReal);
      }
    } catch (e) {
      debugPrint("Error cargando usuario: $e");
    }
  }

  // ================= CARGA DE PERMISOS DINÁMICOS =================
  Future<void> _cargarMisPermisos(String miRol) async {
    try {
      final resPermisos = await supabase
          .from('roles_permisos')
          .select()
          .eq('rol', miRol)
          .maybeSingle();

      if (mounted && resPermisos != null) {
        setState(() {
          _misPermisos = resPermisos; // Guardamos los interruptores en memoria
        });
      }
    } catch (e) {
      debugPrint("Error cargando mis permisos: $e");
    }
  }

  // ================= GESTIÓN DE FOTO DE PERFIL BLINDADA =================
  Future<void> _cambiarFotoPerfil() async {
    final ImagePicker picker = ImagePicker();

    // 1. Seleccionamos la imagen
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen == null) return;

    setState(() => _subiendoFoto = true);

    try {
      // 2. Leemos los bytes (Única forma segura en Web)
      final bytes = await imagen.readAsBytes();
      final ext = imagen.name.split('.').last.toLowerCase();

      // 3. Forzamos un nombre limpio sin espacios ni caracteres raros
      final nombreArchivo =
          'user_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final rutaStorage = 'perfiles/$nombreArchivo';

      debugPrint("🚀 INICIANDO SUBIDA: $rutaStorage");

      // 4. Subimos con la configuración explícita para Web
      await supabase.storage
          .from('perfiles_itca')
          .uploadBinary(
            rutaStorage,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true, // Si ya existe, lo reemplaza
            ),
          );

      // 5. Obtenemos la URL
      final imageUrl = supabase.storage
          .from('perfiles_itca')
          .getPublicUrl(rutaStorage);
      debugPrint("✅ FOTO SUBIDA. URL: $imageUrl");

      // 6. Actualizamos tu tabla de usuarios
      await supabase
          .from('usuarios')
          .update({'foto_url': imageUrl})
          .eq('email', widget.emailUsuario);

      setState(() {
        _fotoUrl = imageUrl;
        _subiendoFoto = false;
      });

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cierra el modal
        _mostrarPerfilFlotante(); // Lo vuelve a abrir actualizado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StorageException catch (se) {
      // ERRORES ESPECÍFICOS DE SUPABASE STORAGE
      setState(() => _subiendoFoto = false);
      debugPrint("❌ ERROR DE SUPABASE STORAGE: ${se.message}");
      debugPrint("❌ CÓDIGO DE ESTADO: ${se.statusCode}");
      _mostrarAlertaError("Error de Storage", se.message);
    } catch (e) {
      // CUALQUIER OTRO ERROR
      setState(() => _subiendoFoto = false);
      debugPrint("❌ ERROR GENERAL: $e");
      _mostrarAlertaError("Error de Aplicación", e.toString());
    }
  }

  // Pequeña función auxiliar para mostrar los errores en pantalla
  void _mostrarAlertaError(String titulo, String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(color: Colors.red)),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  // ================= ACTUALIZAR DATOS DE PERFIL =================
  Future<void> _actualizarPerfil() async {
    try {
      await supabase
          .from('usuarios')
          .update({
            'cedula': _cedulaCtrl.text,
            'telefono': _telefonoCtrl.text,
            // Hemos eliminado 'direccion' de este bloque
          })
          .eq('email', widget.emailUsuario);

      if (mounted) {
        Navigator.pop(context); // Cierra el modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatosUsuario(); // Refresca los datos en pantalla
      }
    } catch (e) {
      debugPrint("Error al actualizar: $e");
    }
  }

  // ================= DIÁLOGO DE PERFIL DINÁMICO =================
  void _mostrarPerfilFlotante() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Mi Perfil ITCA')),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatarSeccion(),
                const SizedBox(height: 20),

                // Nombre Completo (Solo Lectura)
                _inputPerfil(
                  label: 'Nombre Completo',
                  controller: _nombreCtrl,
                  icon: Icons.person,
                  readOnly: true,
                ),
                const SizedBox(height: 15),

                // Cédula (Editable)
                _inputPerfil(
                  label: 'Cédula / ID',
                  controller: _cedulaCtrl,
                  icon: Icons.fingerprint,
                ),
                const SizedBox(height: 15),

                // Teléfono (Editable)
                _inputPerfil(
                  label: 'Teléfono',
                  controller: _telefonoCtrl,
                  icon: Icons.phone,
                ),

                const SizedBox(height: 30),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _actualizarPerfil, // Llama a la función de guardado
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSeccion() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
          child: _fotoUrl == null ? const Icon(Icons.person, size: 50) : null,
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue,
          child: _subiendoFoto
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                  onPressed: _cambiarFotoPerfil,
                ),
        ),
      ],
    );
  }

  Widget _inputPerfil({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: readOnly,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ================= NAVEGACIÓN Y VISTAS =================
  List<Widget> get _pantallas => [
    const InicioScreen(),
    InstitucionesScreen(
      userRole: _rolReal,
      userInstitutionId: _miInstitucionId, // ✨ Le pasamos el dato faltante
    ),
    const BeaconsAdminScreen(),
    // ✨ Actualiza esta línea para enviarle los datos:
    UsuariosAdminScreen(
      rolActual: _rolReal,
      institucionIdActual: _miInstitucionId,
    ),
    const Center(
      child: Text(
        'Módulo de Licencias 🚧',
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    ),
    // ✨ AQUÍ AGREGAMOS LA NUEVA PANTALLA (Índice 5)
    const RolesPermisosAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool esMovil = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ITCA Access Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [_buildUserMenu(), const SizedBox(width: 15)],
      ),
      drawer: esMovil ? Drawer(child: _menuLateral(true)) : null,
      body: Row(
        children: [
          if (!esMovil)
            Container(
              width: 260,
              color: Colors.white,
              child: _menuLateral(false),
            ),

          // ✨ AQUÍ ESTÁ EL CAMBIO: Agregamos el Padding alrededor de la pantalla
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(
                24.0,
              ), // 24 píxeles de margen en todos los lados
              child: _pantallas[_indiceSeleccionado],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton(
      offset: const Offset(0, 50),
      onSelected: (val) =>
          val == 1 ? _mostrarPerfilFlotante() : _cerrarSesion(),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _nombreReal,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _rolReal.toUpperCase(),
                style: const TextStyle(fontSize: 9, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
            child: _fotoUrl == null ? const Icon(Icons.person) : null,
          ),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Mi Perfil'),
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Salir'),
          ),
        ),
      ],
    );
  }

  Widget _menuLateral(bool esDrawer) {
    // Mini-función para saber si un interruptor está encendido (True)
    bool tienePermiso(String permiso) => _misPermisos[permiso] == true;

    return Column(
      children: [
        const SizedBox(height: 20),

        // El inicio siempre lo ven todos los que logran entrar al panel
        _opcion(Icons.home_outlined, 'Inicio', 0, esDrawer),

        // ✨ Los candados mágicos: Solo se dibujan si el interruptor está en TRUE
        if (tienePermiso('ver_instituciones'))
          _opcion(Icons.business_outlined, 'Instituciones', 1, esDrawer),

        if (tienePermiso('ver_beacons'))
          _opcion(Icons.map_outlined, 'Beacons y Mapas', 2, esDrawer),

        const Divider(),

        if (tienePermiso('ver_usuarios'))
          _opcion(Icons.people_outline, 'Usuarios', 3, esDrawer),

        if (_rolReal == 'superadmin') // Licencias temporalmente solo para ti
          _opcion(Icons.vpn_key_outlined, 'Licencias', 4, esDrawer),

        // ✨ La pantalla de configurar interruptores es EXCLUSIVA tuya
        if (_rolReal == 'superadmin') ...[
          const Divider(),
          _opcion(
            Icons.admin_panel_settings_outlined,
            'Roles y Permisos',
            5,
            esDrawer,
          ),
        ],
      ],
    );
  }

  Widget _opcion(IconData icono, String texto, int indice, bool esDrawer) {
    bool sel = _indiceSeleccionado == indice;
    return ListTile(
      leading: Icon(icono, color: sel ? Colors.blue : Colors.grey),
      title: Text(
        texto,
        style: TextStyle(
          color: sel ? Colors.blue : Colors.black,
          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: sel,
      onTap: () {
        setState(() => _indiceSeleccionado = indice);
        if (esDrawer) Navigator.pop(context);
      },
    );
  }

  void _cerrarSesion() async {
    await supabase.auth.signOut();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginAdmin()),
      );
  }
}
