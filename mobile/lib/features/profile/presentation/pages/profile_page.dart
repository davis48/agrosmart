import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/features/profile/presentation/pages/farmer_profile_page.dart';
import 'package:agriculture/features/profile/presentation/pages/buyer_profile_page.dart';

/// Page de profil qui route vers la bonne interface selon le rôle
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Vérifier le rôle de l'utilisateur
        if (state is AuthAuthenticated) {
          final role = state.user.role.toUpperCase();

          // Router vers la page appropriée selon le rôle
          if (role == 'ACHETEUR' || role == 'BUYER') {
            return const BuyerProfilePage();
          } else {
            // PRODUCTEUR ou autre
            return const FarmerProfilePage();
          }
        }

        // Si non authentifié, retourner page vide avec message
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Veuillez vous connecter',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
