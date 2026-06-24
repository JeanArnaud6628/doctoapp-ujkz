import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/these_service.dart';
import '../models/these_model.dart';
import '../models/rapport_model.dart';
import '../models/notification_model.dart';
import '../models/manuscrit_model.dart';

final theseServiceProvider = Provider<TheseService>((ref) => TheseService());

// Provider thèse
final theseProvider = FutureProvider.family<TheseModel?, String>(
      (ref, doctorantId) async {
    return ref.read(theseServiceProvider).getTheseDoctorant(doctorantId);
  },
);

// Provider rapports
final rapportsProvider = FutureProvider.family<List<RapportModel>, String>(
      (ref, doctorantId) async {
    return ref.read(theseServiceProvider).getRapports(doctorantId);
  },
);

// Provider manuscrit
final manuscritProvider = FutureProvider.family<ManuscritModel?, String>(
      (ref, doctorantId) async {
    return ref.read(theseServiceProvider).getManuscrit(doctorantId);
  },
);

// Provider notifications
final notificationsProvider =
FutureProvider.family<List<NotificationModel>, String>(
      (ref, utilisateurId) async {
    return ref.read(theseServiceProvider).getNotifications(utilisateurId);
  },
);

// Provider directeurs
final directeursProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(theseServiceProvider).getDirecteurs();
});