import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstitucionesScreen extends StatefulWidget {
  const InstitucionesScreen({super.key});

  @override
  State<InstitucionesScreen> createState() => _InstitucionesScreenState();
}

class _InstitucionesScreenState extends State<InstitucionesScreen> {
  // ================= CLIENTE SUPABASE =================
  final supabase = Supabase.instance.client;

  // ================= CONTROLADORES Y ESTADO =================
  final TextEditingController _buscadorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _paisController = TextEditingController(
    text: 'Ecuador',
  );
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _pisosController = TextEditingController();
  final TextEditingController _subsuelosController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _provinciaSeleccionada = 'Imbabura';
  String? _ciudadSeleccionada = 'Ibarra';
  String _filtroBusqueda = "";

  final Map<String, List<String>> _ubicacionesEcuador = {
    'Imbabura': [
      'Ibarra',
      'Otavalo',
      'Cotacachi',
      'Antonio Ante',
      'Urcuquí',
      'Pimampiro',
    ],
    'Pichincha': ['Quito', 'Machachi', 'Cayambe', 'Sangolquí', 'Pedro Moncayo'],
    'Guayas': ['Guayaquil', 'Durán', 'Samborondón', 'Daule', 'Milagro'],
    'Azuay': ['Cuenca', 'Gualaceo', 'Paute', 'Sigsig'],
    'Carchi': [
      'Tulcán',
      'Montúfar',
      'Espejo',
      'Mira',
      'Bolívar',
      'San Pedro de Huaca',
    ],
    'Tungurahua': ['Ambato', 'Baños', 'Pelileo', 'Píllaro'],
    'Manabí': ['Portoviejo', 'Manta', 'Chone', 'Bahía de Caráquez'],
  };

