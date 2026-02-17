import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/forum_bloc.dart';
import '../../domain/entities/forum_category.dart';
import '../../../../injection_container.dart' as di;
import 'forum_category_page.dart';
import 'forum_search_page.dart';
import 'create_topic_page.dart';

class ForumHomePageV2 extends StatefulWidget {
  const ForumHomePageV2({super.key});

  @override
  State<ForumHomePageV2> createState() => _ForumHomePageV2State();
}

class _ForumHomePageV2State extends State<ForumHomePageV2>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  // ignore: unused_field
  final String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ForumBloc>()..add(LoadForumCategories()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180,
                floating: true,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D32),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Forum AgroSmart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Partagez, apprenez et entraidez-vous',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => _openSearch(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => _showNotifications(context),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'my_topics',
                        child: ListTile(
                          leading: Icon(Icons.article),
                          title: Text('Mes sujets'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'my_answers',
                        child: ListTile(
                          leading: Icon(Icons.question_answer),
                          title: Text('Mes réponses'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'bookmarks',
                        child: ListTile(
                          leading: Icon(Icons.bookmark),
                          title: Text('Favoris'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'rules',
                        child: ListTile(
                          leading: Icon(Icons.gavel),
                          title: Text('Règles du forum'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Accueil'),
                    Tab(text: 'Populaire'),
                    Tab(text: 'Récent'),
                    Tab(text: 'Non résolu'),
                  ],
                ),
              ),
            ];
          },
          body: BlocBuilder<ForumBloc, ForumState>(
            builder: (context, state) {
              if (state is ForumLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ForumCategoriesLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHomeTab(context, state.categories),
                    _buildPopularTab(context),
                    _buildRecentTab(context),
                    _buildUnsolvedTab(context),
                  ],
                );
              } else if (state is ForumError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text('Erreur: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ForumBloc>().add(LoadForumCategories());
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'forum_new_topic_fab',
          onPressed: () => _createNewTopic(context),
          backgroundColor: const Color(0xFF2E7D32),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nouveau sujet',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, List<ForumCategory> categories) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ForumBloc>().add(LoadForumCategories());
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats rapides
            _buildQuickStats(),
            const SizedBox(height: 24),

            // Catégories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Catégories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(onPressed: () {}, child: const Text('Voir tout')),
              ],
            ),
            const SizedBox(height: 12),
            _buildCategoriesGrid(context, categories),
            const SizedBox(height: 24),

            // Discussions populaires
            const Text(
              'Discussions du moment 🔥',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHotTopicsList(),

            const SizedBox(height: 24),

            // Experts actifs
            const Text(
              'Experts actifs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildActiveExperts(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people, '1,234', 'Membres'),
          _buildStatItem(Icons.article, '567', 'Sujets'),
          _buildStatItem(Icons.chat_bubble, '8,901', 'Réponses'),
          _buildStatItem(Icons.check_circle, '432', 'Résolus'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    List<ForumCategory> categories,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _CategoryCard(
          category: cat,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ForumCategoryPage(category: cat),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHotTopicsList() {
    // Mock data - en production, viendrait du BLoC
    final hotTopics = [
      _MockTopic(
        title: 'Comment lutter contre la cochenille sur le cacao?',
        author: 'Kouamé Jean',
        replies: 23,
        views: 156,
        isHot: true,
        isSolved: false,
      ),
      _MockTopic(
        title: 'Meilleur moment pour la taille des cacaoyers',
        author: 'Aminata Diallo',
        replies: 18,
        views: 89,
        isHot: true,
        isSolved: true,
      ),
      _MockTopic(
        title: 'Expérience avec l\'irrigation goutte à goutte',
        author: 'Ibrahim Traoré',
        replies: 31,
        views: 234,
        isHot: true,
        isSolved: false,
      ),
    ];

    return Column(
      children: hotTopics.map((topic) => _HotTopicCard(topic: topic)).toList(),
    );
  }

  Widget _buildActiveExperts() {
    final experts = [
      _MockExpert(name: 'Dr. Konan', specialty: 'Cacao', answers: 156),
      _MockExpert(name: 'Mme Bamba', specialty: 'Hévéa', answers: 123),
      _MockExpert(name: 'M. Coulibaly', specialty: 'Maraîchage', answers: 98),
      _MockExpert(name: 'Ing. Yao', specialty: 'Irrigation', answers: 87),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: experts.length,
        itemBuilder: (context, index) {
          final expert = experts[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    expert.name[0],
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  expert.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${expert.answers} réponses',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularTab(BuildContext context) {
    return _buildFilteredTopicsList(
      context,
      filter: 'popular',
      emptyMessage: 'Aucune discussion populaire',
    );
  }

  Widget _buildRecentTab(BuildContext context) {
    return _buildFilteredTopicsList(
      context,
      filter: 'recent',
      emptyMessage: 'Aucune discussion récente',
    );
  }

  Widget _buildUnsolvedTab(BuildContext context) {
    return _buildFilteredTopicsList(
      context,
      filter: 'unsolved',
      emptyMessage: 'Toutes les questions ont été résolues! 🎉',
    );
  }

  Widget _buildFilteredTopicsList(
    BuildContext context, {
    required String filter,
    required String emptyMessage,
  }) {
    // En production, chargerait les données filtrées depuis le BLoC
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _TopicListItem(
          topic: _MockTopic(
            title: 'Sujet de discussion #${index + 1}',
            author: 'Utilisateur ${index + 1}',
            replies: (index + 1) * 3,
            views: (index + 1) * 15,
            isHot: index < 3,
            isSolved: index % 3 == 0,
          ),
        );
      },
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForumSearchPage()),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNotificationItem(
              icon: Icons.reply,
              title: 'Nouvelle réponse',
              subtitle: 'Kouamé a répondu à votre sujet',
              time: 'Il y a 5 min',
            ),
            _buildNotificationItem(
              icon: Icons.thumb_up,
              title: 'Vote positif',
              subtitle: 'Votre réponse a reçu 5 votes',
              time: 'Il y a 1h',
            ),
            _buildNotificationItem(
              icon: Icons.check_circle,
              title: 'Solution acceptée',
              subtitle: 'Votre réponse a été marquée comme solution',
              time: 'Il y a 2h',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: Icon(icon, color: Colors.green.shade700, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'my_topics':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mes sujets')));
        break;
      case 'my_answers':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mes réponses')));
        break;
      case 'bookmarks':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Favoris')));
        break;
      case 'rules':
        _showForumRules(context);
        break;
    }
  }

  void _showForumRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.orange),
            SizedBox(width: 8),
            Text('Règles du Forum'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Respect mutuel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Soyez courtois et respectueux envers tous les membres.'),
              SizedBox(height: 12),
              Text(
                '2. Contenu pertinent',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Publiez uniquement du contenu lié à l\'agriculture.'),
              SizedBox(height: 12),
              Text(
                '3. Pas de spam',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Évitez la publicité non sollicitée.'),
              SizedBox(height: 12),
              Text(
                '4. Recherchez avant de poster',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Vérifiez si votre question n\'a pas déjà été posée.'),
              SizedBox(height: 12),
              Text(
                '5. Marquez les solutions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Si votre problème est résolu, marquez la meilleure réponse.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _createNewTopic(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTopicPage(
          category: const ForumCategory(
            id: 'general',
            name: 'Général',
            description: 'Discussions générales',
            iconName: 'forum',
            topicCount: 0,
          ),
        ),
      ),
    );
  }
}

// Widget pour une carte de catégorie
class _CategoryCard extends StatelessWidget {
  final ForumCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(category.iconName),
              size: 28,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.topicCount} sujets',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'local_florist':
        return Icons.local_florist;
      case 'bug_report':
        return Icons.bug_report;
      case 'handyman':
        return Icons.handyman;
      case 'trending_up':
        return Icons.trending_up;
      case 'people':
        return Icons.people;
      case 'water_drop':
        return Icons.water_drop;
      case 'eco':
        return Icons.eco;
      default:
        return Icons.forum;
    }
  }
}

// Widget pour un sujet populaire
class _HotTopicCard extends StatelessWidget {
  final _MockTopic topic;

  const _HotTopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (topic.isHot)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.whatshot,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                )
              else
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    topic.author[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (topic.isSolved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '✓ Résolu',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          topic.author,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.replies}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.views}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour un élément de liste de sujets
class _TopicListItem extends StatelessWidget {
  final _MockTopic topic;

  const _TopicListItem({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: topic.isSolved
              ? Colors.green.shade100
              : Colors.grey.shade200,
          child: topic.isSolved
              ? Icon(Icons.check, color: Colors.green.shade700)
              : Text(topic.author[0]),
        ),
        title: Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(topic.author),
            const SizedBox(width: 8),
            Icon(
              Icons.chat_bubble_outline,
              size: 12,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 2),
            Text('${topic.replies}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: topic.isHot
            ? Icon(Icons.whatshot, color: Colors.orange.shade600)
            : null,
        onTap: () {},
      ),
    );
  }
}

// Classes mock pour le prototype
class _MockTopic {
  final String title;
  final String author;
  final int replies;
  final int views;
  final bool isHot;
  final bool isSolved;

  _MockTopic({
    required this.title,
    required this.author,
    required this.replies,
    required this.views,
    this.isHot = false,
    this.isSolved = false,
  });
}

class _MockExpert {
  final String name;
  final String specialty;
  final int answers;

  _MockExpert({
    required this.name,
    required this.specialty,
    required this.answers,
  });
}
