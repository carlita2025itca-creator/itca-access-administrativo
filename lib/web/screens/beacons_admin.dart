import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

// 👇 Asegúrate de que las rutas a tu carpeta 'services' sean correctas
import '../services/instituciones_service.dart';
import '../services/beacons_service.dart';

class BeaconsAdminScreen extends StatefulWidget {
  const BeaconsAdminScreen({super.key});

  @override
  State<BeaconsAdminScreen> createState() => _BeaconsAdminScreenState();
}

class _BeaconsAdminScreenState extends State<BeaconsAdminScreen> {
  // ================= VARIABLES =================
  String? _idInstitucionSeleccionada;
  Map<String, dynamic>? _datosInstitucionSeleccionada;

  // Variable para saber qué piso exacto se está subiendo y mostrar el círculo de carga
  int? _nivelSubiendoImagen;

  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPantallaPequena = anchoPantalla < 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= 1. TÍTULO =================
        Text(
          'Gestión de Mapas y Beacons',
          style: TextStyle(
            fontSize: esPantallaPequena ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Selecciona una institución para configurar sus croquis y dispositivos Bluetooth.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 30),

        // ================= 2. SELECTOR DE INSTITUCIÓN =================
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.business, color: Colors.blueGrey, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: InstitucionesService().obtenerInstitucionesStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final instituciones = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Elige la Institución a configurar',
                        border: InputBorder.none,
                      ),
                      value: _idInstitucionSeleccionada,
                      isExpanded: true,
                      hint: const Text('Despliega para seleccionar...'),
                      items: instituciones.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text(
                            '${data['nombre']} (${data['ciudad']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (nuevoId) {
                        setState(() {
                          _idInstitucionSeleccionada = nuevoId;
                          _datosInstitucionSeleccionada =
                              instituciones
                                      .firstWhere((doc) => doc.id == nuevoId)
                                      .data()
                                  as Map<String, dynamic>;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // ================= 3. ÁREA DE PISOS Y CROQUIS =================
        Expanded(
          child: _idInstitucionSeleccionada == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 80, color: Colors.black12),
                      SizedBox(height: 15),
                      Text(
                        'Selecciona una institución arriba para comenzar.',
                        style: TextStyle(color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView(children: _generarTarjetasDePisos()),
        ),
      ],
    );
  }

  // ================= LÓGICA ARQUITECTÓNICA (ORDEN ASCENDENTE) =================
  List<Widget> _generarTarjetasDePisos() {
    if (_datosInstitucionSeleccionada == null) return [];

    int pisos = _datosInstitucionSeleccionada!['pisos'] ?? 1;
    int subsuelos = _datosInstitucionSeleccionada!['subsuelos'] ?? 0;

    List<Widget> tarjetas = [];

    // Subsuelos
    for (int i = subsuelos; i >= 1; i--) {
      tarjetas.add(_construirTarjetaPiso('Subsuelo $i', -i, Icons.garage));
    }
    // Planta Baja
    tarjetas.add(_construirTarjetaPiso('Planta Baja', 0, Icons.storefront));
    // Pisos Superiores
    for (int i = 1; i <= pisos; i++) {
      tarjetas.add(_construirTarjetaPiso('Piso $i', i, Icons.domain));
    }

    return tarjetas;
  }

  // ================= LÓGICA DE SUBIDA A FIREBASE =================
  Future<void> _manejarSubidaCroquis(int nivelLogico) async {
    if (_idInstitucionSeleccionada == null) return;

    // Indicamos que ESTE piso en específico está subiendo
    setState(() => _nivelSubiendoImagen = nivelLogico);

    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (resultado != null) {
        Uint8List fileBytes = resultado.files.first.bytes!;
        String fileName = resultado.files.first.name;

        await BeaconsService().subirCroquis(
          _idInstitucionSeleccionada!,
          nivelLogico,
          fileBytes,
          fileName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Croquis subido correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Al terminar (con éxito o error), limpiamos la variable
      setState(() => _nivelSubiendoImagen = null);
    }
  }

  // ================= VENTANA DE GESTIÓN DE BEACONS =================
  void _abrirGestorBeacons(int nivelLogico) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Configurar Beacons - Nivel $nivelLogico',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '¡Próximo paso!\n\nAquí cargaremos la imagen gigante de tu croquis para que puedas hacer clic y colocar los iconos de los Beacons en el mapa.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // ================= DISEÑO DE CADA TARJETA DE PISO =================
  Widget _construirTarjetaPiso(
    String nombreNivel,
    int nivelLogico,
    IconData icono,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 40, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreNivel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Nivel en sistema: $nivelLogico',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    children: [
                      // 👇 Builder para actualizar solo el botón que se está subiendo
                      Builder(
                        builder: (context) {
                          bool estePisoEstaSubiendo =
                              _nivelSubiendoImagen == nivelLogico;
                          bool sistemaOcupado = _nivelSubiendoImagen != null;

                          return ElevatedButton.icon(
                            onPressed: sistemaOcupado
                                ? null
                                : () => _manejarSubidaCroquis(nivelLogico),
                            icon: estePisoEstaSubiendo
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              estePisoEstaSubiendo
                                  ? 'Subiendo...'
                                  : 'Subir Croquis (PNG/JPG)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              foregroundColor: Colors.orange.shade800,
                              elevation: 0,
                            ),
                          );
                        },
                      ),

                      // 👇 Botón para abrir el gestor de Beacons
                      ElevatedButton.icon(
                        onPressed: () => _abrirGestorBeacons(nivelLogico),
                        icon: const Icon(Icons.bluetooth_connected),
                        label: const Text('Gestionar Beacons'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 👇 Lectura en tiempo real del croquis subido
            StreamBuilder<DocumentSnapshot>(
              stream: BeaconsService().obtenerStreamCroquis(
                _idInstitucionSeleccionada!,
                nivelLogico,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  if (data['url_imagen'] != null) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 30,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Croquis Listo',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['url_imagen'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    );
                  }
                }
                return Column(
                  children: [
                    Icon(Icons.map, size: 30, color: Colors.grey.shade300),
                    const SizedBox(height: 5),
                    const Text(
                      'Sin croquis',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
