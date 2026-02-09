/// Calendrier Cultural Intelligent pour la Côte d'Ivoire
/// AgroSmart - Application Mobile
///
/// Fournit les périodes optimales de semis, entretien et récolte
/// basées sur les régions et le climat ivoirien.
library;

import 'dart:developer' as developer;

/// Saison de culture
enum CropSeason {
  grandeSaisonPluies('Grande saison des pluies', 'Mars - Juillet'),
  petiteSaisonSeche('Petite saison sèche', 'Juillet - Septembre'),
  petiteSaisonPluies('Petite saison des pluies', 'Septembre - Novembre'),
  grandeSaisonSeche('Grande saison sèche', 'Novembre - Mars');

  final String name;
  final String period;
  const CropSeason(this.name, this.period);
}

/// Région agricole de Côte d'Ivoire
enum AgricultureRegion {
  sudForestier('Sud Forestier', [
    'Abidjan',
    'San-Pedro',
    'Sassandra',
    'Grand-Lahou',
  ]),
  centreOuest('Centre-Ouest', ['Daloa', 'Man', 'Duékoué', 'Guiglo']),
  centreEst('Centre-Est', ['Abengourou', 'Bondoukou', 'Agnibilékrou']),
  centre('Centre', ['Bouaké', 'Yamoussoukro', 'Dimbokro']),
  nordSavane('Nord Savane', [
    'Korhogo',
    'Boundiali',
    'Ferkessédougou',
    'Odienné',
  ]),
  est('Est', ['Bouna', 'Nassian', 'Tanda']),
  ouest('Ouest', ['Danané', 'Biankouma', 'Touba']);

  final String name;
  final List<String> cities;
  const AgricultureRegion(this.name, this.cities);

  static AgricultureRegion? fromCity(String city) {
    final lowerCity = city.toLowerCase();
    for (final region in AgricultureRegion.values) {
      if (region.cities.any((c) => c.toLowerCase() == lowerCity)) {
        return region;
      }
    }
    return null;
  }
}

/// Type d'activité agricole
enum FarmActivity {
  preparation('Préparation du sol', '🌱'),
  semis('Semis/Plantation', '🌾'),
  entretien('Entretien', '🔧'),
  fertilisation('Fertilisation', '💧'),
  traitement('Traitement phytosanitaire', '🧪'),
  recolte('Récolte', '🌽');

  final String name;
  final String emoji;
  const FarmActivity(this.name, this.emoji);
}

/// Événement du calendrier cultural
class CropCalendarEvent {
  final String cropId;
  final String cropName;
  final FarmActivity activity;
  final int startMonth;
  final int endMonth;
  final String description;
  final String descriptionLocal;
  final List<String> tips;
  final AgricultureRegion? specificRegion;

  CropCalendarEvent({
    required this.cropId,
    required this.cropName,
    required this.activity,
    required this.startMonth,
    required this.endMonth,
    required this.description,
    this.descriptionLocal = '',
    this.tips = const [],
    this.specificRegion,
  });

  bool isActiveInMonth(int month) {
    if (startMonth <= endMonth) {
      return month >= startMonth && month <= endMonth;
    } else {
      // Gère le cas où la période chevauche le nouvel an
      return month >= startMonth || month <= endMonth;
    }
  }

  String get periodText {
    final months = [
      '',
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
    return '${months[startMonth]} - ${months[endMonth]}';
  }

  Map<String, dynamic> toJson() => {
    'cropId': cropId,
    'cropName': cropName,
    'activity': activity.name,
    'startMonth': startMonth,
    'endMonth': endMonth,
    'description': description,
    'descriptionLocal': descriptionLocal,
    'tips': tips,
    'specificRegion': specificRegion?.name,
  };
}

/// Informations sur une culture
class CropInfo {
  final String id;
  final String name;
  final Map<String, String> names; // Noms locaux
  final String emoji;
  final String category;
  final int cycleDays;
  final List<AgricultureRegion> suitableRegions;
  final List<CropCalendarEvent> calendarEvents;
  final Map<String, dynamic> requirements;

  CropInfo({
    required this.id,
    required this.name,
    required this.names,
    required this.emoji,
    required this.category,
    required this.cycleDays,
    required this.suitableRegions,
    required this.calendarEvents,
    this.requirements = const {},
  });

