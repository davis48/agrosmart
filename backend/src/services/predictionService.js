/**
 * Service de Prédiction et d'Analyse IA
 * Gère les prédictions de rendement et les cartes de chaleur des ravageurs
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Générer les données pour la heatmap des ravageurs
 * @param {string} regionId - ID de la région (optionnel)
 * @returns {Promise<Array>} Liste des points chauds
 */
exports.getPestHeatmapData = async (regionId) => {
  try {
    // Dans un cas réel, on filtrerait par région géographique
    // Ici, on simule ou on récupère les diagnostics récents positifs
    // On suppose que le modèle Diagnostic a 'location' (lat, lon) et 'result'

    /* 
    Schema Diagnostic supposé:
    - location: Json { lat, lng }
    - maladie: String (Nom de la maladie détectée)
    - confidence: Float
    - createdAt: DateTime
    */

    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    const diagnostics = await prisma.diagnostic.findMany({
      where: {
        createdAt: { gt: oneMonthAgo },
        // On ne prend que ce qui a été détecté avec une forte confiance
        scoreConfiance: { gt: 0.7 },
        diseaseName: { not: null }
      },
      select: {
        diseaseName: true,
        localisation: true, // Suppose stored as string "lat,lon" or JSON
        createdAt: true
      }
    });

    // Transformer en format heatmap
    // Si localisation est "lat,lon"
    const points = diagnostics
      .filter(d => d.localisation && d.localisation.includes(','))
      .map(d => {
        const [lat, lng] = d.localisation.split(',').map(s => parseFloat(s.trim()));
        return {
          lat,
          lng,
          intensity: 1.0, // Base intensity
          disease: d.diseaseName
        };
      });

    // Ajouter des données simulées si pas assez de données réelles pour la démo
    if (points.length < 5) {
      // Abidjan area simulation
      points.push(
        { lat: 5.3600, lng: -4.0083, intensity: 0.8, disease: 'Mildiou' },
        { lat: 5.3700, lng: -4.0183, intensity: 0.6, disease: 'Rouille' },
        { lat: 5.3500, lng: -3.9983, intensity: 0.9, disease: 'Chenille' }
      );
    }

    return points;
  } catch (error) {
    logger.error('Erreur récupération heatmap', { error: error.message });
    throw error;
  }
};

/**
 * Prédire le rendement futur (Mock IA)
 */
exports.predictYield = async (parcelleId, dateRecolte) => {
  // Logique simulée pour l'instant
  return {
    estime: 12.5, // Tonnes
    confiance: 0.85,
    facteurs: ['Pluviométrie favorable', 'Sol riche']
  };
};
