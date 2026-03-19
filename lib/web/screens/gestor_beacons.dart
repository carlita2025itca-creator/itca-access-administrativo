import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ModoMapa { beacons, rutas, lugares }

class GestorBeaconsScreen extends StatefulWidget {
  final String institucionId;
  final int nivel;
  final String urlImagen;
  final String userRole; // ✨ 1. Agregamos el rol

  const GestorBeaconsScreen({
    super.key,
    required this.institucionId,
    required this.nivel,
    required this.urlImagen,
    required this.userRole, // ✨ 2. Lo hacemos obligatorio
  });

  @override
  State<GestorBeaconsScreen> createState() => _GestorBeaconsScreenState();
}

class _GestorBeaconsScreenState extends State<GestorBeaconsScreen> {
  final supabase = Supabase.instance.client;

  ModoMapa _modoActual = ModoMapa.beacons;
  String? _nodoSeleccionadoParaRuta;
  String? _idBeaconMoviendo;
  String? _idLugarMoviendo;
  String? _idRutaSeleccionada;

  final _nombreController = TextEditingController();
  final _macController = TextEditingController();

  final GlobalKey _mapaKey = GlobalKey();

  // =========================================================================
  // FÓRMULA MATEMÁTICA: DISTANCIA (Colisiones)
  // =========================================================================
  double _distanciaAlCuadrado(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    double l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
    if (l2 == 0) return (px - x1) * (px - x1) + (py - y1) * (py - y1);
    double t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2;
    t = t.clamp(0.0, 1.0);
    double projX = x1 + t * (x2 - x1);
    double projY = y1 + t * (y2 - y1);
    return (px - projX) * (px - projX) + (py - projY) * (py - projY);
  }

  // =========================================================================
  // LÓGICA DE CLIC EN EL MAPA
  // =========================================================================
  void _alHacerClicEnMapa(
    TapDownDetails detalles,
    List<Map<String, dynamic>> beaconsActuales,
    List<Map<String, dynamic>> rutasActuales,
  ) {
    if (widget.userRole != 'superadmin') return;
    final RenderBox cajaImagen =
        _mapaKey.currentContext!.findRenderObject() as RenderBox;
    final double tapX = detalles.localPosition.dx;
    final double tapY = detalles.localPosition.dy;
    final double w = cajaImagen.size.width;
    final double h = cajaImagen.size.height;

    final double px = tapX / w;
    final double py = tapY / h;

    if (px < 0 || px > 1 || py < 0 || py > 1) return;

    if (_modoActual == ModoMapa.rutas) {
      String? rutaTocada;
      double minD2 = 400.0;

      for (var r in rutasActuales) {
        final bOrigen = beaconsActuales.firstWhere(
          (b) => b['id'] == r['nodo_origen_id'],
          orElse: () => <String, dynamic>{},
        );
        final bDestino = beaconsActuales.firstWhere(
          (b) => b['id'] == r['nodo_destino_id'],
          orElse: () => <String, dynamic>{},
        );

        if (bOrigen.isNotEmpty && bDestino.isNotEmpty) {
          double rx1 = bOrigen['pos_x'] * w;
          double ry1 = bOrigen['pos_y'] * h;
          double rx2 = bDestino['pos_x'] * w;
          double ry2 = bDestino['pos_y'] * h;

          double d2 = _distanciaAlCuadrado(tapX, tapY, rx1, ry1, rx2, ry2);
          if (d2 < minD2) {
            minD2 = d2;
            rutaTocada = r['id'];
          }
        }
      }
      setState(() => _idRutaSeleccionada = rutaTocada);
      return;
    }

    if (_modoActual == ModoMapa.lugares) {
      if (_idLugarMoviendo != null) {
        _guardarNuevaPosicionLugar(px, py);
      } else {
        _mostrarDialogoNuevoLugar(px, py, beaconsActuales);
      }
    } else if (_modoActual == ModoMapa.beacons) {
      if (_idBeaconMoviendo != null) {
        _guardarNuevaPosicionBeacon(px, py);
      } else {
        _mostrarDialogoNuevoBeacon(px, py);
      }
    }
  }

