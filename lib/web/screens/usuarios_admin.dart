import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // ✨ Para manejar los textos a encriptar
import 'package:crypto/crypto.dart'; // ✨ El motor de encriptación SHA-256
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class UsuariosAdminScreen extends StatefulWidget {
  // ✨ Agregamos estas dos variables
  final String rolActual;
  final String institucionIdActual;

  const UsuariosAdminScreen({
    super.key,
    required this.rolActual,
    required this.institucionIdActual,
  });

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _buscadorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _otradiscapacidadController =
      TextEditingController();

  String? _rolSeleccionado = 'usuario';
  String? _idInstitucionSeleccionada;
  String? _discapacidadSeleccionada = 'Ninguna';

  String _filtroBusqueda = "";
  List<Map<String, dynamic>> _listaInstituciones = [];

  final List<String> _rolesDisponibles = [
    'superadmin',
    'administrador',
    'control_seguridad',
    'usuario',
  ];

  final List<String> _opcionesdiscapacidad = [
    'Ninguna',
    'Visual',
    'Auditiva',
    'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _cargarInstituciones();
    _buscadorController.addListener(() {
      setState(() {
        _filtroBusqueda = _buscadorController.text.toLowerCase();
      });
    });
  }

  Future<void> _cargarInstituciones() async {
    final res = await supabase
        .from('instituciones')
        .select('id, nombre')
        .order('nombre');
    if (mounted) {
      setState(() {
        _listaInstituciones = List<Map<String, dynamic>>.from(res);
      });
    }
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    _cedulaController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _edadController.dispose();
    _otradiscapacidadController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _cedulaController.clear();
    _nombresController.clear();
    _apellidosController.clear();
    _emailController.clear();
    _edadController.clear();
    _rolSeleccionado = 'usuario';
    _idInstitucionSeleccionada = null;
    _otradiscapacidadController.clear();
    _discapacidadSeleccionada = 'Ninguna';
  }

  void _mostrarFormularioUsuario(
    BuildContext context, {
    required bool esEdicion,
    Map<String, dynamic>? datosActuales,
  }) {
    if (esEdicion && datosActuales != null) {
      _cedulaController.text = datosActuales['cedula'] ?? '';
      _nombresController.text = datosActuales['nombres'] ?? '';
      _apellidosController.text = datosActuales['apellidos'] ?? '';
      _emailController.text = datosActuales['email'] ?? '';
      _edadController.text = datosActuales['edad']?.toString() ?? '';
      _rolSeleccionado = datosActuales['rol'] ?? 'usuario';
      _idInstitucionSeleccionada = datosActuales['institucion_id']?.toString();
      String accDB = datosActuales['discapacidad'] ?? 'Ninguna';
      if (_opcionesdiscapacidad.contains(accDB)) {
        _discapacidadSeleccionada = accDB;
        _otradiscapacidadController.clear();
      } else {
        _discapacidadSeleccionada = 'Otra';
        _otradiscapacidadController.text = accDB;
      }
    } else {
      _limpiarFormulario();
    }

    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    esEdicion ? Icons.edit : Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(esEdicion ? 'Editar Usuario' : 'Nuevo Usuario'),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 600,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _campoTextoPersonalizado(
                                controller: _nombresController,
                                label: 'Nombres',
                                icono: Icons.person,
                                formatters: [UpperCaseTextFormatter()],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _campoTextoPersonalizado(
                                controller: _apellidosController,
                                label: 'Apellidos',
                                icono: Icons.person_outline,
                                formatters: [UpperCaseTextFormatter()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _cedulaController,
                                decoration: const InputDecoration(
                                  labelText: 'Cédula',
                                  prefixIcon: Icon(Icons.fingerprint),
                                  counterText: '',
                                ),
                                readOnly: esEdicion,
                                keyboardType: TextInputType.number,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Requerido';
                                  if (value.length != 10)
                                    return 'Debe tener 10 dígitos';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Requerido';
                                  if (!value.contains('@') ||
                                      !value.contains('.'))
                                    return 'Correo inválido';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _edadController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Edad',
                                  prefixIcon: Icon(Icons.cake),
                                  counterText: '',
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Req.'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _discapacidadSeleccionada,
                                decoration: const InputDecoration(
                                  // ✨ Cambiamos la pregunta aquí:
                                  labelText: '¿Presenta alguna discapacidad?',
                                  prefixIcon: Icon(
                                    Icons.accessibility_new,
                                    color: Colors.blue,
                                  ),
                                ),
                                items: _opcionesdiscapacidad.map((acc) {
                                  return DropdownMenuItem<String>(
                                    value: acc,
                                    child: Text(acc),
                                  );
                                }).toList(),
                                onChanged: (val) => setStateDialog(
                                  () => _discapacidadSeleccionada = val,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_discapacidadSeleccionada == 'Otra') ...[
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _otradiscapacidadController,
                            decoration: const InputDecoration(
                              labelText: 'Especifique la discapacidad',
                              prefixIcon: Icon(Icons.edit_note),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Por favor, especifique la discapacidad'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _idInstitucionSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Institución a la que pertenece',
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: _listaInstituciones.map((inst) {
                            return DropdownMenuItem<String>(
                              value: inst['id'].toString(),
                              child: Text(inst['nombre']),
                            );
                          }).toList(),
                          onChanged: (val) => setStateDialog(
                            () => _idInstitucionSeleccionada = val,
                          ),
                          validator: (value) => value == null
                              ? 'Selecciona una institución'
                              : null,
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _obtenerColorRol(
                                _rolSeleccionado!,
                              ).withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: _obtenerColorRol(
                              _rolSeleccionado!,
                            ).withOpacity(0.05),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _rolSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Nivel de Acceso (Rol)',
                              prefixIcon: Icon(Icons.security),
                              border: InputBorder.none,
                            ),
                            items: _rolesDisponibles.map((rol) {
                              return DropdownMenuItem<String>(
                                value: rol,
                                child: Text(
                                  rol.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _obtenerColorRol(rol),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setStateDialog(() => _rolSeleccionado = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: guardando
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setStateDialog(() => guardando = true);

                            final cedulaLimpia = _cedulaController.text.trim();

                            // Preparamos los datos base
                            final datos = {
                              'cedula': cedulaLimpia,
                              'nombres': _nombresController.text.trim(),
                              'apellidos': _apellidosController.text.trim(),
                              'email': _emailController.text
                                  .trim()
                                  .toLowerCase(),
                              'edad': int.tryParse(_edadController.text.trim()),
                              'discapacidad': _discapacidadSeleccionada,
                              'rol': _rolSeleccionado,
                              'institucion_id': _idInstitucionSeleccionada,
                              'discapacidad': _discapacidadSeleccionada,
                              'discapacidad_detalle':
                                  _discapacidadSeleccionada == 'Otra'
                                  ? _otradiscapacidadController.text.trim()
                                  : null, // Si no es Otra, la base de datos lo deja vacío
                              'estado': 'aprobado',
                            };

                            try {
                              if (esEdicion) {
                                // Al editar, NO cambiamos la contraseña, solo los datos.
                                await supabase
                                    .from('usuarios')
                                    .update(datos)
                                    .eq('cedula', cedulaLimpia);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Usuario actualizado'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                // ✨ 1. CREAMOS LA CONTRASEÑA EN TEXTO PLANO PARA MOSTRARLA
                                String inicialRol = _rolSeleccionado!
                                    .substring(0, 1)
                                    .toUpperCase();
                                String passwordGenerada =
                                    '$inicialRol$cedulaLimpia';

                                // ✨ 2. LA ENCRIPTAMOS CON SHA-256
                                var bytes = utf8.encode(
                                  passwordGenerada,
                                ); // Convertimos el texto a bytes
                                String passwordEncriptada = sha256
                                    .convert(bytes)
                                    .toString(); // Aplicamos el hash matemático

                                // ✨ 3. AGREGAMOS EL HASH A LOS DATOS A GUARDAR
                                datos['password'] = passwordEncriptada;

                                // Guardamos todo en la base de datos propia
                                await supabase.from('usuarios').insert(datos);

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✅ Registrado. Su clave temporal es: $passwordGenerada',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 8),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              debugPrint('🚨 ERROR: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '❌ Error. Verifica que la cédula o correo no existan ya.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              setStateDialog(() => guardando = false);
                            }
                          }
                        },
                  child: guardando
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          esEdicion ? 'Guardar Cambios' : 'Registrar Usuario',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= RESETEAR CONTRASEÑA =================
  Future<void> _resetearContrasena(Map<String, dynamic> usuario) async {
    final cedula = usuario['cedula']?.toString().trim() ?? '';
    final rol = usuario['rol']?.toString().trim() ?? 'usuario';
    final email = usuario['email'];

    // Validación de seguridad
    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: El usuario no tiene cédula registrada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 1. Crear la contraseña plana (Ej: Rol "estudiante" y cédula "100" = "E100")
    final letraRol = rol.isNotEmpty ? rol.substring(0, 1).toUpperCase() : 'U';
    final nuevaPasswordPlana = '$letraRol$cedula';

    // 2. Encriptar la nueva contraseña con SHA-256
    var bytes = utf8.encode(nuevaPasswordPlana);
    String passwordEncriptada = sha256.convert(bytes).toString();

    try {
      // 3. Actualizar en Supabase
      await supabase
          .from('usuarios')
          .update({'password': passwordEncriptada})
          .eq('email', email); // Usamos el email como identificador

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Clave reseteada con éxito. La nueva clave es: $nuevaPasswordPlana',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(
              seconds: 6,
            ), // Duración larga para que puedas leerla/copiarla
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al resetear contraseña: $e");
    }
  }

  void _mostrarDialogoResetPassword(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Resetear contraseña?'),
        content: Text(
          'La contraseña de ${usuario['nombres']} volverá a ser la inicial (Primera letra del rol + Cédula).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              _resetearContrasena(
                usuario,
              ); // Llama a la función que hace el trabajo
            },
            child: const Text(
              'Sí, Resetear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacion(String cedula, String nombres) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('⚠️ Confirmar Eliminación'),
          content: Text('¿Eliminar permanentemente el acceso de "$nombres"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await supabase.from('usuarios').delete().eq('cedula', cedula);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ $nombres eliminado'),
                        backgroundColor: Colors.green,
                      ),
                    );
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Error al eliminar'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              child: const Text('Sí, Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Widget _campoTextoPersonalizado({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      inputFormatters: formatters,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icono)),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Requerido' : null,
    );
  }

  Color _obtenerColorRol(String rol) {
    switch (rol) {
      case 'superadmin':
        return Colors.deepPurple;
      case 'administrador':
        return Colors.blue.shade700;
      case 'control de seguridad':
        return Colors.orange.shade700;
      default:
        return Colors.green.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPantallaPequena = anchoPantalla < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Usuarios',
                    style: TextStyle(
                      fontSize: esPantallaPequena ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Administra los niveles de acceso del personal.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            if (!esPantallaPequena)
              ElevatedButton.icon(
                onPressed: () =>
                    _mostrarFormularioUsuario(context, esEdicion: false),
                icon: const Icon(Icons.person_add),
                label: const Text('Nuevo Usuario'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (esPantallaPequena) ...[
          ElevatedButton.icon(
            onPressed: () =>
                _mostrarFormularioUsuario(context, esEdicion: false),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Usuario'),
          ),
          const SizedBox(height: 20),
        ],

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscadorController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, cédula o email...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              OutlinedButton(
                onPressed: () => _buscadorController.clear(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                // ✨ AQUÍ ESTÁ LA MAGIA DEL FILTRO
                // ✨ AQUÍ ESTÁ LA MAGIA DEL FILTRO CORREGIDA
                stream: (() {
                  if (widget.rolActual != 'superadmin') {
                    // Camino A: Si es administrador o guardia, filtramos por su institución
                    return supabase
                        .from('usuarios')
                        .stream(primaryKey: ['cedula'])
                        .eq('institucion_id', widget.institucionIdActual)
                        .order('nombres');
                  } else {
                    // Camino B: Si eres superadmin, traemos a todos sin el filtro .eq()
                    return supabase
                        .from('usuarios')
                        .stream(primaryKey: ['cedula'])
                        .order('nombres');
                  }
                })(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.hasError)
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  if (!snapshot.hasData || snapshot.data!.isEmpty)
                    return const Center(
                      child: Text(
                        'No hay usuarios registrados',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    );

                  var documentos = snapshot.data!.where((datos) {
                    String n = (datos['nombres'] ?? '')
                        .toString()
                        .toLowerCase();
                    String a = (datos['apellidos'] ?? '')
                        .toString()
                        .toLowerCase();
                    String c = (datos['cedula'] ?? '').toString().toLowerCase();
                    String e = (datos['email'] ?? '').toString().toLowerCase();
                    return n.contains(_filtroBusqueda) ||
                        a.contains(_filtroBusqueda) ||
                        c.contains(_filtroBusqueda) ||
                        e.contains(_filtroBusqueda);
                  }).toList();

                  return Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.resolveWith(
                                (states) => Colors.blue.shade50,
                              ),
                              columnSpacing: 30,
                              horizontalMargin: 30,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Usuario',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Cédula',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Institución',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Nivel de Acceso',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Acciones',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: List.generate(documentos.length, (index) {
                                var datos = documentos[index];
                                String nombreCompleto =
                                    "${datos['nombres'] ?? ''} ${datos['apellidos'] ?? ''}";
                                String rol = datos['rol'] ?? 'usuario';
                                String tipoDisc =
                                    datos['discapacidad'] ?? 'Ninguna';
                                String detalleDisc =
                                    datos['discapacidad_detalle'] ?? '';

                                // ✨ MAGIA: Si eligió "Otra", usamos el texto que escribió. Si no, usamos el tipo.
                                String textoMostrar = tipoDisc == 'Otra'
                                    ? detalleDisc
                                    : tipoDisc;

                                String nombreInstitucion = 'Sin Asignar';
                                if (datos['institucion_id'] != null) {
                                  var inst = _listaInstituciones.where(
                                    (i) =>
                                        i['id'].toString() ==
                                        datos['institucion_id'].toString(),
                                  );
                                  if (inst.isNotEmpty)
                                    nombreInstitucion = inst.first['nombre'];
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            backgroundImage:
                                                datos['foto_url'] != null
                                                ? NetworkImage(
                                                    datos['foto_url'],
                                                  )
                                                : null,
                                            child: datos['foto_url'] == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    nombreCompleto,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (tipoDisc !=
                                                      'Ninguna') ...[
                                                    const SizedBox(width: 5),
                                                    Tooltip(
                                                      // ✨ Ahora mostrará "Discapacidad: Visual" o "Discapacidad: Silla de ruedas"
                                                      message:
                                                          'Discapacidad: $textoMostrar',
                                                      child: const Icon(
                                                        Icons.accessibility_new,
                                                        size: 14,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                '${datos['email'] ?? 'Sin email'} • ${datos['edad'] != null ? "${datos['edad']} años" : "Edad N/A"}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(datos['cedula'] ?? 'S/N')),
                                    DataCell(
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.business,
                                            size: 14,
                                            color: Colors.blueGrey,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(nombreInstitucion),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _obtenerColorRol(
                                            rol,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: _obtenerColorRol(
                                              rol,
                                            ).withOpacity(0.5),
                                          ),
                                        ),
                                        child: Text(
                                          rol.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _obtenerColorRol(rol),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            tooltip: 'Editar Usuario',
                                            onPressed: () =>
                                                _mostrarFormularioUsuario(
                                                  context,
                                                  esEdicion: true,
                                                  datosActuales: datos,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Eliminar',
                                            onPressed: () =>
                                                _confirmarEliminacion(
                                                  datos['cedula'],
                                                  nombreCompleto,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.lock_reset,
                                              color: Colors.orange,
                                            ),
                                            tooltip: 'Resetear Contraseña',
                                            onPressed: () =>
                                                _mostrarDialogoResetPassword(
                                                  datos,
                                                ), // usuarioActual es el map del usuario de esa fila
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
