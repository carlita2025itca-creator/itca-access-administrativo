import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panel_admin_itca/web/screens/gestor_beacons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class BeaconsAdminScreen extends StatefulWidget {
  final String userRole;
  final String? userInstitutionId; // ✨ 1. Presentamos la variable a Flutter

  const BeaconsAdminScreen({
    super.key,
    required this.userRole,
    required this.userInstitutionId, // ✨ 2. La exigimos como obligatoria
  });

  @override
  State<BeaconsAdminScreen> createState() => _BeaconsAdminScreenState();
}

class _BeaconsAdminScreenState extends State<BeaconsAdminScreen> {
  // ================= CLIENTE SUPABASE =================
  final supabase = Supabase.instance.client;

  // ================= VARIABLES =================
  String? _idInstitucionSeleccionada;
  Map<String, dynamic>? _datosInstitucionSeleccionada;

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
        // ================= 2. SELECTOR DE INSTITUCIÓN =================
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.business, color: Colors.blueGrey, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      // ✨ MAGIA 1: El filtro inteligente para cargar solo las instituciones permitidas
                      stream: (() {
                        if (widget.userRole != 'superadmin' &&
                            widget.userInstitutionId != null &&
                            widget.userInstitutionId!.isNotEmpty) {
                          // Camino A: Si NO es superadmin, le traemos SOLO su institución
                          return supabase
                              .from('instituciones')
                              .stream(primaryKey: ['id'])
                              .eq('id', widget.userInstitutionId!)
                              .order('nombre', ascending: true);
                        } else {
                          // Camino B: Si es superadmin, le traemos TODAS
                          return supabase
                              .from('instituciones')
                              .stream(primaryKey: ['id'])
                              .order('nombre', ascending: true);
                        }
                      })(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final instituciones = snapshot.data!;

                        // ✨ MAGIA 2: Si la lista solo tiene 1 colegio (porque no es superadmin),
                        // lo seleccionamos automáticamente para que cargue el mapa de inmediato.
                        if (instituciones.length == 1 &&
                            _idInstitucionSeleccionada == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _idInstitucionSeleccionada = instituciones
                                    .first['id']
                                    .toString();
                                _datosInstitucionSeleccionada =
                                    instituciones.first;
                              });
                            }
                          });
                        }

                        // Actualizar los datos locales en tiempo real si cambia en DB
                        if (_idInstitucionSeleccionada != null) {
                          try {
                            _datosInstitucionSeleccionada = instituciones
                                .firstWhere(
                                  (inst) =>
                                      inst['id'].toString() ==
                                      _idInstitucionSeleccionada,
                                );
                          } catch (e) {
                            _idInstitucionSeleccionada = null;
                            _datosInstitucionSeleccionada = null;
                          }
                        }

                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Elige la Institución a configurar',
                            border: InputBorder.none,
                          ),
                          initialValue: _idInstitucionSeleccionada,
                          isExpanded: true,
                          hint: const Text('Despliega para seleccionar...'),
                          items: instituciones.map((inst) {
                            return DropdownMenuItem<String>(
                              value: inst['id'].toString(),
                              child: Text(
                                '${inst['nombre']} (${inst['ciudad']})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          // ✨ MAGIA 3: Si no es superadmin, bloqueamos el botón para que sea "Solo lectura" (poniendo null)
                          onChanged: widget.userRole == 'superadmin'
                              ? (nuevoId) {
                                  setState(() {
                                    _idInstitucionSeleccionada = nuevoId;
                                    _datosInstitucionSeleccionada =
                                        instituciones.firstWhere(
                                          (inst) =>
                                              inst['id'].toString() == nuevoId,
                                        );
                                  });
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ✨ CONTROLES PARA AGREGAR/QUITAR PISOS (Protegido solo para superadmin)
              if (_datosInstitucionSeleccionada != null &&
                  widget.userRole == 'superadmin') ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(),
                ),
                const Text(
                  'Estructura del Edificio:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _botonEstructura(
                      Icons.remove,
                      'Quitar Piso',
                      Colors.red,
                      () => _ajustarEstructura('piso', -1),
                    ),
                    _botonEstructura(
                      Icons.add,
                      'Añadir Piso',
                      Colors.green,
                      () => _ajustarEstructura('piso', 1),
                    ),
                    const SizedBox(width: 20),
                    _botonEstructura(
                      Icons.remove,
                      'Quitar Subsuelo',
                      Colors.red,
                      () => _ajustarEstructura('subsuelo', -1),
                    ),
                    _botonEstructura(
                      Icons.add,
                      'Añadir Subsuelo',
                      Colors.green,
                      () => _ajustarEstructura('subsuelo', 1),
                    ),
                  ],
                ),
              ],
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

  // =========================================================================
  // ✨ NUEVAS LÓGICAS: AGREGAR, QUITAR, Y RESETEAR PISOS
  // =========================================================================

  Widget _botonEstructura(
    IconData icono,
    String texto,
    Color color,
    VoidCallback accion,
  ) {
    return OutlinedButton.icon(
      icon: Icon(icono, size: 16, color: color),
      label: Text(texto, style: TextStyle(color: Colors.black87)),
      onPressed: accion,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _ajustarEstructura(String tipo, int cambio) async {
    int pisosActuales = _datosInstitucionSeleccionada!['pisos'] ?? 1;
    int subsuelosActuales = _datosInstitucionSeleccionada!['subsuelos'] ?? 0;

    int nuevosPisos = pisosActuales;
    int nuevosSubsuelos = subsuelosActuales;
    int nivelAfectado = 0;

    if (tipo == 'piso') {
      nuevosPisos += cambio;
      if (nuevosPisos < 1) return; // Mínimo debe haber 1 piso
      nivelAfectado = pisosActuales; // El piso de más arriba
    } else {
      nuevosSubsuelos += cambio;
      if (nuevosSubsuelos < 0) return; // Mínimo 0 subsuelos
      nivelAfectado = -subsuelosActuales; // El subsuelo más profundo
    }

    // Si vamos a QUITAR un piso, advertimos y borramos todo su contenido primero
    if (cambio < 0) {
      bool confirmar = await _mostrarDialogoConfirmacion(
        '⚠️ ¿Eliminar Nivel $nivelAfectado?',
        'Esta acción es irreversible. Se borrará el croquis, los beacons, rutas y oficinas de este piso.',
      );
      if (!confirmar) return;

      // Limpiamos los datos de ese nivel en la DB
      await _limpiarDatosNivel(nivelAfectado, borrarCroquis: true);
    }

    // Actualizamos la institución en Supabase
    await supabase
        .from('instituciones')
        .update({'pisos': nuevosPisos, 'subsuelos': nuevosSubsuelos})
        .eq('id', _idInstitucionSeleccionada!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Estructura actualizada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _limpiarDatosNivel(
    int nivel, {
    required bool borrarCroquis,
  }) async {
    // 1. Borrar Puntos
    await supabase
        .from('rutas')
        .delete()
        .eq('institucion_id', _idInstitucionSeleccionada!)
        .eq('nivel', nivel);
    await supabase
        .from('lugares')
        .delete()
        .eq('institucion_id', _idInstitucionSeleccionada!)
        .eq('nivel', nivel);
    await supabase
        .from('beacons')
        .delete()
        .eq('institucion_id', _idInstitucionSeleccionada!)
        .eq('nivel', nivel);

    // 2. Borrar Croquis (Opcional)
    if (borrarCroquis) {
      final croquisId = '${_idInstitucionSeleccionada}_$nivel';
      await supabase.from('croquis').delete().eq('id', croquisId);
    }
  }

  Future<bool> _mostrarDialogoConfirmacion(
    String titulo,
    String mensaje,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ================= LÓGICA ARQUITECTÓNICA DE TARJETAS =================
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
            // Icono del Nivel
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 40, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 20),

            // Información y Botones
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                        ],
                      ),

                      // ✨ NUEVO: MENÚ DE OPCIONES (Tres Puntitos)
                      // ✨ MAGIA: Si NO eres superadmin, este botón simplemente no existe para ti
                      if (widget.userRole == 'superadmin')
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (valor) async {
                            if (valor == 'reset') {
                              bool conf = await _mostrarDialogoConfirmacion(
                                '🔄 Resetear Nivel $nivelLogico',
                                'Se borrarán todos los beacons, rutas y oficinas de este piso. El croquis NO se borrará.',
                              );
                              if (conf) {
                                await _limpiarDatosNivel(
                                  nivelLogico,
                                  borrarCroquis: false,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ Nivel reseteado limpiecito',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            } else if (valor == 'borrar_croquis') {
                              bool conf = await _mostrarDialogoConfirmacion(
                                '🖼️ Borrar Croquis',
                                '¿Estás seguro de eliminar el plano de este nivel?',
                              );
                              if (conf) {
                                final croquisId =
                                    '${_idInstitucionSeleccionada}_$nivelLogico';
                                await supabase
                                    .from('croquis')
                                    .delete()
                                    .eq('id', croquisId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Croquis eliminado'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Resetear Puntos'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'borrar_croquis',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Borrar Croquis'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('croquis')
                        .stream(primaryKey: ['id'])
                        .eq('institucion_id', _idInstitucionSeleccionada!),
                    builder: (context, snapshot) {
                      String? urlActual;
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final coincidencia = snapshot.data!
                            .where((c) => c['nivel'] == nivelLogico)
                            .toList();
                        if (coincidencia.isNotEmpty)
                          urlActual = coincidencia.first['url_imagen'];
                      }

                      return Wrap(
                        spacing: 15,
                        runSpacing: 10,
                        children: [
                          // === BOTÓN 1: SUBIR ===
                          // ✨ MAGIA: Capa de invisibilidad (Solo superadmin lo ve)
                          if (widget.userRole == 'superadmin')
                            Builder(
                              builder: (context) {
                                bool estePisoEstaSubiendo =
                                    _nivelSubiendoImagen == nivelLogico;
                                return ElevatedButton.icon(
                                  onPressed: _nivelSubiendoImagen != null
                                      ? null
                                      : () =>
                                            _manejarSubidaCroquis(nivelLogico),
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
                                        : (urlActual != null
                                              ? 'Reemplazar Croquis'
                                              : 'Subir Croquis'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade50,
                                    foregroundColor: Colors.orange.shade800,
                                    elevation: 0,
                                  ),
                                );
                              },
                            ),

                          // === BOTÓN 2: GESTIONAR O VER ===
                          ElevatedButton.icon(
                            onPressed: () =>
                                _abrirGestorBeacons(nivelLogico, urlActual),

                            // ✨ MAGIA: Si es superadmin muestra el Bluetooth, si no, muestra un Ojo
                            icon: Icon(
                              widget.userRole == 'superadmin'
                                  ? Icons.bluetooth_connected
                                  : Icons.visibility,
                            ),

                            // ✨ MAGIA: Cambia el texto según quién lo esté leyendo
                            label: Text(
                              widget.userRole == 'superadmin'
                                  ? 'Gestionar Beacons'
                                  : 'Ver Beacons',
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: urlActual != null
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              foregroundColor: urlActual != null
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade400,
                              elevation: 0,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LÓGICA DE SUBIDA A SUPABASE (Se mantiene intacta) =================
  Future<void> _manejarSubidaCroquis(int nivelLogico) async {
    if (_idInstitucionSeleccionada == null) return;
    setState(() => _nivelSubiendoImagen = nivelLogico);

    try {
      FilePickerResult? resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (resultado != null) {
        Uint8List bytes = resultado.files.first.bytes!;
        String extension = resultado.files.first.extension ?? 'png';
        final croquisId = '${_idInstitucionSeleccionada}_$nivelLogico';

        final dataAnterior = await supabase
            .from('croquis')
            .select('url_imagen')
            .eq('id', croquisId)
            .maybeSingle();
        if (dataAnterior != null && dataAnterior['url_imagen'] != null) {
          String urlVieja = dataAnterior['url_imagen'];
          if (urlVieja.contains('itcaaccess_files/')) {
            try {
              final rutaVieja = urlVieja.split('itcaaccess_files/').last;
              await supabase.storage.from('itcaaccess_files').remove([
                rutaVieja,
              ]);
            } catch (e) {
              debugPrint('Error borrando croquis viejo: $e');
            }
          }
        }

        final nombreArchivo =
            'croquis_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final rutaStorage =
            'croquis/$_idInstitucionSeleccionada/nivel_$nivelLogico/$nombreArchivo';

        await supabase.storage
            .from('itcaaccess_files')
            .uploadBinary(
              rutaStorage,
              bytes,
              fileOptions: FileOptions(
                contentType: 'image/$extension',
                upsert: true,
              ),
            );
        final imageUrl = supabase.storage
            .from('itcaaccess_files')
            .getPublicUrl(rutaStorage);

        await supabase.from('croquis').upsert({
          'id': croquisId,
          'institucion_id': _idInstitucionSeleccionada,
          'nivel': nivelLogico,
          'url_imagen': imageUrl,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Croquis actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _nivelSubiendoImagen = null);
    }
  }

  void _abrirGestorBeacons(int nivelLogico, String? urlImagen) {
    if (urlImagen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Sube primero el croquis')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GestorBeaconsScreen(
          institucionId: _idInstitucionSeleccionada!,
          nivel: nivelLogico,
          urlImagen: urlImagen,
          userRole: widget.userRole, // ✨ LE PASAMOS EL ROL AQUÍ
        ),
      ),
    );
  }
}