  String getLocalizedName(String languageCode) {
    return names[languageCode] ?? names['fr'] ?? name;
  }
}

/// Service de Calendrier Cultural
class CropCalendarService {
  static final CropCalendarService _instance = CropCalendarService._internal();
  factory CropCalendarService() => _instance;
  CropCalendarService._internal();

  bool _isInitialized = false;
  AgricultureRegion _currentRegion = AgricultureRegion.centre;

  // Base de données des cultures
  static final Map<String, CropInfo> _crops = {
    // === CULTURES DE RENTE ===
    'cacao': CropInfo(
      id: 'cacao',
      name: 'Cacao',
      names: {'fr': 'Cacao', 'bci': 'Cacao', 'dyu': 'Cacao', 'sef': 'Kakao'},
      emoji: '🍫',
      category: 'Cultures de rente',
      cycleDays: 1825, // 5 ans avant première récolte
      suitableRegions: [
        AgricultureRegion.sudForestier,
        AgricultureRegion.centreOuest,
        AgricultureRegion.centreEst,
      ],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'cacao',
          cropName: 'Cacao',
          activity: FarmActivity.preparation,
          startMonth: 2,
          endMonth: 3,
          description: 'Préparation des parcelles, défrichage',
          tips: [
            'Conserver les grands arbres pour l\'ombrage',
            'Éviter le brûlis',
          ],
        ),
        CropCalendarEvent(
          cropId: 'cacao',
          cropName: 'Cacao',
          activity: FarmActivity.semis,
          startMonth: 4,
          endMonth: 6,
          description:
              'Plantation des jeunes plants (début grande saison des pluies)',
          tips: ['Espacer de 3m x 3m', 'Planter sous ombrage'],
        ),
        CropCalendarEvent(
          cropId: 'cacao',
          cropName: 'Cacao',
          activity: FarmActivity.entretien,
          startMonth: 1,
          endMonth: 12,
          description: 'Désherbage régulier, taille sanitaire',
          tips: ['Tailler 2 fois par an', 'Éliminer les gourmands'],
        ),
        CropCalendarEvent(
          cropId: 'cacao',
          cropName: 'Cacao',
          activity: FarmActivity.traitement,
          startMonth: 8,
          endMonth: 11,
          description: 'Traitement contre pourriture brune et swollen shoot',
          tips: ['Utiliser du cuivre', 'Récolter les cabosses malades'],
        ),
        CropCalendarEvent(
          cropId: 'cacao',
          cropName: 'Cacao',
          activity: FarmActivity.recolte,
          startMonth: 10,
          endMonth: 1,
          description: 'Récolte principale (Grande traite)',
          tips: ['Récolter à maturité complète', 'Fermenter 5-7 jours'],
        ),
        CropCalendarEvent(
          cropId: 'cacao',
          cropName: 'Cacao',
          activity: FarmActivity.recolte,
          startMonth: 5,
          endMonth: 7,
          description: 'Récolte secondaire (Petite traite)',
          tips: ['Qualité souvent meilleure', 'Bien sécher au soleil'],
        ),
      ],
    ),
    'cafe': CropInfo(
      id: 'cafe',
      name: 'Café',
      names: {'fr': 'Café', 'bci': 'Café', 'dyu': 'Kafè', 'sef': 'Kafè'},
      emoji: '☕',
      category: 'Cultures de rente',
      cycleDays: 1095, // 3 ans
      suitableRegions: [AgricultureRegion.centreOuest, AgricultureRegion.ouest],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'cafe',
          cropName: 'Café',
          activity: FarmActivity.semis,
          startMonth: 5,
          endMonth: 7,
          description: 'Plantation en début de grande saison des pluies',
          tips: ['Planter en courbe de niveau', 'Prévoir ombrage'],
        ),
        CropCalendarEvent(
          cropId: 'cafe',
          cropName: 'Café',
          activity: FarmActivity.traitement,
          startMonth: 4,
          endMonth: 6,
          description: 'Traitement préventif contre la rouille',
          tips: ['Surveiller les jeunes feuilles', 'Pulvériser après la pluie'],
        ),
        CropCalendarEvent(
          cropId: 'cafe',
          cropName: 'Café',
          activity: FarmActivity.recolte,
          startMonth: 11,
          endMonth: 2,
          description: 'Récolte des cerises mûres',
          tips: [
            'Récolter uniquement les cerises rouges',
            'Dépulper le jour même',
          ],
        ),
      ],
    ),
    'hevea': CropInfo(
      id: 'hevea',
      name: 'Hévéa',
      names: {
        'fr': 'Hévéa',
        'bci': 'Caoutchouc',
        'dyu': 'Kaotcu',
        'sef': 'Hévéa',
      },
      emoji: '🌳',
      category: 'Cultures de rente',
      cycleDays: 2555, // 7 ans
      suitableRegions: [
        AgricultureRegion.sudForestier,
        AgricultureRegion.centreOuest,
      ],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'hevea',
          cropName: 'Hévéa',
          activity: FarmActivity.semis,
          startMonth: 5,
          endMonth: 7,
          description: 'Plantation en début de grande saison des pluies',
          tips: ['Espacer de 7m x 3m', 'Utiliser des plants greffés'],
        ),
        CropCalendarEvent(
          cropId: 'hevea',
          cropName: 'Hévéa',
          activity: FarmActivity.recolte,
          startMonth: 1,
          endMonth: 12,
          description: 'Saignée (tous les 2-3 jours, sauf refoliation)',
          tips: [
            'Arrêter en février-mars (refoliation)',
            'Saigner tôt le matin',
          ],
        ),
      ],
    ),
    'palmier': CropInfo(
      id: 'palmier',
      name: 'Palmier à huile',
      names: {
        'fr': 'Palmier à huile',
        'bci': 'Palmier',
        'dyu': 'Tulu jiri',
        'sef': 'Palmier',
      },
      emoji: '🌴',
      category: 'Cultures de rente',
      cycleDays: 1095, // 3 ans avant production
      suitableRegions: [
        AgricultureRegion.sudForestier,
        AgricultureRegion.centreEst,
      ],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'palmier',
          cropName: 'Palmier à huile',
          activity: FarmActivity.semis,
          startMonth: 5,
          endMonth: 7,
          description: 'Plantation en saison des pluies',
          tips: ['Espacer de 9m en triangle', 'Prévoir drainage'],
        ),
        CropCalendarEvent(
          cropId: 'palmier',
          cropName: 'Palmier à huile',
          activity: FarmActivity.recolte,
          startMonth: 1,
          endMonth: 12,
          description: 'Récolte des régimes toute l\'année',
          tips: [
            'Récolter quand 2-3 fruits se détachent',
            'Traiter dans les 24h',
          ],
        ),
      ],
    ),

    // === CULTURES VIVRIÈRES ===
    'riz': CropInfo(
      id: 'riz',
      name: 'Riz',
      names: {'fr': 'Riz', 'bci': 'Riz', 'dyu': 'Malo', 'sef': 'Malo'},
      emoji: '🌾',
      category: 'Céréales',
      cycleDays: 120,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'riz',
          cropName: 'Riz',
          activity: FarmActivity.preparation,
          startMonth: 2,
          endMonth: 3,
          description: 'Labour et préparation de la pépinière',
          tips: ['Inonder le sol pour riz irrigué', 'Bien niveler'],
        ),
        CropCalendarEvent(
          cropId: 'riz',
          cropName: 'Riz',
          activity: FarmActivity.semis,
          startMonth: 3,
          endMonth: 4,
          description: 'Semis en pépinière (1er cycle)',
          tips: ['25-30 kg semences/ha', 'Repiquage après 21 jours'],
        ),
        CropCalendarEvent(
          cropId: 'riz',
          cropName: 'Riz',
          activity: FarmActivity.semis,
          startMonth: 8,
          endMonth: 9,
          description: 'Semis 2ème cycle (zones irriguées)',
          tips: ['Uniquement dans les bas-fonds aménagés'],
          specificRegion: AgricultureRegion.centre,
        ),
        CropCalendarEvent(
          cropId: 'riz',
          cropName: 'Riz',
          activity: FarmActivity.fertilisation,
          startMonth: 4,
          endMonth: 5,
          description: 'Fertilisation NPK au tallage',
          tips: ['200 kg NPK/ha', 'Urée en deux apports'],
        ),
        CropCalendarEvent(
          cropId: 'riz',
          cropName: 'Riz',
          activity: FarmActivity.recolte,
          startMonth: 7,
          endMonth: 8,
          description: 'Récolte 1er cycle',
          tips: ['Récolter à maturité physiologique', 'Sécher au soleil'],
        ),
        CropCalendarEvent(
          cropId: 'riz',
          cropName: 'Riz',
          activity: FarmActivity.recolte,
          startMonth: 12,
          endMonth: 1,
          description: 'Récolte 2ème cycle',
          tips: ['Battre rapidement après récolte'],
        ),
      ],
    ),
    'mais': CropInfo(
      id: 'mais',
      name: 'Maïs',
      names: {'fr': 'Maïs', 'bci': 'Maïs', 'dyu': 'Kaba', 'sef': 'Kaba'},
      emoji: '🌽',
      category: 'Céréales',
      cycleDays: 90,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'mais',
          cropName: 'Maïs',
          activity: FarmActivity.semis,
          startMonth: 3,
          endMonth: 4,
          description: 'Semis 1er cycle (grande saison des pluies)',
          tips: ['Espacer de 75cm x 40cm', '2-3 graines par poquet'],
        ),
        CropCalendarEvent(
          cropId: 'mais',
          cropName: 'Maïs',
          activity: FarmActivity.semis,
          startMonth: 8,
          endMonth: 9,
          description: 'Semis 2ème cycle (petite saison des pluies)',
          tips: ['Choisir variété à cycle court'],
        ),
        CropCalendarEvent(
          cropId: 'mais',
          cropName: 'Maïs',
          activity: FarmActivity.fertilisation,
          startMonth: 4,
          endMonth: 5,
          description: 'Fertilisation NPK + urée',
          tips: ['NPK au semis', 'Urée au 30ème jour'],
        ),
        CropCalendarEvent(
          cropId: 'mais',
          cropName: 'Maïs',
          activity: FarmActivity.recolte,
          startMonth: 6,
          endMonth: 7,
          description: 'Récolte 1er cycle',
          tips: ['Récolter quand les spathes sèchent'],
        ),
        CropCalendarEvent(
          cropId: 'mais',
          cropName: 'Maïs',
          activity: FarmActivity.recolte,
          startMonth: 11,
          endMonth: 12,
          description: 'Récolte 2ème cycle',
          tips: ['Bien sécher avant stockage'],
        ),
      ],
    ),
    'manioc': CropInfo(
      id: 'manioc',
      name: 'Manioc',
      names: {'fr': 'Manioc', 'bci': 'Atièkè', 'dyu': 'Banan', 'sef': 'Atièkè'},
      emoji: '🥔',
      category: 'Tubercules',
      cycleDays: 365,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'manioc',
          cropName: 'Manioc',
          activity: FarmActivity.semis,
          startMonth: 3,
          endMonth: 5,
          description: 'Plantation des boutures (grande saison)',
          tips: ['Boutures de 20-25 cm', 'Planter en oblique'],
        ),
        CropCalendarEvent(
          cropId: 'manioc',
          cropName: 'Manioc',
          activity: FarmActivity.semis,
          startMonth: 9,
          endMonth: 10,
          description: 'Plantation petite saison (facultatif)',
          tips: ['Moins de rendement qu\'en grande saison'],
        ),
        CropCalendarEvent(
          cropId: 'manioc',
          cropName: 'Manioc',
          activity: FarmActivity.entretien,
          startMonth: 5,
          endMonth: 8,
          description: 'Sarclage et buttage',
          tips: ['Butter après 2 mois', 'Garder le sol propre'],
        ),
        CropCalendarEvent(
          cropId: 'manioc',
          cropName: 'Manioc',
          activity: FarmActivity.recolte,
          startMonth: 1,
          endMonth: 12,
          description: 'Récolte 8-18 mois après plantation',
          tips: ['Récolter avant le durcissement', 'Transformer rapidement'],
        ),
      ],
    ),
    'igname': CropInfo(
      id: 'igname',
      name: 'Igname',
      names: {'fr': 'Igname', 'bci': 'Igname', 'dyu': 'Kusu', 'sef': 'Kusu'},
      emoji: '🍠',
      category: 'Tubercules',
      cycleDays: 270,
      suitableRegions: [
        AgricultureRegion.centre,
        AgricultureRegion.nordSavane,
        AgricultureRegion.centreOuest,
      ],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'igname',
          cropName: 'Igname',
          activity: FarmActivity.preparation,
          startMonth: 11,
          endMonth: 1,
          description: 'Préparation des buttes',
          tips: ['Buttes de 50-60 cm', 'Espacer d\'1 m'],
        ),
        CropCalendarEvent(
          cropId: 'igname',
          cropName: 'Igname',
          activity: FarmActivity.semis,
          startMonth: 1,
          endMonth: 3,
          description: 'Plantation des semenceaux',
          tips: [
            'Choisir des semenceaux sains',
            'Planter à 10 cm de profondeur',
          ],
        ),
        CropCalendarEvent(
          cropId: 'igname',
          cropName: 'Igname',
          activity: FarmActivity.entretien,
          startMonth: 4,
          endMonth: 7,
          description: 'Tuteurage et désherbage',
          tips: ['Tuteurer pour meilleur rendement', 'Désherber régulièrement'],
        ),
        CropCalendarEvent(
          cropId: 'igname',
          cropName: 'Igname',
          activity: FarmActivity.recolte,
          startMonth: 7,
          endMonth: 8,
          description: 'Récolte précoce (igname nouvelle)',
          tips: ['Fête des ignames', 'Prix élevé sur le marché'],
        ),
        CropCalendarEvent(
          cropId: 'igname',
          cropName: 'Igname',
          activity: FarmActivity.recolte,
          startMonth: 10,
          endMonth: 12,
          description: 'Récolte principale',
          tips: ['Stocker dans un endroit sec et aéré'],
        ),
      ],
    ),
    'banane_plantain': CropInfo(
      id: 'banane_plantain',
      name: 'Banane Plantain',
      names: {
        'fr': 'Banane Plantain',
        'bci': 'Alloco',
        'dyu': 'Banana',
        'sef': 'Banana',
      },
      emoji: '🍌',
      category: 'Fruits',
      cycleDays: 365,
      suitableRegions: [
        AgricultureRegion.sudForestier,
        AgricultureRegion.centreOuest,
        AgricultureRegion.centre,
      ],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'banane_plantain',
          cropName: 'Banane Plantain',
          activity: FarmActivity.semis,
          startMonth: 3,
          endMonth: 5,
          description: 'Plantation des rejets (grande saison)',
          tips: [
            'Utiliser des rejets sains',
            'Planter dans des trous profonds',
          ],
        ),
        CropCalendarEvent(
          cropId: 'banane_plantain',
          cropName: 'Banane Plantain',
          activity: FarmActivity.entretien,
          startMonth: 1,
          endMonth: 12,
          description: 'Œilletonnage et effeuillage',
          tips: ['Garder 1-2 rejets par pied', 'Couper les feuilles sèches'],
        ),
        CropCalendarEvent(
          cropId: 'banane_plantain',
          cropName: 'Banane Plantain',
          activity: FarmActivity.recolte,
          startMonth: 1,
          endMonth: 12,
          description: 'Récolte continue (9-12 mois après plantation)',
          tips: ['Récolter quand les doigts sont bien formés'],
        ),
      ],
    ),

    // === MARAÎCHAGE ===
    'tomate': CropInfo(
      id: 'tomate',
      name: 'Tomate',
      names: {
        'fr': 'Tomate',
        'bci': 'Tomate',
        'dyu': 'Tomate',
        'sef': 'Tomate',
      },
      emoji: '🍅',
      category: 'Maraîchage',
      cycleDays: 90,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'tomate',
          cropName: 'Tomate',
          activity: FarmActivity.semis,
          startMonth: 10,
          endMonth: 12,
          description: 'Semis en pépinière (saison sèche)',
          tips: ['La tomate craint l\'excès d\'eau', 'Semis sous abri'],
        ),
        CropCalendarEvent(
          cropId: 'tomate',
          cropName: 'Tomate',
          activity: FarmActivity.semis,
          startMonth: 6,
          endMonth: 7,
          description: 'Repiquage après 3 semaines',
          tips: ['Espacer de 60x40 cm', 'Repiquer le soir'],
        ),
        CropCalendarEvent(
          cropId: 'tomate',
          cropName: 'Tomate',
          activity: FarmActivity.traitement,
          startMonth: 11,
          endMonth: 2,
          description: 'Traitement préventif (mildiou, alternariose)',
          tips: ['Pulvériser tous les 7-10 jours', 'Alterner les produits'],
        ),
        CropCalendarEvent(
          cropId: 'tomate',
          cropName: 'Tomate',
          activity: FarmActivity.recolte,
          startMonth: 1,
          endMonth: 4,
          description: 'Récolte principale',
          tips: ['Récolter à maturité', 'Éviter les heures chaudes'],
        ),
      ],
    ),
    'oignon': CropInfo(
      id: 'oignon',
      name: 'Oignon',
      names: {'fr': 'Oignon', 'bci': 'Djaba', 'dyu': 'Djaba', 'sef': 'Djaba'},
      emoji: '🧅',
      category: 'Maraîchage',
      cycleDays: 120,
      suitableRegions: [AgricultureRegion.nordSavane, AgricultureRegion.centre],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'oignon',
          cropName: 'Oignon',
          activity: FarmActivity.semis,
          startMonth: 10,
          endMonth: 11,
          description: 'Semis en pépinière',
          tips: ['Pépinière bien drainée', '3-4 g de semences/m²'],
        ),
        CropCalendarEvent(
          cropId: 'oignon',
          cropName: 'Oignon',
          activity: FarmActivity.semis,
          startMonth: 11,
          endMonth: 12,
          description: 'Repiquage après 45 jours',
          tips: ['Espacement 15x10 cm', 'Irriguer régulièrement'],
        ),
        CropCalendarEvent(
          cropId: 'oignon',
          cropName: 'Oignon',
          activity: FarmActivity.recolte,
          startMonth: 2,
          endMonth: 4,
          description: 'Récolte quand les feuilles jaunissent',
          tips: [
            'Arrêter irrigation 2 semaines avant',
            'Bien sécher au soleil',
          ],
        ),
      ],
    ),
    'piment': CropInfo(
      id: 'piment',
      name: 'Piment',
      names: {
        'fr': 'Piment',
        'bci': 'Piment',
        'dyu': 'Foronto',
        'sef': 'Foronto',
      },
      emoji: '🌶️',
      category: 'Maraîchage',
      cycleDays: 150,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'piment',
          cropName: 'Piment',
          activity: FarmActivity.semis,
          startMonth: 2,
          endMonth: 3,
          description: 'Semis en pépinière',
          tips: ['Tremper les graines 24h', 'Lever en 10-15 jours'],
        ),
        CropCalendarEvent(
          cropId: 'piment',
          cropName: 'Piment',
          activity: FarmActivity.semis,
          startMonth: 4,
          endMonth: 5,
          description: 'Repiquage à 60x40 cm',
          tips: ['Repiquer le soir', 'Bien arroser après'],
        ),
        CropCalendarEvent(
          cropId: 'piment',
          cropName: 'Piment',
          activity: FarmActivity.recolte,
          startMonth: 7,
          endMonth: 12,
          description: 'Récolte échelonnée',
          tips: ['Récolter régulièrement', 'Stimule la production'],
        ),
      ],
    ),
    'gombo': CropInfo(
      id: 'gombo',
      name: 'Gombo',
      names: {'fr': 'Gombo', 'bci': 'Gombo', 'dyu': 'Gombo', 'sef': 'Gombo'},
      emoji: '🥒',
      category: 'Maraîchage',
      cycleDays: 75,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'gombo',
          cropName: 'Gombo',
          activity: FarmActivity.semis,
          startMonth: 3,
          endMonth: 4,
          description: 'Semis direct (1er cycle)',
          tips: ['3-4 graines/poquet', 'Espacer de 60x40 cm'],
        ),
        CropCalendarEvent(
          cropId: 'gombo',
          cropName: 'Gombo',
          activity: FarmActivity.semis,
          startMonth: 8,
          endMonth: 9,
          description: 'Semis 2ème cycle',
          tips: ['Cycle plus court en saison sèche'],
        ),
        CropCalendarEvent(
          cropId: 'gombo',
          cropName: 'Gombo',
          activity: FarmActivity.recolte,
          startMonth: 5,
          endMonth: 7,
          description: 'Récolte tous les 2-3 jours',
          tips: ['Récolter jeune (5-7 cm)', 'Ne pas laisser durcir'],
        ),
      ],
    ),
    'aubergine': CropInfo(
      id: 'aubergine',
      name: 'Aubergine',
      names: {
        'fr': 'Aubergine',
        'bci': 'Ntroma',
        'dyu': 'Ntroma',
        'sef': 'Ntroma',
      },
      emoji: '🍆',
      category: 'Maraîchage',
      cycleDays: 120,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'aubergine',
          cropName: 'Aubergine',
          activity: FarmActivity.semis,
          startMonth: 9,
          endMonth: 10,
          description: 'Semis en pépinière',
          tips: ['Lever en 8-10 jours', 'Protéger du soleil direct'],
        ),
        CropCalendarEvent(
          cropId: 'aubergine',
          cropName: 'Aubergine',
          activity: FarmActivity.semis,
          startMonth: 10,
          endMonth: 11,
          description: 'Repiquage à 70x50 cm',
          tips: ['Repiquer au stade 4-5 feuilles'],
        ),
        CropCalendarEvent(
          cropId: 'aubergine',
          cropName: 'Aubergine',
          activity: FarmActivity.recolte,
          startMonth: 1,
          endMonth: 5,
          description: 'Récolte continue',
          tips: ['Récolter jeune pour meilleur goût'],
        ),
      ],
    ),

    // === LÉGUMINEUSES ===
    'arachide': CropInfo(
      id: 'arachide',
      name: 'Arachide',
      names: {
        'fr': 'Arachide',
        'bci': 'Pistache',
        'dyu': 'Tiga',
        'sef': 'Tiga',
      },
      emoji: '🥜',
      category: 'Légumineuses',
      cycleDays: 105,
      suitableRegions: [AgricultureRegion.nordSavane, AgricultureRegion.centre],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'arachide',
          cropName: 'Arachide',
          activity: FarmActivity.semis,
          startMonth: 5,
          endMonth: 6,
          description: 'Semis dès les premières pluies',
          tips: ['Semer en ligne', 'Espacer de 40x15 cm'],
        ),
        CropCalendarEvent(
          cropId: 'arachide',
          cropName: 'Arachide',
          activity: FarmActivity.entretien,
          startMonth: 7,
          endMonth: 8,
          description: 'Sarclage-buttage',
          tips: ['Butter au moment de la floraison'],
        ),
        CropCalendarEvent(
          cropId: 'arachide',
          cropName: 'Arachide',
          activity: FarmActivity.recolte,
          startMonth: 9,
          endMonth: 10,
          description: 'Récolte à maturité',
          tips: ['Feuilles jaunissent', 'Arracher le matin'],
        ),
      ],
    ),
    'soja': CropInfo(
      id: 'soja',
      name: 'Soja',
      names: {'fr': 'Soja', 'bci': 'Soja', 'dyu': 'Soja', 'sef': 'Soja'},
      emoji: '🫘',
      category: 'Légumineuses',
      cycleDays: 100,
      suitableRegions: [AgricultureRegion.centre, AgricultureRegion.nordSavane],
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'soja',
          cropName: 'Soja',
          activity: FarmActivity.semis,
          startMonth: 6,
          endMonth: 7,
          description: 'Semis en début de saison des pluies',
          tips: ['Inoculer les semences', 'Espacer de 50x10 cm'],
        ),
        CropCalendarEvent(
          cropId: 'soja',
          cropName: 'Soja',
          activity: FarmActivity.recolte,
          startMonth: 10,
          endMonth: 11,
          description: 'Récolte à maturité complète',
          tips: ['Gousses brunes et sèches', 'Battre rapidement'],
        ),
      ],
    ),
    'haricot': CropInfo(
      id: 'haricot',
      name: 'Haricot',
      names: {'fr': 'Haricot', 'bci': 'Haricot', 'dyu': 'Soso', 'sef': 'Soso'},
      emoji: '🫛',
      category: 'Légumineuses',
      cycleDays: 75,
      suitableRegions: AgricultureRegion.values.toList(),
      calendarEvents: [
        CropCalendarEvent(
          cropId: 'haricot',
          cropName: 'Haricot',
          activity: FarmActivity.semis,
          startMonth: 3,
          endMonth: 4,
          description: 'Semis 1er cycle',
          tips: ['Espacer de 40x20 cm', '2-3 graines/poquet'],
        ),
        CropCalendarEvent(
          cropId: 'haricot',
          cropName: 'Haricot',
          activity: FarmActivity.semis,
          startMonth: 9,
          endMonth: 10,
          description: 'Semis 2ème cycle',
          tips: ['Associer au maïs possible'],
        ),
        CropCalendarEvent(
          cropId: 'haricot',
          cropName: 'Haricot',
          activity: FarmActivity.recolte,
          startMonth: 5,
          endMonth: 6,
          description: 'Récolte à maturité',
          tips: ['Gousses sèches et cassantes'],
        ),
      ],
    ),
  };

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    developer.log('[CropCalendar] Service initialized');
  }

  /// Définit la région actuelle
  void setRegion(AgricultureRegion region) {
    _currentRegion = region;
    developer.log('[CropCalendar] Region set to: ${region.name}');
  }

  /// Obtient la région actuelle
  AgricultureRegion get currentRegion => _currentRegion;

  /// Obtient les événements du mois pour une région
  List<CropCalendarEvent> getEventsForMonth(
    int month, {
    AgricultureRegion? region,
    String? cropId,
  }) {
    final targetRegion = region ?? _currentRegion;
    final events = <CropCalendarEvent>[];

    for (final crop in _crops.values) {
      // Filtrer par culture si spécifié
      if (cropId != null && crop.id != cropId) continue;

      // Vérifier si la culture est adaptée à la région
      if (!crop.suitableRegions.contains(targetRegion)) continue;

      for (final event in crop.calendarEvents) {
        // Vérifier si l'événement est actif ce mois
        if (!event.isActiveInMonth(month)) continue;

        // Vérifier si l'événement est spécifique à une autre région
        if (event.specificRegion != null &&
            event.specificRegion != targetRegion) {
          continue;
        }

        events.add(event);
      }
    }

    // Trier par activité
    events.sort((a, b) => a.activity.index.compareTo(b.activity.index));

    return events;
  }

  /// Obtient le calendrier complet d'une culture
  List<CropCalendarEvent> getCropCalendar(String cropId) {
    final crop = _crops[cropId];
    if (crop == null) return [];
    return crop.calendarEvents;
  }

  /// Obtient les cultures recommandées pour une région
  List<CropInfo> getRecommendedCrops(AgricultureRegion region) {
    return _crops.values
        .where((crop) => crop.suitableRegions.contains(region))
        .toList();
  }

  /// Obtient les activités urgentes (ce mois et le suivant)
  List<CropCalendarEvent> getUpcomingActivities({
    AgricultureRegion? region,
    int? days,
  }) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;

    final events = <CropCalendarEvent>[];

    // Événements du mois en cours
    events.addAll(getEventsForMonth(currentMonth, region: region));

    // Événements du mois prochain qui commencent
    for (final crop in _crops.values) {
      if (region != null && !crop.suitableRegions.contains(region)) continue;

      for (final event in crop.calendarEvents) {
        if (event.startMonth == nextMonth) {
          events.add(event);
        }
      }
    }

    return events;
  }

  /// Recherche de cultures par nom
  List<CropInfo> searchCrops(String query) {
    final lowerQuery = query.toLowerCase();
    return _crops.values.where((crop) {
      return crop.name.toLowerCase().contains(lowerQuery) ||
          crop.names.values.any((n) => n.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Obtient une culture par ID
  CropInfo? getCropById(String cropId) {
    return _crops[cropId];
  }

  /// Obtient toutes les cultures
  List<CropInfo> getAllCrops() {
    return _crops.values.toList();
  }

  /// Obtient les cultures par catégorie
  List<CropInfo> getCropsByCategory(String category) {
    return _crops.values.where((c) => c.category == category).toList();
  }

  /// Liste des catégories de cultures
  List<String> getCategories() {
    return _crops.values.map((c) => c.category).toSet().toList()..sort();
  }

  /// Obtient la saison actuelle
  CropSeason getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 6) {
      return CropSeason.grandeSaisonPluies;
    } else if (month == 7 || month == 8) {
      return CropSeason.petiteSaisonSeche;
    } else if (month >= 9 && month <= 11) {
      return CropSeason.petiteSaisonPluies;
    } else {
      return CropSeason.grandeSaisonSeche;
    }
  }

  /// Obtient les conseils pour la saison actuelle
  List<String> getSeasonalAdvice() {
    final season = getCurrentSeason();
    switch (season) {
      case CropSeason.grandeSaisonPluies:
        return [
          'Période idéale pour les plantations',
          'Surveiller les maladies fongiques',
          'Préparer le drainage des parcelles',
          'Semer les cultures vivrières',
        ];
      case CropSeason.petiteSaisonSeche:
        return [
          'Réduire les arrosages',
          'Récolter les cultures précoces',
          'Préparer les semences pour le 2ème cycle',
          'Entretenir les cultures pérennes',
        ];
      case CropSeason.petiteSaisonPluies:
        return [
          'Dernière chance pour les semis annuels',
          'Planter les légumes de saison sèche',
          'Surveiller les ravageurs',
          'Fertiliser les cultures en place',
        ];
      case CropSeason.grandeSaisonSeche:
        return [
          'Irriguer les cultures sensibles',
          'Récolter les cultures de rente',
          'Préparer le sol pour la prochaine saison',
          'Stocker les récoltes correctement',
        ];
    }
  }
}
