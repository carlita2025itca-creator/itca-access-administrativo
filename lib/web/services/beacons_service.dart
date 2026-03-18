import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class BeaconsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Subir la imagen a Storage y guardar la URL en la subcolección
  Future<void> subirCroquis(
    String idInstitucion,
    int nivelLogico,
    Uint8List fileBytes,
    String fileName,
  ) async {
    // Definimos la ruta en Storage
    String rutaStorage = 'croquis/$idInstitucion/piso_${nivelLogico}_$fileName';
    Reference ref = _storage.ref(rutaStorage);

    // Subimos el archivo
    TaskSnapshot uploadTask = await ref.putData(fileBytes);

    // Obtenemos la URL pública
    String urlDescarga = await uploadTask.ref.getDownloadURL();

    // Guardamos en Firestore en la subcolección 'croquis_pisos'
    await _firestore
        .collection('instituciones')
        .doc(idInstitucion)
        .collection('croquis_pisos')
        .doc('nivel_$nivelLogico')
        .set({
          'nivel_logico': nivelLogico,
          'url_imagen': urlDescarga,
          'fecha_actualizacion': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // 2. Obtener la imagen en tiempo real para un piso específico
  Stream<DocumentSnapshot> obtenerStreamCroquis(
    String idInstitucion,
    int nivelLogico,
  ) {
    return _firestore
        .collection('instituciones')
        .doc(idInstitucion)
        .collection('croquis_pisos')
        .doc('nivel_$nivelLogico')
        .snapshots();
  }
}
