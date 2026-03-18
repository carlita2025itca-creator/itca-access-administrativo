import 'package:cloud_firestore/cloud_firestore.dart';

class InstitucionesService {
  // Usamos una referencia limpia
  final CollectionReference _coleccion = FirebaseFirestore.instance.collection(
    'instituciones',
  );

  Stream<QuerySnapshot> obtenerInstitucionesStream() {
    try {
      // Si quieres volver a usar el orden, asegúrate de haber creado el índice en la consola de Firebase
      return _coleccion.orderBy('fecha_registro', descending: true).snapshots();
    } catch (e) {
      print("Error en Stream: $e");
      // Si falla por el índice, devolvemos el stream sin orden para que al menos cargue la app
      return _coleccion.snapshots();
    }
  }

  Future<void> registrarInstitucion(Map<String, dynamic> datos) async {
    datos['fecha_registro'] = FieldValue.serverTimestamp();
    datos['estado'] = 'Activo';
    await _coleccion.add(datos);
  }

  // 3. Actualizar una institución (EDITAR)
  Future<void> actualizarInstitucion(
    String idDocumento,
    Map<String, dynamic> nuevosDatos,
  ) async {
    try {
      await _coleccion.doc(idDocumento).update(nuevosDatos);
    } catch (e) {
      print("Error al actualizar institución: $e");
      throw Exception("No se pudo actualizar la institución");
    }
  }

  // 4. Eliminar una institución (ELIMINAR)
  Future<void> eliminarInstitucion(String idDocumento) async {
    try {
      await _coleccion.doc(idDocumento).delete();
    } catch (e) {
      print("Error al eliminar institución: $e");
      throw Exception("No se pudo eliminar la institución");
    }
  }
}
