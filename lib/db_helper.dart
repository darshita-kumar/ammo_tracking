import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendAmmoEvent({
  required String shootingId,
  required String gun,
  required String ammo,
}) async {
  await FirebaseFirestore.instance
      .collection('shootings')
      .doc(shootingId)
      .collection('events')
      .add({
    'gun':       gun,
    'ammo':      ammo,
    'timestamp': FieldValue.serverTimestamp(),
  });
}