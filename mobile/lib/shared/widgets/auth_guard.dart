import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Widget qui protège les actions nécessitant une authentification
///
/// Utilisé pour envelopper des actions comme ajouter au panier,
/// finaliser un achat, etc.
///
/// En mode "guard", il affiche le child si l'utilisateur est authentifié,
/// sinon affiche une invitation à se connecter.
///
/// En mode "action", il vérifie l'authentification avant d'exécuter une action.
class AuthGuard extends StatelessWidget {
  final Widget child;
  final String message;
  final Widget? fallback;

  const AuthGuard({
    super.key,
    required this.child,
    this.message = 'Connectez-vous pour continuer',
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return child;
        }

        // Non authentifié - afficher le fallback ou une invitation à se connecter
        return fallback ?? _buildLoginPrompt(context);
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/role-selection'),
              child: Text(
                'Créer un compte',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension pour faciliter la vérification d'authentification
///
/// Exemple:
/// ```dart
/// context.requireAuth(
///   onAuthenticated: () {
///     // Action à exécuter si authentifié
///   },
/// );
/// ```
extension AuthGuardExtension on BuildContext {
  /// Vérifie si l'utilisateur est authentifié avant d'exécuter une action
  /// Si non authentifié, affiche un dialog d'invitation à se connecter
  void requireAuth({
    required VoidCallback onAuthenticated,
    String message = 'Connectez-vous pour continuer',
  }) {
    final authState = read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      onAuthenticated();
    } else {
      showLoginRequiredDialog(message: message);
    }
  }

  /// Affiche un dialog invitant l'utilisateur à se connecter
  void showLoginRequiredDialog({
    String message = 'Connectez-vous pour continuer',
  }) {
    showDialog(
      context: this,
      builder: (dialogContext) => LoginRequiredDialog(message: message),
    );
  }
}

/// Dialog affiché quand une action requiert l'authentification
class LoginRequiredDialog extends StatelessWidget {
  final String message;

  const LoginRequiredDialog({
    super.key,
    this.message = 'Connectez-vous pour continuer',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 40,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connexion requise',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Plus tard', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push('/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Se connecter'),
        ),
      ],
    );
  }
}
