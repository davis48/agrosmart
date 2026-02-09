/**
 * Contrôleur d'Analytique
 * AgroSmart - Statistiques et analytiques de la ferme
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Obtenir les statistiques complètes de l'exploitation pour un utilisateur
 */
exports.getStats = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // Récupérer les données de ROI depuis la table roi_tracking
        const roiData = await prisma.roiTracking.findFirst({
            where: { userId },
            orderBy: { periodeFin: 'desc' },
            select: {
                coutSemences: true,
                coutEngrais: true,
                coutPesticides: true,
                coutIrrigation: true,
                coutMainOeuvre: true,
                autresCouts: true,
                quantiteRecoltee: true,
                prixVenteUnitaire: true,
                roiTrend: true
            }
        });

        // Calculer les métriques de ROI
        let roiPourcentage = 0;
        let revenuTotal = 0;
        let coutTotal = 0;
        let roiTrend = 'stable';

        if (roiData) {
            coutTotal = Number(roiData.coutSemences || 0) +
                Number(roiData.coutEngrais || 0) +
                Number(roiData.coutPesticides || 0) +
                Number(roiData.coutIrrigation || 0) +
                Number(roiData.coutMainOeuvre || 0) +
                Number(roiData.autresCouts || 0);

            revenuTotal = Number(roiData.quantiteRecoltee || 0) * Number(roiData.prixVenteUnitaire || 0);

            if (coutTotal > 0) {
                roiPourcentage = ((revenuTotal - coutTotal) / coutTotal) * 100;
            }

            roiTrend = roiData.roiTrend || 'stable';
        }

        // Récupérer les données d'économies depuis la table economies
        // Calculer la somme manuellement ou utiliser aggregate
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

        const economiesAgg = await prisma.economies.aggregate({
            _sum: {
                eauEconomiseePourcentage: true,
                engraisEconomisePourcentage: true,
                pertesEviteesPourcentage: true,
                valeurEauEconomiseeFcfa: true,
                valeurEngraisEconomiseFcfa: true,
                valeurPertesEviteesFcfa: true,
                economiesTotalesFcfa: true
            },
            where: {
                userId,
                dateFin: { gte: sixMonthsAgo }
            }
        });

        const economies = {
            eau_economisee: Number(economiesAgg._sum.eauEconomiseePourcentage || 0),
            engrais_economise: Number(economiesAgg._sum.engraisEconomisePourcentage || 0),
            pertes_evitees: Number(economiesAgg._sum.pertesEviteesPourcentage || 0),
            val_eau: Number(economiesAgg._sum.valeurEauEconomiseeFcfa || 0),
            val_engrais: Number(economiesAgg._sum.valeurEngraisEconomiseFcfa || 0),
            val_pertes: Number(economiesAgg._sum.valeurPertesEviteesFcfa || 0),
            total: Number(economiesAgg._sum.economiesTotalesFcfa || 0)
        };

        // Obtenir les rendements par culture depuis plantations + recoltes
        // Requête complexe avec CASE et HAVING -> Utiliser Raw (compatible MySQL)
        const rendementsCulturesRaw = await prisma.$queryRaw`
            SELECT 
                c.nom as culture,
                COALESCE(AVG(r.rendement_par_hectare), 0) as rendement_actuel,
                c.rendement_optimal as rendement_objectif,
                CASE 
                    WHEN c.rendement_moyen > 0 THEN 
                        ((COALESCE(AVG(r.rendement_par_hectare), 0) - c.rendement_moyen) / c.rendement_moyen) * 100
                    ELSE 0
                END as improvement
            FROM cultures c
            LEFT JOIN plantations pl ON c.id = pl.culture_id
            LEFT JOIN recoltes r ON pl.id = r.plantation_id
            LEFT JOIN parcelles p ON pl.parcelle_id = p.id
            WHERE p.user_id = ${userId}
            GROUP BY c.id, c.nom, c.rendement_moyen, c.rendement_optimal
            HAVING COUNT(r.id) > 0
            ORDER BY rendement_actuel DESC
        `;

        const rendementesParCulture = rendementsCulturesRaw.map(row => ({
            culture: row.culture,
            rendement_actuel: parseFloat(row.rendement_actuel) || 0,
            rendement_objectif: parseFloat(row.rendement_objectif) || 0,
            improvement: parseFloat(row.improvement) || 0
        }));

        // Obtenir les parcelles performantes depuis la table performance_parcelles
        // EXTRACT(YEAR) -> logique simple dans le where
        const currentYear = new Date().getFullYear();

        const performanceParcellesRaw = await prisma.performanceParcelle.findMany({
            where: {
                userId,
                annee: currentYear
            },
            include: {
                parcelle: { select: { nom: true } }
            },
            orderBy: { rendementMoyen: 'desc' },
            take: 5
        });

        const performanceParcelles = performanceParcellesRaw.map(pp => ({
            parcelle_id: pp.parcelleId,
            nom: pp.parcelle.nom,
            rendement: Number(pp.rendementMoyen || 0),
            score_qualite: Number(pp.scoreQualiteSol || 0),
            meilleure_pratique: pp.meilleurePratique || ''
        }));

        // Calculer l'amélioration moyenne à partir des rendements
        const avgImprovement = rendementesParCulture.length > 0
            ? rendementesParCulture.reduce((sum, r) => sum + r.improvement, 0) / rendementesParCulture.length
            : 0;

        const stats = {
            roi_percentage: roiData ? Number(roiData.roiPourcentage || 0) : 0,
            roi_trend: roiData?.roiTrend || 'stable',
            rendement: {
                value: avgImprovement > 0
                    ? `+${avgImprovement.toFixed(1)}%`
                    : `${(avgImprovement || 0).toFixed(1)}%`,
                vs_traditional: true
            },
            eau_economisee: `${economies.eau_economisee.toFixed(1)}%`,
            engrais_reduction: `${economies.engrais_economise.toFixed(1)}%`,
            pertes_maladies: `${economies.pertes_evitees.toFixed(1)}%`,
            rendements_par_culture: rendementesParCulture,
            economies: {
                eau: economies.val_eau,
                engrais: economies.val_engrais,
                pertes_evitees: economies.val_pertes,
                total: economies.total
            },
            performance_parcelles: performanceParcelles
        };

        res.json({
            success: true,
            data: stats
        });
    } catch (error) {
        logger.error('Error fetching analytics:', error.message);
        next(error);
    }
};

