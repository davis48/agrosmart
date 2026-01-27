import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agriculture/core/widgets/smart_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/marketplace_bloc.dart';
import 'product_detail_page.dart';
import '../../domain/entities/product.dart';

// Placeholder classes for Search and Filter - To be moved to separate files
class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => Center(child: Text("Résultats pour '$query'"));

  @override
  Widget buildSuggestions(BuildContext context) => const Center(child: Text("Recherchez un produit..."));
}

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: const Column(
        children: [
          Text("Filtrer par catégorie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          // Add filters here
        ],
      ),
    );
  }
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<MarketplaceBloc>()..add(LoadMarketplaceProducts()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Ensure theme background
          body: Stack(
            children: [
              Column(
                children: [
                  Material(
                    color: Theme.of(context).cardColor, // Use theme color
                    child: const TabBar(
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(text: 'Acheter'),
                        Tab(text: 'Louer'),
                      ],
                    ),
                  ),
                  // ... rest (keep mostly same, check indentation)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            showSearch(
                              context: context,
                              delegate: ProductSearchDelegate(),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => const FilterBottomSheet(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
                      builder: (context, state) {
                        if (state is MarketplaceLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is MarketplaceError) {
                          // Improved Error UI
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                                const SizedBox(height: 16),
                                Text(
                                  "Oups !",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    "Impossible de charger les produits pour le moment.",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<MarketplaceBloc>().add(LoadMarketplaceProducts());
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Réessayer"),
                                ),
                              ],
                            ),
                          );
                        } else if (state is MarketplaceLoaded) {
                          final sales = state.products.where((p) => p.description?.toLowerCase().contains('location') != true && p.categorie != 'location').toList();
                          final rentals = state.products.where((p) => p.description?.toLowerCase().contains('location') == true || p.categorie == 'location').toList();

                          return TabBarView(
                            children: [
                              _buildProductGrid(sales, "Aucun produit en vente"),
                              _buildProductGrid(rentals, "Aucun produit en location"),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showAddOptions(context),
                  tooltip: 'Ajouter une annonce',
                  backgroundColor: const Color(0xFF28A745),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sell),
            title: const Text('Vendre un produit'),
            onTap: () {
              Navigator.pop(context);
              context.push('/add-product?type=vente');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Mettre en location'),
            onTap: () {
              Navigator.pop(context);
              context.push('/add-product?type=location');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, String emptyMessage) {
    if (products.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<MarketplaceBloc>().add(LoadMarketplaceProducts());
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: product.images.isNotEmpty
                        ? SmartNetworkImage(
                            imageUrl: _getImageUrl(product.images.first),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product.prix.toInt()} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.categorie.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.localisation ?? 'Non spécifié',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    // Base URL logic (duplicated from ApiClient for now, strictly should be in config)
    String baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
    if (!path.startsWith('/')) path = '/$path';
    return '$baseUrl$path';
  }
}
