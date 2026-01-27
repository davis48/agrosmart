import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agriculture/features/auth/domain/entities/user.dart';
import 'package:agriculture/features/parcelles/presentation/bloc/parcelle_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final User? user = (state is AuthAuthenticated) ? state.user : (state is AuthRegistered ? state.user : null);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, user),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                       _buildStatsCard(context),
                       const SizedBox(height: 16),
                       _buildParametersCard(context),
                       const SizedBox(height: 16),
                       _buildSupportCard(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
             onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Mode vocal activé'),
                   backgroundColor: Colors.green,
                   duration: Duration(seconds: 2),
                 ),
               );
             },
             backgroundColor: const Color(0xFFFFC107),
             mini: true,
             child: const Icon(Icons.mic, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF26C6DA), Color(0xFF00ACC1)], // Cyan/Teal
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              user != null ? "${user.nom[0]}${user.prenoms[0]}".toUpperCase() : "EE",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
           ),
           const SizedBox(height: 12),
           Text(
             user != null ? "${user.nom} ${user.prenoms}" : "Evih Elia",
             style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
           ),
           const SizedBox(height: 4),
           const Text(
             "Producteur certifié",
             style: TextStyle(color: Colors.white70, fontSize: 14),
           ),
           const SizedBox(height: 16),
           OutlinedButton.icon(
             onPressed: () => context.push('/edit-profile'),
             icon: const Icon(Icons.edit, color: Colors.white, size: 18),
             label: const Text("Modifier mon profil", style: TextStyle(color: Colors.white)),
             style: OutlinedButton.styleFrom(
               side: const BorderSide(color: Colors.white54),
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Statistiques",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               BlocBuilder<ParcelleBloc, ParcelleState>(
                 builder: (context, state) {
                    String count = "0";
                    String surface = "0ha";
                    if (state is ParcelleLoaded) {
                       count = "${state.parcelles.length}";
                       final total = state.parcelles.fold(0.0, (sum, p) => sum + p.superficie);
                       surface = "${total.toStringAsFixed(1)}ha";
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         _buildStatItem(count, "Parcelles", Colors.green),
                         const SizedBox(width: 20),
                         _buildStatItem(surface, "Surface totale", Colors.blue),
                      ],
                    );
                 }
               ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildStatItem("N/A", "Rendement", Colors.orange), // Not calculated yet
               _buildStatItem("N/A", "Mois d'usage", Colors.purple), // Requires user.createdAt
            ],
          )
        ],
      ),
    );
  }

   // Actually the mockup has a 2x2 grid layout implicitly or 4 items in a row?
   // Screenshot shows:
   // 3 Parcelles        5.2ha Surface totale
   // +18% Rendement     24 Mois d'usage
   // It's a 2x2 grid.

  Widget _buildStatItem(String value, String label, Color color) {
    return SizedBox(
      width: 130, // Fixed width for alignment
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Paramètres",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildSwitchRow(context, "Notifications push", true),
          const Divider(height: 24),
          _buildSwitchRow(context, "Mode vocal", false),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Langue", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              const Text("Français", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        Switch(
          value: value, 
          onChanged: (v) {},
          activeColor: Colors.white,
          activeTrackColor: Colors.green,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
           )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Support",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildSupportButton(context, Icons.phone, "Contacter le support", Colors.green[50]!, Colors.green),
          const SizedBox(height: 12),
          _buildSupportButton(context, Icons.menu_book, "Guide d'utilisation", Colors.blue[50]!, Colors.blue),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 // Logout logic
                 context.go('/onboarding'); // Simple navigation for now, should ideally be via Bloc event
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A80), // Light Red
                foregroundColor: const Color(0xFFC62828), // Dark Red Text
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Deconnexion", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context, IconData icon, String label, Color bgColor, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Adjust background for dark mode to ensure contrast
    final adjustedBgColor = isDark ? iconColor.withOpacity(0.15) : bgColor;
    // Ensure text color is readable against the background
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container( 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: adjustedBgColor, 
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        ],
      ),
    );
  }
}
