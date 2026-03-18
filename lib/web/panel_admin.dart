import 'package:flutter/material.dart';

class PanelAdminWeb extends StatefulWidget {
  const PanelAdminWeb({super.key});

  @override
  State<PanelAdminWeb> createState() => _PanelAdminWebState();
}

class _PanelAdminWebState extends State<PanelAdminWeb> {
  int _seccionSeleccionada = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. MENU LATERAL (Sidebar)
          NavigationRail(
            selectedIndex: _seccionSeleccionada,
            onDestinationSelected: (int index) {
              setState(() => _seccionSeleccionada = index);
            },
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(
              color: Colors.white,
              size: 30,
            ),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Inicio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bluetooth),
                label: Text('Beacons'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map),
                label: Text('Mapa ITCA'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Usuarios'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: _construirContenido(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirContenido() {
    switch (_seccionSeleccionada) {
      case 1:
        return const Text(
          "Aquí irá la tabla de Beacons vinculados a Firebase",
          style: TextStyle(fontSize: 24),
        );
      default:
        return const Text(
          "Bienvenido al Panel de Administración ITCA Access",
          style: TextStyle(fontSize: 24),
        );
    }
  }
}
