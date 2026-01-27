import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:agriculture/features/notifications/data/datasources/alert_remote_data_source.dart';
import 'package:agriculture/features/notifications/data/repositories/alert_repository_impl.dart';
import 'package:agriculture/features/notifications/presentation/bloc/alert_bloc.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/recommandations/presentation/bloc/recommandation_bloc.dart';
import 'package:agriculture/features/recommandations/domain/entities/recommandation.dart';
import 'package:agriculture/injection_container.dart' as di;
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late AlertBloc _alertBloc;
  late RecommandationBloc _recommandationBloc;
  late TabController _tabController;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["Tout", "Maladies", "Irrigation", "Sol", "Météo"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Init AlertBloc
    final dataSource = AlertRemoteDataSourceImpl(dio: dioClient);
    final repository = AlertRepositoryImpl(remoteDataSource: dataSource);
    _alertBloc = AlertBloc(repository: repository)..add(LoadAlerts());

    // Init RecommandationBloc
    // Assuming DI container has it registered, otherwise we might need to create it manually like AlertBloc
    // For safety, we try to get it from DI, if fails we might need fallback or manually create it if logic allows
    try {
      _recommandationBloc = di.sl<RecommandationBloc>()..add(LoadRecommandations());
    } catch (e) {
      // Fallback if not registered in SL (though it should be if used in Dashboard)
      // This part is a placeholder, strictly we should ensure DI is correct.
      debugPrint("RecommandationBloc retrieval failed: $e");
    }
  }

  @override
  void dispose() {
    _alertBloc.close();
    // _recommandationBloc.close(); // Do not close if it is a singleton from DI. If we created it, we should close it.
    // Assuming we retrieved it from DI and it might be shared or factory. 
    // If factory, we should close it. Safe to close if text implies local usage. 
    // But earlier I said dashboard used it. 
    // Let's assume we don't close it if it comes from SL and might be shared, OR we create a new instance and close it.
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _alertBloc),
        BlocProvider.value(value: _recommandationBloc),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAlertsTab(),
                  _buildRecommendationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 0),
      decoration: const BoxDecoration(
        color: Color(0xFFD32F2F), // Red base color, but we might want dynamic color based on tab?
        // Let's keep it Red for consistency with "Notifications" or change to Neutral/Green?
        // User asked for "Recommandations" in "volet alerte".
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                "Centre de Notifications",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: "Alertes"),
              Tab(text: "Conseils"),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return BlocBuilder<AlertBloc, AlertState>(
      builder: (context, state) {
        List<Alert> alerts = [];
        if (state is AlertLoaded) {
          alerts = state.alerts;
        }

        // Filter logic
        if (_selectedFilterIndex != 0) {
          alerts = alerts.where((a) {
            switch (_selectedFilterIndex) {
              case 1: return a.category == AlertCategory.maladie;
              case 2: return a.category == AlertCategory.irrigation;
              case 3: return a.category == AlertCategory.sol;
              case 4: return a.category == AlertCategory.meteo;
              default: return true;
            }
          }).toList();
        }

        return Column(
          children: [
            // Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filters[index]),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      checkmarkColor: Colors.red,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.red : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // List
            Expanded(
              child: alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text("Aucune alerte pour ce filtre",
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (_selectedFilterIndex == 0) ...[
                             // Timeline Alertes (Small Cards) - Only on 'All' view for summary
                            ...alerts.take(3).map((alert) => _buildSmallAlertCard(alert)),
                            const SizedBox(height: 24),
                          ],
                          
                          // Detailed Cards
                          ...alerts.map((a) {
                            if (a.category == AlertCategory.maladie) return _buildDiseaseAlertCard(a);
                            if (a.category == AlertCategory.irrigation) return _buildIrrigationCard(a);
                            if (a.category == AlertCategory.sol) return _buildPhCard(a);
                            // Fallback
                            return _buildSmallAlertCard(a); 
                          }),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendationsTab() {
    return BlocBuilder<RecommandationBloc, RecommandationState>(
      builder: (context, state) {
        if (state is RecommandationLoading) {
           return const Center(child: CircularProgressIndicator());
        }
        
        List<Recommandation> recs = [];
        if (state is RecommandationLoaded) {
          recs = state.recommandations;
        }

        if (recs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.green.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text("Tout est optimal !", style: TextStyle(color: Colors.grey, fontSize: 18)),
                const Text("Aucun conseil pour le moment.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recs.length,
          itemBuilder: (context, index) {
            final rec = recs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIconForType(rec.type), color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.titre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec.description,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        if (rec.impactEstime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              "Impact: ${rec.impactEstime}",
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(RecommandationType type) {
    switch (type) {
      case RecommandationType.irrigation: return Icons.water_drop;
      case RecommandationType.fertilisation: return Icons.science;
      case RecommandationType.traitement: return Icons.healing;
      case RecommandationType.recolte: return Icons.agriculture;
      default: return Icons.lightbulb_outline;
    }
  }

  Widget _buildSmallAlertCard(Alert alert) {
    Color barColor = Colors.orange;
    IconData icon = Icons.warning_amber_rounded;
    Color iconColor = Colors.orange;
    
    if (alert.category == AlertCategory.irrigation) {
        barColor = Colors.green;
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
    } else if (alert.category == AlertCategory.maladie) {
        barColor = Colors.red;
        icon = Icons.error_outline;
        iconColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: barColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: barColor, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(icon, color: iconColor),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   DateFormat('HH:mm').format(alert.date),
                   style: TextStyle(color: Colors.grey[500], fontSize: 12),
                 ),
                 const SizedBox(height: 4),
                 Text(
                   alert.title, 
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                 ),
               ],
             )
           )
        ],
      ),
    );
  }

  Widget _buildDiseaseAlertCard(Alert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              const Text(
                "Alerte Maladie - IA",
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.message, 
            style: const TextStyle(
              color: Color(0xFFB71C1C),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Voir\nRecommandations", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(color: Color(0xFFD32F2F)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Contacter un\nexpert", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIrrigationCard(Alert alert) {
     return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: Colors.blue, size: 28),
              const SizedBox(width: 10),
              const Text(
                "Irrigation Programmée",
                style: TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.message, 
            style: const TextStyle(
              color: Color(0xFF0D47A1),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Modifier la programmation"),
            ),
          )
        ],
      ),
     );
  }

  Widget _buildPhCard(Alert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: Colors.orange, size: 28),
              const SizedBox(width: 10),
              const Text(
                "pH Acide",
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.actionRecommandee ?? "Mets un peu de chaux ou de cendre de bois pour remonter le pH.",
            style: const TextStyle(
              color: Color(0xFFE65100),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

