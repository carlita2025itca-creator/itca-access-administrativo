import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lógica responsiva
    double anchoPantalla = MediaQuery.of(context).size.width;
    bool esPantallaPequena = anchoPantalla < 800;

    return ListView(
      children: [
        Text(
          'Dashboard Administrativo',
          style: TextStyle(
            fontSize: esPantallaPequena ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 30),

        if (esPantallaPequena)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tarjetaEstadistica(
                'Beacons Activos',
                '24',
                Icons.sensors,
                Colors.green,
              ),
              const SizedBox(height: 15),
              _tarjetaEstadistica(
                'Alertas Hoy',
                '3',
                Icons.warning_amber,
                Colors.orange,
              ),
              const SizedBox(height: 15),
              _tarjetaEstadistica(
                'Usuarios App',
                '156',
                Icons.person,
                Colors.blue,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _tarjetaEstadistica(
                  'Beacons Activos',
                  '24',
                  Icons.sensors,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _tarjetaEstadistica(
                  'Alertas Hoy',
                  '3',
                  Icons.warning_amber,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _tarjetaEstadistica(
                  'Usuarios App',
                  '156',
                  Icons.person,
                  Colors.blue,
                ),
              ),
            ],
          ),

        const SizedBox(height: 30),

        Container(
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: const Center(
            child: Text(
              'Gráficos de uso y actividad del ITCA',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // Mudamos la tarjeta aquí adentro también
  Widget _tarjetaEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icono, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
