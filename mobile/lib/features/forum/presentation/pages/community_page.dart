import 'package:flutter/material.dart';
import 'package:agriculture/features/forum/presentation/pages/forum_home_page.dart';
import 'package:agriculture/features/marketplace/presentation/pages/marketplace_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté'),
        elevation: 0,
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: "Forum", icon: Icon(Icons.forum_outlined)),
            Tab(text: "Marché", icon: Icon(Icons.storefront_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ForumHomePage(), // We might need to adjust ForumHomePage to remove its internal Scaffold/AppBar
          MarketplacePage(), // Same for MarketplacePage
        ],
      ),
    );
  }
}