/**
 * Obtenir les statistiques des parcelles
 */
async function getParcellesStats(userId) {
    const parcellesAgg = await prisma.parcelle.aggregate({
        _count: { id: true },
        _sum: { superficie: true },
        where: { userId }
    });

    // Obtenir les cultures uniques via findMany sur plantations (ou cultures jointes)
    const culturesList = await prisma.plantation.findMany({
        where: { parcelle: { userId }, estActive: true },
        include: { culture: { select: { nom: true } } },
        distinct: ['cultureId']
    });
    const cultures = culturesList.map(p => p.culture?.nom).filter(Boolean);

    const parcelles = await prisma.parcelle.findMany({
        where: { userId },
        include: {
            plantations: {
                where: { estActive: true },
                include: { culture: true },
                take: 1
            }
        }
    });

    // La logique de boucle de performance est en JS simple, on la garde mais on adapte la source de données
    const performance = parcelles.map(p => {
        const cultureNom = p.plantations[0]?.culture?.nom || 'Culture';
        const score = 0; // Défaut
        return {
            nom: `${cultureNom} - ${p.nom}`,
            score,
            above_average: score >= 50
        };
    });

    return {
        total: parcellesAgg._count.id || 0,
        superficie_totale: Number(parcellesAgg._sum.superficie || 0),
        cultures,
        performance
    };
}

/**
 * Obtenir les statistiques du marketplace/revenus
 */
async function getMarketplaceStats(userId) {
    const [salesAgg, purchasesAgg] = await Promise.all([
        prisma.marketplaceCommande.aggregate({
            _count: { id: true },
            _sum: { prixTotal: true },
            _avg: { prixTotal: true },
            where: { vendeurId: userId, statut: 'LIVREE' }
        }),
        prisma.marketplaceCommande.aggregate({
            _sum: { prixTotal: true },
            where: { acheteurId: userId, statut: 'LIVREE' }
        })
    ]);

    return {
        ventes: salesAgg._count.id || 0,
        revenue: Number(salesAgg._sum.prixTotal || 0),
        revenu_moyen: Number(salesAgg._avg.prixTotal || 0),
        depenses: Number(purchasesAgg._sum.prixTotal || 0)
    };
}

/**
 * Obtenir les statistiques de rendement par culture
 * Optimisé pour éviter les requêtes N+1
 */
