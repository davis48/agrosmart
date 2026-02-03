/// Page du Calendrier Cultural
/// AgriSmart CI - Application Mobile
library;

import 'package:flutter/material.dart';
import 'package:agriculture/features/calendar/services/crop_calendar_service.dart';

class CropCalendarPage extends StatefulWidget {
  const CropCalendarPage({super.key});

  @override
  State<CropCalendarPage> createState() => _CropCalendarPageState();
}

class _CropCalendarPageState extends State<CropCalendarPage>
    with SingleTickerProviderStateMixin {
  final CropCalendarService _calendarService = CropCalendarService();
  late TabController _tabController;

  int _selectedMonth = DateTime.now().month;
  AgricultureRegion _selectedRegion = AgricultureRegion.centre;
  String? _selectedCropId;

  final List<String> _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _calendarService.initialize();
    setState(() {});
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
        title: const Text(
          'Calendrier Cultural',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Mois'),
            Tab(icon: Icon(Icons.grass), text: 'Cultures'),
            Tab(icon: Icon(Icons.tips_and_updates), text: 'Conseils'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMonthView(), _buildCropsView(), _buildAdviceView()],
      ),
    );
  }

  Widget _buildMonthView() {
    final events = _calendarService.getEventsForMonth(
      _selectedMonth,
      region: _selectedRegion,
      cropId: _selectedCropId,
    );

    return Column(
      children: [
        // Sélecteurs
        Container(
          color: Colors.green[50],
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Sélecteur de mois
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedMonth == index + 1;
                    final isCurrent = DateTime.now().month == index + 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(_months[index].substring(0, 3)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedMonth = index + 1);
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        avatar: isCurrent
                            ? const Icon(Icons.today, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Sélecteur de région
              DropdownButtonFormField<AgricultureRegion>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  labelText: 'Région',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: AgricultureRegion.values.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRegion = value);
                    _calendarService.setRegion(value);
                  }
                },
              ),
            ],
          ),
        ),
        // Saison actuelle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: _getSeasonColor(_calendarService.getCurrentSeason()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getSeasonIcon(_calendarService.getCurrentSeason()),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _calendarService.getCurrentSeason().name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Liste des événements
        Expanded(
          child: events.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(events[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCropsView() {
    final categories = _calendarService.getCategories();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final crops = _calendarService.getCropsByCategory(category);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...crops.map((crop) => _buildCropCard(crop)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAdviceView() {
    final season = _calendarService.getCurrentSeason();
    final advice = _calendarService.getSeasonalAdvice();
    final upcomingEvents = _calendarService.getUpcomingActivities(
      region: _selectedRegion,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de la saison
          Card(
            color: _getSeasonColor(season),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSeasonIcon(season),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              season.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              season.period,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Conseils saisonniers
          Text(
            'Conseils pour cette saison',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...advice.map(
            (tip) => Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.amber),
                title: Text(tip),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Activités à venir
          Text(
            'Activités à prévoir',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (upcomingEvents.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune activité urgente pour le moment'),
              ),
            )
          else
            ...upcomingEvents.take(10).map((event) => _buildEventCard(event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(CropCalendarEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(event.activity),
          child: Text(
            event.activity.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          '${event.cropName} - ${event.activity.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  event.periodText,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (event.tips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: event.tips.take(2).map((tip) {
                  return Chip(
                    label: Text(tip, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green[50],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCropCard(CropInfo crop) {
    final isRecommended = crop.suitableRegions.contains(_selectedRegion);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Text(crop.emoji, style: const TextStyle(fontSize: 28)),
        title: Row(
          children: [
            Expanded(child: Text(crop.name)),
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Recommandé',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Text('Cycle: ${crop.cycleDays} jours'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Régions adaptées
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: crop.suitableRegions.map((region) {
                    return Chip(
                      label: Text(
                        region.name,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: region == _selectedRegion
                          ? Colors.green[100]
                          : Colors.grey[200],
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Calendrier de la culture
                const Text(
                  'Calendrier:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...crop.calendarEvents.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(event.activity.emoji),
                        const SizedBox(width: 8),
                        Expanded(child: Text(event.activity.name)),
                        Text(
                          event.periodText,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                // Bouton voir détails
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedCropId = crop.id);
                      _tabController.animateTo(0);
                    },
                    icon: const Icon(Icons.calendar_view_month),
                    label: const Text('Voir dans le calendrier'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune activité pour ${_months[_selectedMonth - 1]}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (_selectedCropId != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedCropId = null),
              child: const Text('Voir toutes les cultures'),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeasonColor(CropSeason season) {
    switch (season) {
      case CropSeason.grandeSaisonPluies:
        return Colors.blue[600]!;
      case CropSeason.petiteSaisonSeche:
        return Colors.orange[600]!;
      case CropSeason.petiteSaisonPluies:
        return Colors.teal[600]!;
      case CropSeason.grandeSaisonSeche:
        return Colors.amber[700]!;
    }
  }

  IconData _getSeasonIcon(CropSeason season) {
    switch (season) {
      case CropSeason.grandeSaisonPluies:
        return Icons.water_drop;
      case CropSeason.petiteSaisonSeche:
        return Icons.wb_sunny;
      case CropSeason.petiteSaisonPluies:
        return Icons.grain;
      case CropSeason.grandeSaisonSeche:
        return Icons.brightness_high;
    }
  }

  Color _getActivityColor(FarmActivity activity) {
    switch (activity) {
      case FarmActivity.preparation:
        return Colors.brown;
      case FarmActivity.semis:
        return Colors.green;
      case FarmActivity.entretien:
        return Colors.blue;
      case FarmActivity.fertilisation:
        return Colors.purple;
      case FarmActivity.traitement:
        return Colors.red;
      case FarmActivity.recolte:
        return Colors.amber;
    }
  }
}
