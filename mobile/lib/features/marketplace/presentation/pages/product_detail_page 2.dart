import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/product.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  /// Vérifie si l'utilisateur est authentifié et affiche un dialog sinon
  void _requireAuth(BuildContext context, VoidCallback onAuthenticated) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      onAuthenticated();
    } else {
      _showAuthRequiredDialog(context);
    }
  }

  /// Dialog invitant l'utilisateur à se connecter
  void _showAuthRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez être connecté pour effectuer cette action. '
          'Connectez-vous ou créez un compte pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/login');
            },
            child: const Text('Se connecter'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/role-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.nom),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Bouton Favoris
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return IconButton(
                icon: const Icon(Icons.favorite_border),
                tooltip: 'Ajouter aux favoris',
                onPressed: () => _requireAuth(context, () {
                  // TODO: Implémenter l'ajout aux favoris via le bloc
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ajouté aux favoris !'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }),
              );
            },
          ),
          // Bouton Panier
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                tooltip: 'Ajouter au panier',
                onPressed: () => _requireAuth(context, () {
                  // Ajouter au panier
                  context.read<CartBloc>().add(
                    AddToCart(produitId: product.id, quantite: 1),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.nom} ajouté au panier'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Voir le panier',
                        onPressed: () => context.push('/cart'),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel (simplified as single image for now if list)
            SizedBox(
              height: 300,
              width: double.infinity,
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _getImageUrl(product.images.first),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.nom,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${product.prix.toInt()} FCFA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(product.categorie.toUpperCase()),
                        labelStyle: const TextStyle(fontSize: 10),
                      ),
                      if (product.localisation != null)
                        Chip(
                          avatar: const Icon(Icons.location_on, size: 14),
                          label: Text(product.localisation!),
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                      Chip(
                        label: Text(
                          'Dispo: ${product.quantiteDisponible.toInt()} ${product.unite ?? ""}',
                        ),
                        labelStyle: const TextStyle(fontSize: 10),
                        backgroundColor: Colors.green.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description ?? "Aucune description fournie.",
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    "Vendeur",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text(
                      "Vendeur Partenaire",
                    ), // Placeholder, we only have ID
                    subtitle: Text("Membre depuis ${product.createdAt.year}"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(product.vendeurTelephone),
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchCall(product.vendeurTelephone),
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchSMS(product.vendeurTelephone),
                    icon: const Icon(Icons.sms),
                    label: const Text('SMS'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Internal Chat Navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat interne bientôt disponible'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String? phone) async {
    if (phone == null) return;
    final number = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSMS(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse("sms:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    String baseUrl = Platform.isAndroid
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }
}