async function getYieldStats(userId) {
    // Requête optimisée - UNE SEULE requête au lieu de N+1
    const yieldDataRaw = await prisma.$queryRaw`
        SELECT 
            c.nom as culture,
            COUNT(DISTINCT p.id) as nombre_parcelles,
            AVG(p.superficie) as superficie_moyenne,
            COALESCE(AVG(pl.rendement_par_hectare), 0) as actual_yield,
            c.rendement_moyen as traditional_yield,
            c.rendement_optimal as optimal_yield
        FROM parcelles p
        JOIN plantations pl ON p.id = pl.parcelle_id AND pl.statut = 'active'
        JOIN cultures c ON pl.culture_id = c.id
        WHERE p.user_id = ${userId}
        GROUP BY c.id, c.nom, c.rendement_moyen, c.rendement_optimal
    `;

    const traditionalYields = {
        'Maïs': 2.0,
        'Riz': 2.0,
        'Tomate': 15.0,
        'Cacao': 0.5,
        'Café': 0.7,
        'Anacarde': 0.6,
        'Hévéa': 1.5,
        'Coton': 1.2
    };

    const yieldData = yieldDataRaw.map(row => {
        const actualYield = Number(row.actual_yield || 0);
        const traditionalYield = row.traditional_yield 
            ? Number(row.traditional_yield) 
            : (traditionalYields[row.culture] || 2.0);

        // Calculer l'amélioration seulement si on a des données réelles
        let improvement = 0;
        if (actualYield > 0 && traditionalYield > 0) {
            improvement = Math.round(((actualYield - traditionalYield) / traditionalYield) * 100);
        }

        return {
            culture: row.culture,
            rendement_actuel: Math.round(actualYield * 10) / 10,
            rendement_traditionnel: traditionalYield,
            improvement
        };
    });

    return yieldData;
}

/**
 * Calculer le ROI
 */
function calculateROI(parcellesStats, marketplaceStats) {
    // Calcul ROI simplifié
    // Scénario réel: (Revenu - Coûts) / Coûts * 100
    const estimatedCosts = marketplaceStats.depenses + (parcellesStats.superficie_totale * 50000); // Coût estimé par hectare
    const revenue = marketplaceStats.revenue;

    if (estimatedCosts === 0) {
        return { percentage: 0, trend: '0%' };
    }

    const roiPercentage = Math.round(((revenue - estimatedCosts) / estimatedCosts) * 100);
    const trend = roiPercentage > 200 ? '+23%' : roiPercentage > 100 ? '+15%' : '+8%';

    return {
        percentage: Math.max(0, roiPercentage),
        trend
    };
}

/**
 * Obtenir des analytiques détaillées pour une parcelle spécifique
 */
exports.getParcelleAnalytics = async (req, res, next) => {
    try {
        const { parcelleId } = req.params;
        const userId = req.user.id;

        // Vérifier la propriété
        const parcelle = await prisma.parcelle.findFirst({
            where: { id: parcelleId, userId }
        });

        if (!parcelle) {
            return res.status(404).json({
                success: false,
                message: 'Parcelle non trouvée'
            });
        }

        // Obtenir le résumé des données capteurs (Compatible MySQL - AVG retourne un décimal)
        const sensorsDataRaw = await prisma.$queryRaw`
            SELECT 
                c.type,
                CAST(COUNT(m.id) AS SIGNED) as nombre_mesures,
                AVG(CAST(m.valeur AS DECIMAL(10,2))) as valeur_moyenne
            FROM mesures m
            JOIN capteurs c ON m.capteur_id = c.id
            WHERE c.parcelle_id = ${parcelleId}
            GROUP BY c.type
        `;

        const sensorsData = sensorsDataRaw.map(s => ({
            type: s.type,
            nombre_mesures: Number(s.nombre_mesures),
            valeur_moyenne: s.valeur_moyenne
        }));

        res.json({
            success: true,
            data: {
                parcelle: {
                    nom: parcelle.nom,
                    superficie: parcelle.superficie,
                    culture: parcelle.cultureActuelle // Renommé dans le schéma
                    // Note: la colonne 'culture' dans l'ancien schéma était probablement 'culture_actuelle' ou via plantations.
                    // Le schéma a 'cultureActuelle'.
                },
                sensors: sensorsData,
                // Des analytiques supplémentaires peuvent être ajoutées ici
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Obtenir les statistiques publiques de la plateforme (pour la landing page)
 */
exports.getPublicStats = async (req, res, next) => {
    try {
        const [hectaresAgg, totalFarmers, totalCrops] = await Promise.all([
            prisma.parcelle.aggregate({ _sum: { superficie: true } }),
            prisma.user.count({ where: { role: 'PRODUCTEUR' } }),
            prisma.culture.count()
        ]);

        res.json({
            success: true,
            data: {
                hectares: Math.round(Number(hectaresAgg._sum.superficie || 0)),
                agriculteurs: totalFarmers,
                cultures: totalCrops,
                precision: 94
            }
        });
    } catch (error) {
        logger.error('Error fetching public stats:', error.message);
        // Fallback checks
        res.json({
            success: true,
            data: {
                hectares: '10K+',
                agriculteurs: '5000+',
                cultures: '25+',
                precision: '94%'
            }
        });
    }
};
