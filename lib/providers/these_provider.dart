import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/these_service.dart';
import '../models/these_model.dart';
import '../models/rapport_model.dart';
import '../models/notification_model.dart';
import '../models/manuscrit_model.dart';

final theseServiceProvider = Provider<TheseService>((ref) => TheseService());

// ─── THÈSE ──────────────────────────────────────────────────────────────────

final theseProvider = FutureProvider.family<TheseModel?, String>(
      (ref, doctorantId) async {
    return ref.read(theseServiceProvider).getTheseDoctorant(doctorantId);
  },
);

// ─── RAPPORTS ──────────────────────────────────────────────────────────────

final rapportsProvider = FutureProvider.family<List<RapportModel>, String>(
      (ref, doctorantId) async {
    return ref.read(theseServiceProvider).getRapports(doctorantId);
  },
);

// ─── MANUSCRIT ─────────────────────────────────────────────────────────────

final manuscritProvider = FutureProvider.family<ManuscritModel?, String>(
      (ref, doctorantId) async {
    return ref.read(theseServiceProvider).getManuscrit(doctorantId);
  },
);

// ─── NOTIFICATIONS ────────────────────────────────────────────────────────

final notificationsProvider =
FutureProvider.family<List<NotificationModel>, String>(
      (ref, utilisateurId) async {
    return ref.read(theseServiceProvider).getNotifications(utilisateurId);
  },
);

// ─── DIRECTEURS ───────────────────────────────────────────────────────────

final directeursProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(theseServiceProvider).getDirecteurs();
});

final directeursByEcoleProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, ecole) async {
    return ref.read(theseServiceProvider).getDirecteursByEcole(ecole);
  },
);

// ─── CYCLE DOCTORAL ──────────────────────────────────────────────────────

final etapeTheseProvider = FutureProvider.family<String?, String>(
      (ref, theseId) async {
    final these = await ref.read(theseServiceProvider).getTheseDoctorant(theseId);
    return these?.etapeActuelle;
  },
);

final quitusProvider = FutureProvider.family<Map<String, bool>, String>(
      (ref, theseId) async {
    final these = await ref.read(theseServiceProvider).getTheseDoctorant(theseId);
    return {
      'directeur': these?.quitusDirecteur ?? false,
      'csi': these?.quitusCsi ?? false,
      'validation_admin': these?.validationAdmin ?? false,
    };
  },
);

final anneeEnCoursProvider = FutureProvider.family<int?, String>(
      (ref, theseId) async {
    final these = await ref.read(theseServiceProvider).getTheseDoctorant(theseId);
    return these?.anneeEnCours ?? 1;
  },
);

// ─── VÉRIFICATIONS ────────────────────────────────────────────────────────

final peutDeposerRapportProvider = FutureProvider.family<bool, String>(
      (ref, doctorantId) async {
    final these = await ref.read(theseServiceProvider).getTheseDoctorant(doctorantId);
    if (these == null) return false;
    final etape = these.etapeActuelle ?? 'enregistree';
    final etapesRapport = [
      'rapport_annuel_1',
      'rapport_annuel_1_valide',
      'rapport_annuel_2',
      'rapport_annuel_2_valide',
      'rapport_annuel_3',
      'rapport_annuel_3_valide',
    ];
    return etapesRapport.contains(etape) || etape == 'csi_affecte';
  },
);

final peutDeposerManuscritProvider = FutureProvider.family<bool, String>(
      (ref, doctorantId) async {
    final these = await ref.read(theseServiceProvider).getTheseDoctorant(doctorantId);
    if (these == null) return false;
    final etape = these.etapeActuelle ?? 'enregistree';
    final etapesManuscrit = [
      'manuscrit_depose',
      'quitus_directeur',
      'quitus_csi',
      'validation_admin',
      'rapporteurs_affectes',
      'evaluation_rapporteurs',
      'soutenance_programmee',
      'soutenance_realisee',
    ];
    return etapesManuscrit.contains(etape) || etape == 'rapport_annuel_3_valide';
  },
);