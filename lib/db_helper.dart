import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendAmmoEvent({
  required String troop,
  required String gun,
  required String ammo,
}) async {

  await FirebaseFirestore.instance
      .collection("events")
      .add({
        "troop": troop,
        "gun": gun,
        "ammo": ammo,
        "timestamp": FieldValue.serverTimestamp(),
      });
}