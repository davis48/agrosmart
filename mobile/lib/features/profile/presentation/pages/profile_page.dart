import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';

/// Page de profil unifiée pour tous les rôles
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = state.user;
        final isProducer = user.role.toUpperCase() != 'ACHETEUR';

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context, user, isProducer),
                const SizedBox(height: 20),
                _buildMenuSection(context, isProducer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, bool isProducer) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              isProducer ? Icons.agriculture : Icons.shopping_bag,
              size: 50,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.nom ?? 'Utilisateur',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.telephone ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isProducer ? 'Producteur' : 'Acheteur',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isProducer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.person,
            title: 'Modifier le profil',
            onTap: () => context.push('/edit-profile'),
          ),
          if (isProducer) ...[
            _buildMenuTile(
              context,
              icon: Icons.analytics,
              title: 'Statistiques',
              onTap: () => context.push('/analytics'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.grass,
              title: 'Mes Parcelles',
              onTap: () => context.push('/parcelles'),
            ),
          ],
          if (!isProducer) ...[
            _buildMenuTile(
              context,
              icon: Icons.shopping_cart,
              title: 'Mes Commandes',
              onTap: () => context.push('/orders'),
            ),
            _buildMenuTile(
              context,
              icon: Icons.favorite,
              title: 'Mes Favoris',
              onTap: () => context.push('/favorites'),
            ),
          ],
          _buildMenuTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.settings,
            title: 'Paramètres',
            onTap: () => context.push('/settings'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.help_outline,
            title: 'Support',
            onTap: () => context.push('/support'),
          ),
          _buildMenuTile(
            context,
            icon: Icons.info_outline,
            title: 'À propos',
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 20),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Déconnexion'),
              content: const Text('Voulez-vous vraiment vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<AuthBloc>().add(LogoutRequested());
                    context.go('/login');
                  },
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Se déconnecter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

