import 'api_service.dart';

Future<void> sendAmmoEvent({
  required String shootingId,
  required String gun,
  required String ammo,
}) async {
  await ApiService.post('/api/shootings/$shootingId/events', {
    'gun':  gun,
    'ammo': ammo,
  });
}