import 'package:flutter/material.dart';

class LicenciasScreen extends StatefulWidget {
  const LicenciasScreen({super.key});

  @override
  State<LicenciasScreen> createState() => _LicenciasScreenState();
}

class _LicenciasScreenState extends State<LicenciasScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Panel de Control de Licencias\n(En construcción)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
