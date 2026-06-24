import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../models/utilisateur_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _ineController = TextEditingController();
  int _etape = 1;
  UtilisateurModel? _utilisateurTrouve;

  @override
  void dispose() {
    _ineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              transform: Matrix4.translationValues(0, -16, 0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: _buildEtape(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Étape 1 sur 4 – Vérification INE',
      'Étape 2 sur 4 – Confirmation identité',
      'Étape 3 sur 4 – Vérification email',
      'Étape 4 sur 4 – Mot de passe',
    ];

    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.only(top: 50, bottom: 36, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (_etape > 1) {
                setState(() => _etape--);
              } else {
                context.go(AppRoutes.login);
              }
            },
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Text('Retour',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Créer mon compte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titles[_etape - 1],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          // Barre de progression
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < _etape
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape() {
    switch (_etape) {
      case 1:
        return _buildEtape1();
      case 2:
        return _buildEtape2();
      case 3:
        return _buildEtape3();
      case 4:
        return _buildEtape4();
      default:
        return _buildEtape1();
    }
  }

  // ÉTAPE 1 — Saisie INE
  Widget _buildEtape1() {
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadge(Icons.badge_outlined, 'Identification'),
        const SizedBox(height: 14),
        const Text('Saisissez votre INE',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        const Text(
          'Votre Identifiant National Étudiant vous a été fourni lors de votre inscription à l\'UJKZ.',
          style: TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
        const SizedBox(height: 20),
        const Text('INE (Identifiant National Étudiant)',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 6),
        CustomTextField(
          controller: _ineController,
          hintText: 'Ex : BF2021XXXXXXXXX',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            border: Border.all(color: const Color(0xFFFFE0A0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_outlined,
                  color: AppTheme.orangeColor, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seuls les doctorants officiellement inscrits à l\'UJKZ peuvent créer un compte.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF555555)),
                ),
              ),
            ],
          ),
        ),
        if (authState.erreur != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(authState.erreur!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Vérifier mon INE',
          isLoading: authState.isLoading,
          onPressed: () async {
            if (_ineController.text.trim().isEmpty) return;
            final utilisateur = await ref
                .read(authProvider.notifier)
                .verifierINE(_ineController.text.trim());
            if (utilisateur != null) {
              setState(() {
                _utilisateurTrouve = utilisateur;
                _etape = 2;
              });
            }
          },
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.login),
            child: const Text.rich(
              TextSpan(
                text: 'Déjà un compte ? ',
                style: TextStyle(fontSize: 12, color: AppTheme.textGray),
                children: [
                  TextSpan(
                    text: 'Se connecter',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ÉTAPE 2 — Confirmation identité
  Widget _buildEtape2() {
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadge(Icons.person_outline, 'Confirmation'),
        const SizedBox(height: 14),
        const Text('Est-ce bien vous ?',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        const Text(
          'Nous avons trouvé un compte correspondant à votre INE.',
          style: TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
        const SizedBox(height: 20),
        // Carte identité masquée
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F0),
            border: Border.all(
                color: AppTheme.primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _utilisateurTrouve?.initiales ?? 'XX',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _utilisateurTrouve?.nomMasque ?? '***** *****',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'INE : ${_ineController.text.substring(0, 6)}·····XXX',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGray),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _utilisateurTrouve?.role.toUpperCase() ?? 'UJKZ',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Oui, c\'est moi',
                isLoading: authState.isLoading,
                onPressed: () {
                  setState(() => _etape = 3);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _etape = 1;
                    _utilisateurTrouve = null;
                    _ineController.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ce n\'est pas moi'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            border: Border.all(color: const Color(0xFFFFE0A0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: AppTheme.orangeColor, size: 15),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pour votre sécurité, le nom est masqué. Un code sera envoyé à votre email.',
                  style:
                  TextStyle(fontSize: 11, color: Color(0xFF555555)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ÉTAPE 3 — Vérification OTP
  Widget _buildEtape3() {
    return _OtpStep(
      email: _utilisateurTrouve?.email ?? '',
      onSuccess: () => setState(() => _etape = 4),
    );
  }

  // ÉTAPE 4 — Mot de passe
  Widget _buildEtape4() {
    return _PasswordStep(
      ine: _ineController.text.trim(),
      onSuccess: () => context.go(AppRoutes.dashboard),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        border: Border.all(color: const Color(0xFFC8DFC8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── ÉTAPE 3 Widget OTP ──────────────────────────────────────────────────────
class _OtpStep extends ConsumerStatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const _OtpStep({required this.email, required this.onSuccess});

  @override
  ConsumerState<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends ConsumerState<_OtpStep> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _otpEnvoye = false;

  @override
  void initState() {
    super.initState();
    _envoyerOTP();
  }

  Future<void> _envoyerOTP() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).envoyerOTP(widget.email);
      setState(() {
        _otpEnvoye = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String get _code =>
      _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadge(),
        const SizedBox(height: 14),
        const Text('Entrez votre code',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        Text(
          'Un code à 6 chiffres a été envoyé à ${_masquerEmail(widget.email)}',
          style:
          const TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
        const SizedBox(height: 24),
        // Champs OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 52,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFFC8DFC8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FBF8),
                ),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  }
                  if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: _envoyerOTP,
            child: const Text(
              'Renvoyer le code',
              style: TextStyle(
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: 'Valider le code',
          isLoading: _isLoading,
          onPressed: () async {
            if (_code.length < 6) return;
            setState(() => _isLoading = true);
            try {
              await ref.read(authServiceProvider).verifierOTP(
                widget.email,
                _code,
              );
              widget.onSuccess();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Code incorrect. Réessayez.')),
                );
              }
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
        ),
      ],
    );
  }

  String _masquerEmail(String email) {
    if (email.isEmpty) return '****@****.***';
    final parts = email.split('@');
    if (parts.length < 2) return email;
    return '${parts[0][0]}*****@${parts[1]}';
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        border: Border.all(color: const Color(0xFFC8DFC8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined,
              color: AppTheme.primaryColor, size: 14),
          SizedBox(width: 6),
          Text('Vérification email',
              style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }
}

// ── ÉTAPE 4 Widget Mot de passe ─────────────────────────────────────────────
class _PasswordStep extends ConsumerStatefulWidget {
  final String ine;
  final VoidCallback onSuccess;

  const _PasswordStep({required this.ine, required this.onSuccess});

  @override
  ConsumerState<_PasswordStep> createState() => _PasswordStepState();
}

class _PasswordStepState extends ConsumerState<_PasswordStep> {
  final _mdpController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  bool get _has8Chars => _mdpController.text.length >= 8;
  bool get _hasMaj =>
      _mdpController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasChiffre =>
      _mdpController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _mdpController.text.contains(RegExp(r'[!@#\$&*~]'));

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F0),
            border: Border.all(color: const Color(0xFFC8DFC8)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  color: AppTheme.primaryColor, size: 14),
              SizedBox(width: 6),
              Text('Sécurisation',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Créez votre mot de passe',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark)),
        const SizedBox(height: 6),
        const Text(
          'Choisissez un mot de passe sécurisé pour protéger votre dossier doctoral.',
          style:
          TextStyle(fontSize: 12, color: AppTheme.textGray),
        ),
        const SizedBox(height: 20),
        const Text('Mot de passe',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 6),
        StatefulBuilder(builder: (context, setLocalState) {
          return CustomTextField(
            controller: _mdpController,
            hintText: '••••••••',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscure1,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure1
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textGray,
              ),
              onPressed: () =>
                  setState(() => _obscure1 = !_obscure1),
            ),
          );
        }),
        const SizedBox(height: 10),
        // Règles
        _buildRegle(_has8Chars, 'Au moins 8 caractères'),
        _buildRegle(_hasMaj, 'Une lettre majuscule'),
        _buildRegle(_hasChiffre, 'Un chiffre'),
        _buildRegle(_hasSpecial, 'Un caractère spécial (!@#\$&*~)'),
        const SizedBox(height: 16),
        const Text('Confirmer le mot de passe',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor)),
        const SizedBox(height: 6),
        CustomTextField(
          controller: _confirmController,
          hintText: '••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscure2,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure2
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textGray,
            ),
            onPressed: () => setState(() => _obscure2 = !_obscure2),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Créer mon compte',
          isLoading: authState.isLoading,
          onPressed: () async {
            if (_mdpController.text != _confirmController.text) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                    Text('Les mots de passe ne correspondent pas.')),
              );
              return;
            }
            if (!_has8Chars || !_hasMaj || !_hasChiffre) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Le mot de passe ne respecte pas les règles.')),
              );
              return;
            }
            final succes = await ref
                .read(authProvider.notifier)
                .creerCompteDoctorant(widget.ine, _mdpController.text);
            if (succes && mounted) widget.onSuccess();
          },
        ),
      ],
    );
  }

  Widget _buildRegle(bool valide, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            valide ? Icons.check_circle : Icons.cancel_outlined,
            color: valide ? AppTheme.primaryColor : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            texte,
            style: TextStyle(
              fontSize: 12,
              color: valide ? AppTheme.primaryColor : AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mdpController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}