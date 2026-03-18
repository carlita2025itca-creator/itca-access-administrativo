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

  // ================= CONTROLADORES =================
  final TextEditingController _buscadorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _paisController = TextEditingController(
    text: 'Ecuador',
  );
  final TextEditingController _provinciaController = TextEditingController(
    text: 'Imbabura',
  );
  final TextEditingController _ciudadController = TextEditingController(
    text: 'Ibarra',
  );
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _pisosController = TextEditingController();
  final TextEditingController _subsuelosController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String _filtroBusqueda = "";

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
    _paisController.dispose();
    _provinciaController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    _pisosController.dispose();
    _subsuelosController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _paisController.text = 'Ecuador';
    _provinciaController.text = 'Imbabura';
    _ciudadController.text = 'Ibarra';
    _direccionController.clear();
    _pisosController.clear();
    _subsuelosController.clear();
    _contactoController.clear();
    _telefonoController.clear();
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
    _paisController.text = datosActuales['pais'] ?? 'Ecuador';
    _provinciaController.text = datosActuales['provincia'] ?? 'Imbabura';
    _ciudadController.text = datosActuales['ciudad'] ?? 'Ibarra';
    _direccionController.text = datosActuales['direccion'] ?? '';
    _pisosController.text = (datosActuales['pisos'] ?? '').toString();
    _subsuelosController.text = (datosActuales['subsuelos'] ?? '').toString();
    _contactoController.text = datosActuales['contacto'] ?? '';
    _telefonoController.text = datosActuales['telefono'] ?? '';

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
                  width:
                      600, // Más ancho para que quepan las 3 columnas de ubicación
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _campoTexto(
                          _nombreController,
                          'Nombre de Institución',
                          Icons.business,
                        ),
                        const SizedBox(height: 15),

                        // Fila con País, Provincia y Ciudad
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
                              child: _campoTexto(
                                _provinciaController,
                                'Provincia',
                                Icons.map,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _campoTexto(
                                _ciudadController,
                                'Ciudad',
                                Icons.location_city,
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
                              'pais': _paisController.text.trim(),
                              'provincia': _provinciaController.text.trim(),
                              'ciudad': _ciudadController.text.trim(),
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
                                      esEdicion
                                          ? '✅ Actualizada correctamente'
                                          : '✅ Creada correctamente',
                                    ),
                                    backgroundColor: esEdicion
                                        ? Colors.blue
                                        : Colors.green,
                                  ),
                                );
                              }
                              _limpiarFormulario();
                            } catch (e) {
                              debugPrint("Error de Supabase: $e");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('❌ Error al procesar datos'),
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ $nombre eliminada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Error al eliminar'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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

  // ================= DISEÑO PRINCIPAL (UI) =================
  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPantallaPequena = anchoPantalla < 800;

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
                    'Gestiona los lugares donde se instalarán los Beacons.',
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

        // 3. TABLA DE DATOS (SUPABASE REALTIME)
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('instituciones')
                        .stream(primaryKey: ['id'])
                        .order('fecha_registro', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(50.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(50.0),
                          child: Center(
                            child: Text(
                              'Error al cargar datos: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(50.0),
                          child: Center(
                            child: Text(
                              'No hay instituciones registradas',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      }

                      var documentos = snapshot.data!.where((datos) {
                        String nombre = (datos['nombre'] ?? '')
                            .toString()
                            .toLowerCase();
                        String ciudad = (datos['ciudad'] ?? '')
                            .toString()
                            .toLowerCase();
                        return nombre.contains(_filtroBusqueda) ||
                            ciudad.contains(_filtroBusqueda);
                      }).toList();

                      return DataTable(
                        headingRowColor: WidgetStateProperty.resolveWith(
                          (states) => Colors.grey.shade100,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              '#',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Nombre',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Ubicación',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Contacto',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Teléfono',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Acciones',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: List.generate(documentos.length, (index) {
                          var datos = documentos[index];
                          String ubicacionCompleta =
                              "${datos['ciudad'] ?? ''}, ${datos['provincia'] ?? ''}";

                          return _filaInstitucion(
                            index + 1,
                            datos['id'].toString(),
                            datos,
                            datos['nombre'] ?? 'Sin nombre',
                            ubicacionCompleta,
                            datos['contacto'] ?? 'Sin contacto',
                            datos['telefono'] ?? 'N/A',
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= COMPONENTES DE LA TABLA =================
  DataRow _filaInstitucion(
    int numero,
    String idDocumento,
    Map<String, dynamic> datos,
    String nombre,
    String ubicacion,
    String contacto,
    String telf,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(numero.toString(), style: const TextStyle(color: Colors.grey)),
        ),
        DataCell(
          Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(Text(ubicacion)),
        DataCell(Text(contacto)),
        DataCell(Text(telf)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.blue,
                  size: 20,
                ),
                tooltip: 'Editar Institución',
                onPressed: () => _mostrarFormularioEditar(idDocumento, datos),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                tooltip: 'Eliminar Institución',
                onPressed: () => _confirmarEliminacion(idDocumento, nombre),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirBuscador() => TextField(
    controller: _buscadorController,
    decoration: const InputDecoration(
      hintText: 'Buscar por nombre o ciudad...',
      prefixIcon: Icon(Icons.search),
      border: InputBorder
          .none, // Quitamos el borde porque el contenedor ya lo tiene
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
