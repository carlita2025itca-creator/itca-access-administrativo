import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistroAccesosAdminScreen extends StatefulWidget {
  final String rolActual;
  final String institucionIdActual;

  const RegistroAccesosAdminScreen({
    super.key,
    required this.rolActual,
    required this.institucionIdActual,
  });

  @override
  State<RegistroAccesosAdminScreen> createState() =>
      _RegistroAccesosAdminScreenState();
}

class _RegistroAccesosAdminScreenState
    extends State<RegistroAccesosAdminScreen> {
  final supabase = Supabase.instance.client;

  bool _estaCargando = true;
  List<Map<String, dynamic>> _accesos = [];
  List<Map<String, dynamic>> _accesosFiltrados = [];

  String _filtroEstado = 'Todos';
  final TextEditingController _buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarAccesos();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  // ================= CARGAR DATOS =================
  Future<void> _cargarAccesos() async {
    setState(() => _estaCargando = true);
    try {
      final List<dynamic> data; // ✨ 1. Preparamos el contenedor de datos vacío

      // ✨ 2. Hacemos las consultas directas y completas según el caso
      if (widget.rolActual != 'superadmin' &&
          widget.institucionIdActual.isNotEmpty) {
        // Consulta para administradores normales (CON filtro de institución)
        data = await supabase
            .from('registro_accesos')
            .select('''
          *,
          usuarios!usuario_id (cedula, nombres, apellidos),
          instituciones!institucion_id (nombre)
        ''')
            .eq('institucion_id', widget.institucionIdActual)
            .order('fecha_solicitud', ascending: false);
      } else {
        // Consulta para el Superadmin (SIN filtro, ve todo)
        data = await supabase
            .from('registro_accesos')
            .select('''
          *,
          usuarios!usuario_id (cedula, nombres, apellidos),
          instituciones!institucion_id (nombre)
        ''')
            .order('fecha_solicitud', ascending: false);
      }

      // ✨ 3. Guardamos los datos en nuestras listas
      setState(() {
        _accesos = List<Map<String, dynamic>>.from(data);
        _accesosFiltrados = _accesos;
      });
    } catch (e) {
      debugPrint('Error al cargar accesos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar los registros: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _estaCargando = false);
    }
  }

  // ================= FILTRAR BÚSQUEDA =================
  void _filtrarDatos() {
    String query = _buscarCtrl.text.toLowerCase();

    setState(() {
      _accesosFiltrados = _accesos.where((acceso) {
        // Filtro por Estado
        bool coincideEstado =
            _filtroEstado == 'Todos' ||
            acceso['estado'].toString().toLowerCase() ==
                _filtroEstado.toLowerCase();

        // Filtro por Texto (Cédula o Nombre)
        final usuario = acceso['usuarios'] ?? {};
        String cedula = usuario['cedula']?.toString().toLowerCase() ?? '';
        String nombres = usuario['nombres']?.toString().toLowerCase() ?? '';
        String apellidos = usuario['apellidos']?.toString().toLowerCase() ?? '';

        bool coincideTexto =
            cedula.contains(query) ||
            nombres.contains(query) ||
            apellidos.contains(query);

        return coincideEstado && coincideTexto;
      }).toList();
    });
  }

  // ================= CAMBIAR ESTADO (APROBAR / RECHAZAR) =================
  Future<void> _cambiarEstado(String idAcceso, String nuevoEstado) async {
    try {
      final datosActualizar = <String, dynamic>{'estado': nuevoEstado};

      // Si lo aprueba, registramos la hora exacta de ingreso
      if (nuevoEstado == 'aprobado') {
        datosActualizar['fecha_ingreso'] = DateTime.now().toIso8601String();
      }

      await supabase
          .from('registro_accesos')
          .update(datosActualizar)
          .eq('id', idAcceso);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado == 'aprobado'
                  ? '✅ Acceso Aprobado'
                  : '⛔ Acceso Rechazado',
            ),
            backgroundColor: nuevoEstado == 'aprobado'
                ? Colors.green
                : Colors.red,
          ),
        );
        _cargarAccesos(); // Recargamos la tabla
      }
    } catch (e) {
      debugPrint('Error al cambiar estado: $e');
    }
  }

  // ================= UTILIDADES DE UI =================
  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return '---';
    try {
      final fecha = DateTime.parse(fechaIso).toLocal();
      // Formato simple: DD/MM/YYYY HH:MM
      return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fechaIso;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registro de Accesos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Control de entradas y salidas mediante Beacons/App.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // --- BARRA DE HERRAMIENTAS (Filtros y Búsqueda) ---
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _buscarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por cédula o nombre...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _filtrarDatos(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _filtroEstado,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['Todos', 'Pendiente', 'Aprobado', 'Rechazado'].map((
                    e,
                  ) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _filtroEstado = val!);
                    _filtrarDatos();
                  },
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: _cargarAccesos,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- TABLA DE DATOS ---
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: _estaCargando
                ? const Center(child: CircularProgressIndicator())
                : _accesosFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron registros de acceso.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade100,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Solicitante',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Institución',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Solicitud',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Ingreso',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Estado',
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
                      rows: _accesosFiltrados.map((acceso) {
                        final usuario = acceso['usuarios'] ?? {};
                        final institucion = acceso['instituciones'] ?? {};
                        final estado = acceso['estado'] ?? 'pendiente';

                        return DataRow(
                          cells: [
                            // Columna 1: Usuario
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${usuario['nombres'] ?? ''} ${usuario['apellidos'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${usuario['cedula'] ?? 'Sin CI'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Columna 2: Institución
                            DataCell(Text(institucion['nombre'] ?? 'N/A')),
                            // Columna 3: Fecha Solicitud
                            DataCell(
                              Text(_formatearFecha(acceso['fecha_solicitud'])),
                            ),
                            // Columna 4: Fecha Ingreso
                            DataCell(
                              Text(_formatearFecha(acceso['fecha_ingreso'])),
                            ),
                            // Columna 5: Estado (Badge de color)
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorEstado(estado).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _colorEstado(estado),
                                  ),
                                ),
                                child: Text(
                                  estado.toUpperCase(),
                                  style: TextStyle(
                                    color: _colorEstado(estado),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            // Columna 6: Acciones
                            DataCell(
                              estado == 'pendiente'
                                  ? Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Aprobar Ingreso',
                                          onPressed: () => _cambiarEstado(
                                            acceso['id'],
                                            'aprobado',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ),
                                          tooltip: 'Rechazar',
                                          onPressed: () => _cambiarEstado(
                                            acceso['id'],
                                            'rechazado',
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      '---',
                                      style: TextStyle(color: Colors.grey),
                                    ), // Si ya se aprobó/rechazó, no hay acciones
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
