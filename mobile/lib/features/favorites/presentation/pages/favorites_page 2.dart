import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/domain/entities/cart_item.dart';

/// Page des favoris
/// Affiche les produits que l'utilisateur a mis en favoris
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // TODO: Implémenter FavoritesBloc pour récupérer les favoris depuis l'API
  final List<_FavoriteItem> _mockFavorites = [
    _FavoriteItem(
      id: '1',
      name: 'Engrais NPK 15-15-15',
      price: 15000,
      imageUrl: null,
      category: 'Intrants',
      isAvailable: true,
    ),
    _FavoriteItem(
      id: '2',
      name: 'Semences de maïs hybride',
      price: 25000,
      imageUrl: null,
      category: 'Semences',
      isAvailable: true,
    ),
    _FavoriteItem(
      id: '3',
      name: 'Pulvérisateur 16L',
      price: 45000,
      imageUrl: null,
      category: 'Équipements',
      isAvailable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Si non authentifié, afficher invitation à se connecter
        if (authState is! AuthAuthenticated) {
          return _buildNotAuthenticatedView(context, isDark);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mes Favoris'),
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            elevation: 0,
          ),
          body: _mockFavorites.isEmpty
              ? _buildEmptyFavorites(context, isDark)
              : _buildFavoritesList(context, isDark),
        );
      },
    );
  }

  Widget _buildNotAuthenticatedView(BuildContext context, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Connectez-vous pour voir vos favoris',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sauvegardez vos produits préférés et retrouvez-les facilement',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Pas encore de favoris',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parcourez le marketplace et ajoutez des produits à vos favoris',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Explorer le marketplace',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockFavorites.length,
      itemBuilder: (context, index) {
        final item = _mockFavorites[index];
        return _FavoriteItemCard(
          item: item,
          onRemove: () {
            setState(() {
              _mockFavorites.removeAt(index);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} retiré des favoris'),
                action: SnackBarAction(
                  label: 'Annuler',
                  onPressed: () {
                    setState(() {
                      _mockFavorites.insert(index, item);
                    });
                  },
                ),
              ),
            );
          },
          onAddToCart: () {
            context.read<CartBloc>().add(
              AddToLocalCart(
                item: CartItem(
                  id: 'local_${item.id}',
                  produitId: item.id,
                  nom: item.name,
                  prix: item.price,
                  quantite: 1,
                  unite: 'unité',
                  stockDisponible: 100,
                ),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.name} ajouté au panier'),
                action: SnackBarAction(
                  label: 'Voir',
                  onPressed: () => context.push('/cart'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FavoriteItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isAvailable;

  _FavoriteItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.isAvailable,
  });
}

class _FavoriteItemCard extends StatelessWidget {
  final _FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const _FavoriteItemCard({
    required this.item,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.shopping_bag,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(Icons.shopping_bag, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(fontSize: 11, color: Colors.green[700]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      const Spacer(),
                      if (!item.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Indisponible',
                            style: TextStyle(fontSize: 11, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  tooltip: 'Retirer des favoris',
                ),
                if (item.isAvailable)
                  IconButton(
                    onPressed: onAddToCart,
                    icon: Icon(
                      Icons.add_shopping_cart,
                      color: Colors.green[700],
                    ),
                    tooltip: 'Ajouter au panier',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