  @override
  void initState() {
    super.initState();
    _buscadorController.addListener(() {
      setState(() {
        _filtroBusqueda = _buscadorController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    _nombreController.dispose();
    _rucController.dispose();
    _paisController.dispose();
    _direccionController.dispose();
    _pisosController.dispose();
    _subsuelosController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _rucController.clear();
    _paisController.text = 'Ecuador';
    _direccionController.clear();
    _pisosController.clear();
    _subsuelosController.clear();
    _contactoController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _provinciaSeleccionada = 'Imbabura';
    _ciudadSeleccionada = 'Ibarra';
  }

  // ================= MODALES (NUEVO Y EDITAR) =================
  void _mostrarFormularioNuevaInstitucion(BuildContext context) {
    _limpiarFormulario();
    _mostrarModalFormulario(context, esEdicion: false, idDocumento: null);
  }

  void _mostrarFormularioEditar(
    String idDocumento,
    Map<String, dynamic> datosActuales,
  ) {
    _nombreController.text = datosActuales['nombre'] ?? '';
    _rucController.text = datosActuales['ruc'] ?? '';
    _paisController.text = datosActuales['pais'] ?? 'Ecuador';
    _direccionController.text = datosActuales['direccion'] ?? '';
    _pisosController.text = (datosActuales['pisos'] ?? '').toString();
    _subsuelosController.text = (datosActuales['subsuelos'] ?? '').toString();
    _contactoController.text = datosActuales['contacto'] ?? '';
    _telefonoController.text = datosActuales['telefono'] ?? '';
    _emailController.text = datosActuales['email'] ?? '';

    String provBD = datosActuales['provincia'] ?? 'Imbabura';
    String ciuBD = datosActuales['ciudad'] ?? 'Ibarra';

    if (_ubicacionesEcuador.containsKey(provBD)) {
      _provinciaSeleccionada = provBD;
      if (_ubicacionesEcuador[provBD]!.contains(ciuBD)) {
        _ciudadSeleccionada = ciuBD;
      } else {
        _ciudadSeleccionada = _ubicacionesEcuador[provBD]!.first;
      }
    } else {
      _provinciaSeleccionada = 'Imbabura';
      _ciudadSeleccionada = 'Ibarra';
    }

    _mostrarModalFormulario(context, esEdicion: true, idDocumento: idDocumento);
  }

  void _mostrarModalFormulario(
    BuildContext context, {
    required bool esEdicion,
    String? idDocumento,
  }) {
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
                    esEdicion ? Icons.edit : Icons.business,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(esEdicion ? 'Editar Institución' : 'Nueva Institución'),
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
                          children: [
                            Expanded(
                              flex: 2,
                              child: _campoTexto(
                                _nombreController,
                                'Nombre de Institución',
                                Icons.business,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 1,
                              child: _campoTexto(
                                _rucController,
                                'RUC',
                                Icons.assignment_ind,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _campoTexto(
                                _paisController,
                                'País',
                                Icons.public,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _provinciaSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Provincia',
                                  prefixIcon: Icon(Icons.map),
                                ),
                                items: _ubicacionesEcuador.keys
                                    .map(
                                      (String p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setStateDialog(() {
                                      _provinciaSeleccionada = val;
                                      _ciudadSeleccionada =
                                          _ubicacionesEcuador[val]!.first;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _ciudadSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                items: _provinciaSeleccionada != null
                                    ? _ubicacionesEcuador[_provinciaSeleccionada]!
                                          .map(
                                            (String c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            ),
                                          )
                                          .toList()
                                    : [],
                                onChanged: (val) => setStateDialog(
                                  () => _ciudadSeleccionada = val,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _campoTexto(
                          _direccionController,
                          'Dirección Exacta',
                          Icons.signpost,
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _campoNumero(
                                _pisosController,
                                'Pisos',
                                Icons.stairs,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _campoNumero(
                                _subsuelosController,
                                'Subsuelos',
                                Icons.arrow_downward,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _campoTexto(
                                _contactoController,
                                'Persona de Contacto',
                                Icons.person,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _campoTexto(
                                _telefonoController,
                                'Teléfono',
                                Icons.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _campoTexto(
                          _emailController,
                          'Correo Electrónico',
                          Icons.email,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                          _limpiarFormulario();
                          Navigator.pop(context);
                        },
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
                            final datos = {
                              'nombre': _nombreController.text.trim(),
                              'ruc': _rucController.text.trim(),
                              'pais': _paisController.text.trim(),
                              'provincia': _provinciaSeleccionada,
                              'ciudad': _ciudadSeleccionada,
                              'direccion': _direccionController.text.trim(),
                              'pisos':
                                  int.tryParse(_pisosController.text.trim()) ??
                                  1,
                              'subsuelos':
                                  int.tryParse(
                                    _subsuelosController.text.trim(),
                                  ) ??
                                  0,
                              'contacto': _contactoController.text.trim(),
                              'telefono': _telefonoController.text.trim(),
                              'email': _emailController.text.trim(),
                            };
                            try {
                              if (esEdicion && idDocumento != null) {
                                await supabase
                                    .from('instituciones')
                                    .update(datos)
                                    .eq('id', idDocumento);
                              } else {
                                await supabase
                                    .from('instituciones')
                                    .insert(datos);
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      esEdicion ? '✅ Actualizada' : '✅ Creada',
                                    ),
                                    backgroundColor: esEdicion
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                );
                              }
                              _limpiarFormulario();
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ Error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
                      : Text(esEdicion ? 'Guardar Cambios' : 'Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= ELIMINAR =================
  void _confirmarEliminacion(String idDocumento, String nombre) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('⚠️ Confirmar Eliminación'),
          content: Text(
            '¿Estás segura de que deseas eliminar permanentemente "$nombre"?',
          ),
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
                  await supabase
                      .from('instituciones')
                      .delete()
                      .eq('id', idDocumento);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ $nombre eliminada'),
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

  // ================= WIDGETS AUXILIARES =================
  Widget _campoTexto(
    TextEditingController controller,
    String label,
    IconData icono,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icono)),
      validator: (value) =>
          value == null || value.isEmpty ? 'Campo requerido' : null,
    );
  }

  Widget _campoNumero(
    TextEditingController controller,
    String label,
    IconData icono,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icono)),
      validator: (value) => value == null || value.isEmpty ? 'Req.' : null,
    );
  }

  // ✨ ================= NUEVO: VENTANA FLOTANTE DE DETALLES ================= ✨
  void _mostrarDetalles(Map<String, dynamic> datos) {
    String fechaRaw = datos['fecha_registro'] ?? '';
    String fechaCorta = fechaRaw.length > 10
        ? fechaRaw.substring(0, 10)
        : 'Desconocida';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 450, // Ancho adecuado para web y móvil
            constraints: const BoxConstraints(
              maxHeight: 600,
            ), // Evita que crezca demasiado
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabecera colorida
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        radius: 25,
                        child: const Icon(Icons.business, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              datos['nombre'] ?? 'Sin Nombre',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'RUC: ${datos['ruc'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Cuerpo desplazable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _seccionDetalle(
                          Icons.calendar_today,
                          'Fecha de Registro',
                          fechaCorta,
                        ),
                        const Divider(height: 30),

                        const Text(
                          '📍 Ubicación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _seccionDetalle(
                          Icons.public,
                          'País',
                          datos['pais'] ?? 'Ecuador',
                        ),
                        _seccionDetalle(
                          Icons.map,
                          'Provincia',
                          datos['provincia'] ?? 'N/A',
                        ),
                        _seccionDetalle(
                          Icons.location_city,
                          'Ciudad',
                          datos['ciudad'] ?? 'N/A',
                        ),
                        _seccionDetalle(
                          Icons.signpost,
                          'Dirección',
                          datos['direccion'] ?? 'No especificada',
                        ),
                        const Divider(height: 30),

                        const Text(
                          '🏢 Edificio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _seccionDetalle(
                                Icons.stairs,
                                'Pisos',
                                '${datos['pisos'] ?? 0}',
                              ),
                            ),
                            Expanded(
                              child: _seccionDetalle(
                                Icons.arrow_downward,
                                'Subsuelos',
                                '${datos['subsuelos'] ?? 0}',
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),

                        const Text(
                          '📞 Contacto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _seccionDetalle(
                          Icons.person,
                          'Responsable',
                          datos['contacto'] ?? 'N/A',
                        ),
                        _seccionDetalle(
                          Icons.phone,
                          'Teléfono',
                          datos['telefono'] ?? 'N/A',
                        ),
                        _seccionDetalle(
                          Icons.email,
                          'Correo Electrónico',
                          datos['email'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _seccionDetalle(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= DISEÑO PRINCIPAL (UI) =================
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
                    'Instituciones Registradas',
                    style: TextStyle(
                      fontSize: esPantallaPequena ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Gestiona la información de todas las instituciones.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            if (!esPantallaPequena) _construirBotonNuevaInstitucion(),
          ],
        ),
        const SizedBox(height: 20),
        if (esPantallaPequena) ...[
          _construirBotonNuevaInstitucion(),
          const SizedBox(height: 20),
        ],

        // BUSCADOR
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(child: _construirBuscador()),
              const SizedBox(width: 15),
              _construirBotonLimpiar(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. TABLA EXPANDIDA Y CENTRADA ✨
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('instituciones')
                    .stream(primaryKey: ['id'])
                    .order('fecha_registro', ascending: false),
                builder: (context, snapshotInst) {
                  if (snapshotInst.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshotInst.hasError)
                    return Center(
                      child: Text(
                        'Error: ${snapshotInst.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  if (!snapshotInst.hasData || snapshotInst.data!.isEmpty)
                    return const Center(
                      child: Text(
                        'No hay instituciones',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    );

                  var documentos = snapshotInst.data!.where((datos) {
                    String nombre = (datos['nombre'] ?? '')
                        .toString()
                        .toLowerCase();
                    String ruc = (datos['ruc'] ?? '').toString().toLowerCase();
                    return nombre.contains(_filtroBusqueda) ||
                        ruc.contains(_filtroBusqueda);
                  }).toList();

                  // ✨ NUEVO: ESCUCHAMOS TAMBIÉN LA TABLA DE BEACONS EN TIEMPO REAL
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase.from('beacons').stream(primaryKey: ['id']),
                    builder: (context, snapshotBeacons) {
                      // Si no han cargado los beacons, usamos una lista vacía para no bloquear la pantalla
                      final todosLosBeacons = snapshotBeacons.data ?? [];

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
                                  headingRowColor:
                                      WidgetStateProperty.resolveWith(
                                        (states) => Colors.blue.shade50,
                                      ),
                                  columnSpacing: 30,
                                  horizontalMargin: 30,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        '#',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Nombre de Institución',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'RUC',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Ubicación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // ✨ NUEVA COLUMNA DE BEACONS
                                    DataColumn(
                                      label: Text(
                                        'Beacons',
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
                                  rows: List.generate(documentos.length, (
                                    index,
                                  ) {
                                    var datos = documentos[index];
                                    String idInstitucion = datos['id']
                                        .toString();
                                    String ubicacionCompleta =
                                        "${datos['ciudad'] ?? ''}, ${datos['provincia'] ?? ''}";

                                    // ✨ MATEMÁTICA: Filtramos y contamos los beacons de esta institución
                                    int cantidadBeacons = todosLosBeacons
                                        .where(
                                          (b) =>
                                              b['institucion_id'].toString() ==
                                              idInstitucion,
                                        )
                                        .length;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            (index + 1).toString(),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.business,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                datos['nombre'] ?? 'Sin nombre',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(datos['ruc'] ?? 'S/N')),
                                        DataCell(Text(ubicacionCompleta)),

                                        // ✨ NUEVA CELDA: INDICADOR VISUAL DE BEACONS (BADGE)
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cantidadBeacons > 0
                                                  ? Colors.green.shade50
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: cantidadBeacons > 0
                                                    ? Colors.green.shade200
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bluetooth,
                                                  size: 14,
                                                  color: cantidadBeacons > 0
                                                      ? Colors.green.shade700
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  cantidadBeacons.toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: cantidadBeacons > 0
                                                        ? Colors.green.shade700
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Tooltip(
                                                message:
                                                    'Ver Detalles Completos',
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue.shade50,
                                                    foregroundColor:
                                                        Colors.blue.shade700,
                                                    elevation: 0,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.visibility,
                                                    size: 18,
                                                  ),
                                                  label: const Text('Ver info'),
                                                  onPressed: () =>
                                                      _mostrarDetalles(datos),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.orange,
                                                  size: 20,
                                                ),
                                                tooltip: 'Editar Institución',
                                                onPressed: () =>
                                                    _mostrarFormularioEditar(
                                                      idInstitucion,
                                                      datos,
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
                                                      idInstitucion,
                                                      datos['nombre'] ?? '',
                                                    ),
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
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirBuscador() => TextField(
    controller: _buscadorController,
    decoration: const InputDecoration(
      hintText: 'Buscar por nombre o RUC...',
      prefixIcon: Icon(Icons.search),
      border: InputBorder.none,
    ),
  );

  Widget _construirBotonLimpiar() => OutlinedButton(
    onPressed: () => _buscadorController.clear(),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: const Text('Limpiar'),
  );

  Widget _construirBotonNuevaInstitucion() => ElevatedButton.icon(
    onPressed: () => _mostrarFormularioNuevaInstitucion(context),
    icon: const Icon(Icons.add),
    label: const Text('Nueva Institución'),
  );
}
