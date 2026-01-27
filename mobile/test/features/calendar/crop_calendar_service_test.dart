/// Tests pour le service de calendrier cultural
/// AgriSmart CI - Application Mobile
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:agriculture/features/calendar/services/crop_calendar_service.dart';

void main() {
  late CropCalendarService calendarService;

  setUp(() {
    calendarService = CropCalendarService();
  });

  group('CropCalendarService', () {
    test('should initialize successfully', () async {
      await calendarService.initialize();
      expect(calendarService.currentRegion, AgricultureRegion.centre);
    });

    test('should change region', () {
      calendarService.setRegion(AgricultureRegion.nordSavane);
      expect(calendarService.currentRegion, AgricultureRegion.nordSavane);
    });

    test('should return crops for all regions', () {
      final crops = calendarService.getAllCrops();
      expect(crops.isNotEmpty, true);
      expect(crops.length, greaterThan(10)); // Au moins 10 cultures
    });

    test('should return crops by category', () {
      final cereales = calendarService.getCropsByCategory('Céréales');
      expect(cereales.isNotEmpty, true);

      for (final crop in cereales) {
        expect(crop.category, 'Céréales');
      }
    });

    test('should return categories', () {
      final categories = calendarService.getCategories();
      expect(categories.contains('Céréales'), true);
      expect(categories.contains('Cultures de rente'), true);
      expect(categories.contains('Maraîchage'), true);
      expect(categories.contains('Tubercules'), true);
    });

    test('should return events for month', () {
      // Mars est un mois actif pour beaucoup de cultures
      final events = calendarService.getEventsForMonth(3);
      expect(events.isNotEmpty, true);
    });

    test('should filter events by region', () {
      // Le cacao n'est pas adapté au nord
      final eventsNord = calendarService.getEventsForMonth(
        4,
        region: AgricultureRegion.nordSavane,
      );

      final eventsSud = calendarService.getEventsForMonth(
        4,
        region: AgricultureRegion.sudForestier,
      );

      // Le sud forestier devrait avoir des événements cacao
      final cacaoSud = eventsSud.where((e) => e.cropId == 'cacao').toList();
      final cacaoNord = eventsNord.where((e) => e.cropId == 'cacao').toList();

      expect(cacaoSud.length, greaterThanOrEqualTo(cacaoNord.length));
    });

    test('should return crop by id', () {
      final cacao = calendarService.getCropById('cacao');
      expect(cacao, isNotNull);
      expect(cacao!.name, 'Cacao');
      expect(cacao.emoji, '🍫');
    });

    test('should return null for unknown crop id', () {
      final unknown = calendarService.getCropById('unknown_crop');
      expect(unknown, isNull);
    });

    test('should return recommended crops for region', () {
      final cropsNord = calendarService.getRecommendedCrops(
        AgricultureRegion.nordSavane,
      );
      final cropsSud = calendarService.getRecommendedCrops(
        AgricultureRegion.sudForestier,
      );

      // L'igname est adapté au nord
      expect(cropsNord.any((c) => c.id == 'igname'), true);

      // Le cacao est adapté au sud
      expect(cropsSud.any((c) => c.id == 'cacao'), true);
    });

    test('should search crops by name', () {
      final results = calendarService.searchCrops('cacao');
      expect(results.isNotEmpty, true);
      expect(results.first.id, 'cacao');
    });

    test('should search crops by local name', () {
      // Recherche par nom en dioula
      final results = calendarService.searchCrops('malo'); // riz en dioula
      expect(results.isNotEmpty, true);
    });

    test('should return current season', () {
      final season = calendarService.getCurrentSeason();
      expect(CropSeason.values.contains(season), true);
    });

    test('should return seasonal advice', () {
      final advice = calendarService.getSeasonalAdvice();
      expect(advice.isNotEmpty, true);
      expect(advice.length, greaterThanOrEqualTo(3));
    });

    test('should return upcoming activities', () {
      final upcoming = calendarService.getUpcomingActivities();
      // Devrait toujours y avoir des activités à venir
      expect(upcoming, isNotNull);
    });

    test('should get crop calendar events', () {
      final events = calendarService.getCropCalendar('riz');
      expect(events.isNotEmpty, true);

      // Le riz devrait avoir des événements de semis et récolte
      final hasSeeding = events.any((e) => e.activity == FarmActivity.semis);
      final hasHarvest = events.any((e) => e.activity == FarmActivity.recolte);

      expect(hasSeeding, true);
      expect(hasHarvest, true);
    });

    test('event isActiveInMonth should work correctly', () {
      final event = CropCalendarEvent(
        cropId: 'test',
        cropName: 'Test',
        activity: FarmActivity.semis,
        startMonth: 3,
        endMonth: 5,
        description: 'Test event',
      );

      expect(event.isActiveInMonth(2), false);
      expect(event.isActiveInMonth(3), true);
      expect(event.isActiveInMonth(4), true);
      expect(event.isActiveInMonth(5), true);
      expect(event.isActiveInMonth(6), false);
    });

    test('event isActiveInMonth should handle year wrap', () {
      // Événement qui chevauche le nouvel an (novembre à février)
      final event = CropCalendarEvent(
        cropId: 'test',
        cropName: 'Test',
        activity: FarmActivity.recolte,
        startMonth: 11,
        endMonth: 2,
        description: 'Test event crossing year',
      );

      expect(event.isActiveInMonth(10), false);
      expect(event.isActiveInMonth(11), true);
      expect(event.isActiveInMonth(12), true);
      expect(event.isActiveInMonth(1), true);
      expect(event.isActiveInMonth(2), true);
      expect(event.isActiveInMonth(3), false);
    });

    test('CropInfo should return localized name', () {
      final cacao = calendarService.getCropById('cacao')!;

      expect(cacao.getLocalizedName('fr'), 'Cacao');
      expect(cacao.getLocalizedName('dyu'), 'Cacao');
      // Pour une langue inconnue, retourne le français
      expect(cacao.getLocalizedName('xx'), 'Cacao');
    });

    test('AgricultureRegion should find region from city', () {
      final region = AgricultureRegion.fromCity('Abidjan');
      expect(region, AgricultureRegion.sudForestier);

      final region2 = AgricultureRegion.fromCity('Korhogo');
      expect(region2, AgricultureRegion.nordSavane);

      final unknown = AgricultureRegion.fromCity('Paris');
      expect(unknown, isNull);
    });
  });
}