  // =========================================================================
  // 1. MÓDULO BEACONS
  // =========================================================================
  void _mostrarDialogoNuevoBeacon(double x, double y) {
    _nombreController.clear();
    _macController.clear();
    final rssiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth, color: Colors.blue),
            SizedBox(width: 10),
            Text('Nuevo Beacon Físico'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre o Número (ej: 0)',
              ),
            ),
            TextField(
              controller: _macController,
              decoration: const InputDecoration(
                labelText: 'Dirección MAC (Opcional)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rssiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Señal de Llegada Exacta (RSSI)',
                prefixIcon: Icon(Icons.radar, color: Colors.blue),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('beacons').insert({
                'institucion_id': widget.institucionId,
                'nivel': widget.nivel,
                'nombre': _nombreController.text,
                'mac_address': _macController.text,
                'rssi_referencia': int.tryParse(rssiController.text),
                'pos_x': x,
                'pos_y': y,
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _alTocarBeacon(Map<String, dynamic> beacon) {
    if (widget.userRole != 'superadmin') return;
    if (_modoActual == ModoMapa.lugares) return;

    if (_modoActual == ModoMapa.rutas) {
      _gestionarSeleccionNodoRuta(beacon);
    } else if (_modoActual == ModoMapa.beacons) {
      _mostrarDialogoOpcionesBeacon(beacon);
    }
  }

  void _mostrarDialogoOpcionesBeacon(Map<String, dynamic> beacon) {
    _nombreController.text = beacon['nombre'] ?? '';
    _macController.text = beacon['mac_address'] ?? '';
    final rssiController = TextEditingController(
      text: beacon['rssi_referencia']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Editar: ${beacon['nombre']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre o Número'),
            ),
            TextField(
              controller: _macController,
              decoration: const InputDecoration(labelText: 'Dirección MAC'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rssiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Señal de Llegada Exacta (RSSI)',
                prefixIcon: Icon(Icons.radar, color: Colors.blue),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await supabase.from('beacons').delete().eq('id', beacon['id']);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _idBeaconMoviendo = beacon['id']);
                },
                child: const Text('Reubicar'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  await supabase
                      .from('beacons')
                      .update({
                        'nombre': _nombreController.text,
                        'mac_address': _macController.text,
                        'rssi_referencia': int.tryParse(rssiController.text),
                      })
                      .eq('id', beacon['id']);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _guardarNuevaPosicionBeacon(double x, double y) async {
    final id = _idBeaconMoviendo;
    setState(() => _idBeaconMoviendo = null);
    await supabase
        .from('beacons')
        .update({'pos_x': x, 'pos_y': y})
        .eq('id', id!);
  }

  // =========================================================================
  // 2. MÓDULO RUTAS
  // =========================================================================
  void _gestionarSeleccionNodoRuta(Map<String, dynamic> beacon) async {
    if (_nodoSeleccionadoParaRuta == null) {
      setState(() => _nodoSeleccionadoParaRuta = beacon['id']);
    } else {
      if (_nodoSeleccionadoParaRuta == beacon['id']) {
        setState(() => _nodoSeleccionadoParaRuta = null);
        return;
      }
      final origenId = _nodoSeleccionadoParaRuta!;
      final destinoId = beacon['id'];

      final rutaExistente = await supabase
          .from('rutas')
          .select('id')
          .or(
            'and(nodo_origen_id.eq.$origenId,nodo_destino_id.eq.$destinoId),and(nodo_origen_id.eq.$destinoId,nodo_destino_id.eq.$origenId)',
          )
          .maybeSingle();

      if (rutaExistente != null) {
        await supabase.from('rutas').delete().eq('id', rutaExistente['id']);
        setState(() => _idRutaSeleccionada = null);
      } else {
        await supabase.from('rutas').insert({
          'institucion_id': widget.institucionId,
          'nivel': widget.nivel,
          'nodo_origen_id': origenId,
          'nodo_destino_id': destinoId,
        });
      }
      setState(() => _nodoSeleccionadoParaRuta = null);
    }
  }

  // =========================================================================
  // 3. MÓDULO LUGARES
  // =========================================================================
  void _mostrarDialogoNuevoLugar(
    double x,
    double y,
    List<Map<String, dynamic>> beaconsActuales,
  ) {
    final nombreLugarController = TextEditingController();
    final rssi1Controller = TextEditingController();
    final rssi2Controller = TextEditingController();
    String? macSeleccionada1;
    String? macSeleccionada2;

    final beaconsConMac = beaconsActuales
        .where(
          (b) =>
              b['mac_address'] != null &&
              b['mac_address'].toString().trim().isNotEmpty,
        )
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.flag, color: Colors.green),
                SizedBox(width: 10),
                Text('Registrar Nuevo Lugar'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreLugarController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (ej: Baños, Cafetería)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Señal Primaria (Obligatoria)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Seleccionar Beacon'),
                          value: macSeleccionada1,
                          items: beaconsConMac
                              .map<DropdownMenuItem<String>>(
                                (b) => DropdownMenuItem<String>(
                                  value: b['mac_address'].toString(),
                                  child: Text(
                                    '${b['nombre']} (${b['mac_address']})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setStateDialog(() => macSeleccionada1 = val),
                        ),
                        TextField(
                          controller: rssi1Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Intensidad exacta (Ej: -60)',
                            prefixIcon: Icon(Icons.signal_cellular_alt),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Señal Secundaria (Opcional)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Seleccionar segundo Beacon'),
                          value: macSeleccionada2,
                          items: beaconsConMac
                              .map<DropdownMenuItem<String>>(
                                (b) => DropdownMenuItem<String>(
                                  value: b['mac_address'].toString(),
                                  child: Text(
                                    '${b['nombre']} (${b['mac_address']})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setStateDialog(() => macSeleccionada2 = val),
                        ),
                        TextField(
                          controller: rssi2Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Intensidad de apoyo (Ej: -80)',
                            prefixIcon: Icon(Icons.signal_cellular_alt),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (nombreLugarController.text.isEmpty) return;
                  await supabase.from('lugares').insert({
                    'institucion_id': widget.institucionId,
                    'nivel': widget.nivel,
                    'nombre': nombreLugarController.text,
                    'pos_x': x,
                    'pos_y': y,
                    'mac_beacon_1': macSeleccionada1,
                    'rssi_beacon_1': int.tryParse(rssi1Controller.text),
                    'mac_beacon_2': macSeleccionada2,
                    'rssi_beacon_2': int.tryParse(rssi2Controller.text),
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Guardar Lugar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✨ DIÁLOGO PARA EDITAR LUGARES
  void _mostrarDialogoOpcionesLugar(
    Map<String, dynamic> lugar,
    List<Map<String, dynamic>> beaconsActuales,
  ) {
    final nombreLugarController = TextEditingController(
      text: lugar['nombre'] ?? '',
    );
    final rssi1Controller = TextEditingController(
      text: lugar['rssi_beacon_1']?.toString() ?? '',
    );
    final rssi2Controller = TextEditingController(
      text: lugar['rssi_beacon_2']?.toString() ?? '',
    );
    String? macSeleccionada1 = lugar['mac_beacon_1'];
    String? macSeleccionada2 = lugar['mac_beacon_2'];

    final beaconsConMac = beaconsActuales
        .where(
          (b) =>
              b['mac_address'] != null &&
              b['mac_address'].toString().trim().isNotEmpty,
        )
        .toList();

    if (!beaconsConMac.any((b) => b['mac_address'] == macSeleccionada1))
      macSeleccionada1 = null;
    if (!beaconsConMac.any((b) => b['mac_address'] == macSeleccionada2))
      macSeleccionada2 = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text('Editar: ${lugar['nombre']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreLugarController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Lugar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Señal Primaria',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Seleccionar Beacon'),
                          value: macSeleccionada1,
                          items: beaconsConMac
                              .map<DropdownMenuItem<String>>(
                                (b) => DropdownMenuItem<String>(
                                  value: b['mac_address'].toString(),
                                  child: Text(
                                    '${b['nombre']} (${b['mac_address']})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setStateDialog(() => macSeleccionada1 = val),
                        ),
                        TextField(
                          controller: rssi1Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Intensidad exacta (Ej: -60)',
                            prefixIcon: Icon(Icons.signal_cellular_alt),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Señal Secundaria',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Seleccionar segundo Beacon'),
                          value: macSeleccionada2,
                          items: beaconsConMac
                              .map<DropdownMenuItem<String>>(
                                (b) => DropdownMenuItem<String>(
                                  value: b['mac_address'].toString(),
                                  child: Text(
                                    '${b['nombre']} (${b['mac_address']})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setStateDialog(() => macSeleccionada2 = val),
                        ),
                        TextField(
                          controller: rssi2Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Intensidad de apoyo (Ej: -80)',
                            prefixIcon: Icon(Icons.signal_cellular_alt),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await supabase.from('lugares').delete().eq('id', lugar['id']);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Borrar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _idLugarMoviendo = lugar['id']);
                    },
                    child: const Text('Reubicar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (nombreLugarController.text.isEmpty) return;
                      await supabase
                          .from('lugares')
                          .update({
                            'nombre': nombreLugarController.text,
                            'mac_beacon_1': macSeleccionada1,
                            'rssi_beacon_1': int.tryParse(rssi1Controller.text),
                            'mac_beacon_2': macSeleccionada2,
                            'rssi_beacon_2': int.tryParse(rssi2Controller.text),
                          })
                          .eq('id', lugar['id']);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardarNuevaPosicionLugar(double x, double y) async {
    final id = _idLugarMoviendo;
    setState(() => _idLugarMoviendo = null);
    await supabase
        .from('lugares')
        .update({'pos_x': x, 'pos_y': y})
        .eq('id', id!);
  }

  Color _obtenerColorModo() {
    if (_modoActual == ModoMapa.beacons) return Colors.blue;
    if (_modoActual == ModoMapa.rutas) return Colors.orange;
    return Colors.green;
  }

  // =========================================================================
  // INTERFAZ PRINCIPAL
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPantallaPequena = anchoPantalla < 900;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('beacons')
          .stream(primaryKey: ['id'])
          .eq('institucion_id', widget.institucionId),
      builder: (context, snapshotBeacons) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('rutas')
              .stream(primaryKey: ['id'])
              .eq('institucion_id', widget.institucionId),
          builder: (context, snapshotRutas) {
            List<Map<String, dynamic>> beaconsActuales = [];
            if (snapshotBeacons.hasData)
              beaconsActuales = snapshotBeacons.data!
                  .where((b) => b['nivel'] == widget.nivel)
                  .toList();

            List<Map<String, dynamic>> rutasActuales = [];
            if (snapshotRutas.hasData)
              rutasActuales = snapshotRutas.data!
                  .where((r) => r['nivel'] == widget.nivel)
                  .toList();

            return Scaffold(
              appBar: AppBar(
                title: Text('Mapa y Posicionamiento - Nivel ${widget.nivel}'),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 1,
                actions: [
                  if (esPantallaPequena)
                    Builder(
                      builder: (contextBtn) => Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.settings),
                          label: const Text('Herramientas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              Scaffold.of(contextBtn).openEndDrawer(),
                        ),
                      ),
                    ),
                ],
              ),
              endDrawer: esPantallaPequena
                  ? Drawer(
                      width: 350,
                      child: SafeArea(
                        child: _construirPanelHerramientas(
                          beaconsActuales,
                          rutasActuales,
                        ),
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  // 1. ZONA DEL MAPA
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade200,
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            maxScale: 5.0,
                            child: Center(
                              child: GestureDetector(
                                onTapDown: (det) => _alHacerClicEnMapa(
                                  det,
                                  beaconsActuales,
                                  rutasActuales,
                                ),
                                child: Stack(
                                  key: _mapaKey,
                                  children: [
                                    Image.network(widget.urlImagen),
                                    Positioned.fill(
                                      child: _dibujarLineasRutas(
                                        beaconsActuales,
                                        rutasActuales,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: _dibujarLugares(beaconsActuales),
                                    ),
                                    Positioned.fill(
                                      child: _dibujarPuntosBeacons(
                                        beaconsActuales,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // INFO FLOTANTE
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Text(
                                _idRutaSeleccionada != null
                                    ? 'Ruta Seleccionada. Puedes borrarla.'
                                    : _idBeaconMoviendo != null
                                    ? 'Modo: Reubicando Beacon'
                                    : _idLugarMoviendo != null
                                    ? 'Modo: Reubicando Lugar'
                                    : 'Modo: ${_modoActual.name.toUpperCase()}',
                                style: TextStyle(
                                  color: _idRutaSeleccionada != null
                                      ? Colors.redAccent
                                      : _obtenerColorModo(),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. PANEL LATERAL
                  if (!esPantallaPequena)
                    Container(
                      width: 380,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                      child: _construirPanelHerramientas(
                        beaconsActuales,
                        rutasActuales,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // PANEL Y LISTAS
  // =========================================================================
  Widget _construirPanelHerramientas(
    List<Map<String, dynamic>> beacons,
    List<Map<String, dynamic>> rutas,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Herramientas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.blue),
                tooltip: 'Instrucciones',
                onPressed: _mostrarDialogoInstrucciones,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              _botonModo(
                ModoMapa.beacons,
                'Beacons',
                Icons.bluetooth,
                Colors.blue,
              ),
              const SizedBox(width: 5),
              _botonModo(
                ModoMapa.rutas,
                'Rutas',
                Icons.timeline,
                Colors.orange,
              ),
              const SizedBox(width: 5),
              _botonModo(ModoMapa.lugares, 'Lugares', Icons.flag, Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _obtenerColorModo().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _obtenerColorModo().withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: _obtenerColorModo()),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _idBeaconMoviendo != null || _idLugarMoviendo != null
                      ? "Modo Reubicación:\nHaz clic en el mapa para soltar el elemento."
                      : _modoActual == ModoMapa.beacons
                      ? "Agrega Beacons físicos al mapa."
                      : _modoActual == ModoMapa.rutas
                      ? "Toca dos beacons para trazar ruta. Toca una línea en el mapa para seleccionarla."
                      : "Toca el mapa para agregar Lugares (Baños, Cafetería...) y asocia la huella de la señal (RSSI).",
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Divider(),
        Expanded(
          child: _modoActual == ModoMapa.beacons
              ? _listaBeacons(beacons)
              : _modoActual == ModoMapa.rutas
              ? _listaRutas(beacons, rutas)
              : _listaLugares(beacons),
        ),
      ],
    );
  }

  Widget _listaBeacons(List<Map<String, dynamic>> beacons) {
    if (beacons.isEmpty)
      return const Center(
        child: Text(
          'Aún no hay beacons.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    return ListView.builder(
      itemCount: beacons.length,
      itemBuilder: (context, i) {
        final b = beacons[i];
        final rssiInfo = b['rssi_referencia'] != null
            ? 'Llegada: ${b['rssi_referencia']} dBm'
            : 'Sin señal de llegada';
        return ListTile(
          leading: const Icon(Icons.location_on, color: Colors.blue),
          title: Text(
            b['nombre'].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${b['mac_address'] ?? 'Sin MAC'} • $rssiInfo',
            style: const TextStyle(fontSize: 12),
          ),
          // ✨ Si es superadmin muestra el lápiz, si no, no muestra nada (null)
          trailing: widget.userRole == 'superadmin'
              ? IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _mostrarDialogoOpcionesBeacon(b),
                )
              : null,
        );
      },
    );
  }

  Widget _listaRutas(
    List<Map<String, dynamic>> beacons,
    List<Map<String, dynamic>> rutas,
  ) {
    if (rutas.isEmpty)
      return const Center(
        child: Text(
          'No hay rutas creadas.',
          style: TextStyle(color: Colors.grey),
        ),
      );

    return ListView.builder(
      itemCount: rutas.length,
      itemBuilder: (context, i) {
        final r = rutas[i];
        final origen = beacons.firstWhere(
          (b) => b['id'] == r['nodo_origen_id'],
          orElse: () => {'nombre': '?'},
        )['nombre'];
        final destino = beacons.firstWhere(
          (b) => b['id'] == r['nodo_destino_id'],
          orElse: () => {'nombre': '?'},
        )['nombre'];

        bool esSeleccionada = _idRutaSeleccionada == r['id'];

        return ListTile(
          tileColor: esSeleccionada ? Colors.red.shade50 : null,
          leading: Icon(
            Icons.timeline,
            color: esSeleccionada ? Colors.red : Colors.orange,
          ),
          title: Text(
            '$origen ➔ $destino',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: esSeleccionada ? Colors.red : Colors.black,
            ),
          ),
          onTap: () => setState(() => _idRutaSeleccionada = r['id']),
          // ✨ MAGIA: Si es superadmin muestra el basurero, si no, lo oculta (null)
          trailing: widget.userRole == 'superadmin'
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () async {
                    await supabase.from('rutas').delete().eq('id', r['id']);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ Ruta eliminada'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                )
              : null, // <- Aquí está la clave para ocultarlo
        );
      },
    );
  }

  // ✨ AQUÍ ESTÁ LA LISTA DE LUGARES CON EL LÁPIZ DE EDITAR
  Widget _listaLugares(List<Map<String, dynamic>> beaconsActuales) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('lugares')
          .stream(primaryKey: ['id'])
          .eq('institucion_id', widget.institucionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final lugares = snapshot.data!
            .where((o) => o['nivel'] == widget.nivel)
            .toList();
        if (lugares.isEmpty)
          return const Center(
            child: Text(
              'No hay lugares mapeados.',
              style: TextStyle(color: Colors.grey),
            ),
          );

        return ListView.builder(
          itemCount: lugares.length,
          itemBuilder: (context, i) {
            final l = lugares[i];
            return ListTile(
              leading: const Icon(Icons.flag, color: Colors.green),
              title: Text(
                l['nombre'].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'B1: ${l['rssi_beacon_1'] ?? '-'} | B2: ${l['rssi_beacon_2'] ?? '-'}',
                style: const TextStyle(fontSize: 12),
              ),
              // ✨ MAGIA: Si es superadmin muestra los botones, si no, los oculta (null)
              trailing: widget.userRole == 'superadmin'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✨ BOTÓN PARA EDITAR (LÁPIZ AZUL)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 18,
                          ),
                          onPressed: () =>
                              _mostrarDialogoOpcionesLugar(l, beaconsActuales),
                        ),
                        // ✨ BOTÓN DE BASURERO
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () async {
                            await supabase
                                .from('lugares')
                                .delete()
                                .eq('id', l['id']);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🗑️ Lugar eliminado'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  : null, // <- Si NO es superadmin, no dibuja absolutamente nada
            );
          },
        );
      },
    );
  }

  Widget _botonModo(ModoMapa modo, String texto, IconData icono, Color color) {
    bool activo = _modoActual == modo;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _modoActual = modo;
          _nodoSeleccionadoParaRuta = null;
          _idBeaconMoviendo = null;
          _idLugarMoviendo = null;
          _idRutaSeleccionada = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: activo ? color : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(
                icono,
                color: activo ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(height: 5),
              Text(
                texto,
                style: TextStyle(
                  color: activo ? Colors.white : Colors.grey.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoInstrucciones() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Instrucciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Usa el panel de la derecha para administrar tus elementos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DIBUJO EN EL MAPA
  // =========================================================================
  Widget _dibujarLineasRutas(
    List<Map<String, dynamic>> beacons,
    List<Map<String, dynamic>> rutas,
  ) {
    return LayoutBuilder(
      builder: (context, constr) => CustomPaint(
        size: Size(constr.maxWidth, constr.maxHeight),
        painter: RutaPainter(rutas, beacons, _idRutaSeleccionada),
      ),
    );
  }

  Widget _dibujarPuntosBeacons(List<Map<String, dynamic>> beacons) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: beacons.map((b) {
            final double x = b['pos_x'] * constraints.maxWidth;
            final double y = b['pos_y'] * constraints.maxHeight;

            final bool esSeleccionado = _nodoSeleccionadoParaRuta == b['id'];
            final bool esMoviendo = _idBeaconMoviendo == b['id'];

            Color colorPunto = Colors.blue;
            if (esSeleccionado) colorPunto = Colors.orange;
            if (esMoviendo) colorPunto = Colors.purple;

            return Positioned(
              left: x,
              top: y,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -1.0),
                child: Transform.translate(
                  offset: const Offset(0, 8),
                  child: GestureDetector(
                    onTap: () => _alTocarBeacon(b),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            b['nombre'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorPunto,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ✨ DIBUJO DE LUGARES
  Widget _dibujarLugares(List<Map<String, dynamic>> beaconsActuales) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('lugares')
          .stream(primaryKey: ['id'])
          .eq('institucion_id', widget.institucionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final lugaresNivel = snapshot.data!
            .where((o) => o['nivel'] == widget.nivel)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: lugaresNivel.map((ofi) {
                final double x = ofi['pos_x'] * constraints.maxWidth;
                final double y = ofi['pos_y'] * constraints.maxHeight;

                final bool esMoviendo = _idLugarMoviendo == ofi['id'];

                return Positioned(
                  left: x,
                  top: y,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.0),
                    child: Transform.translate(
                      offset: const Offset(0, 8),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.userRole != 'superadmin') return;
                          if (_modoActual == ModoMapa.lugares) {
                            _mostrarDialogoOpcionesLugar(ofi, beaconsActuales);
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: esMoviendo
                                    ? Colors.purple
                                    : Colors.green.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ofi['nombre'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Tooltip(
                              message:
                                  'B1: ${ofi['rssi_beacon_1']} | B2: ${ofi['rssi_beacon_2']}',
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: esMoviendo
                                        ? Colors.purple
                                        : Colors.green,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: esMoviendo
                                      ? Colors.purple
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class RutaPainter extends CustomPainter {
  final List<Map<String, dynamic>> rutas;
  final List<Map<String, dynamic>> beacons;
  final String? rutaSeleccionadaId;

  RutaPainter(this.rutas, this.beacons, this.rutaSeleccionadaId);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ruta in rutas) {
      try {
        final bOrigen = beacons.firstWhere(
          (b) => b['id'] == ruta['nodo_origen_id'],
        );
        final bDestino = beacons.firstWhere(
          (b) => b['id'] == ruta['nodo_destino_id'],
        );

        bool esSeleccionada = ruta['id'] == rutaSeleccionadaId;

        final paint = Paint()
          ..color = esSeleccionada ? Colors.red : Colors.orange.shade300
          ..strokeWidth = esSeleccionada ? 5.0 : 3.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(bOrigen['pos_x'] * size.width, bOrigen['pos_y'] * size.height),
          Offset(
            bDestino['pos_x'] * size.width,
            bDestino['pos_y'] * size.height,
          ),
          paint,
        );
      } catch (e) {}
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
