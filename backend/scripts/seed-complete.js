/**
 * Script de Seed Complet - Toutes les tables
 * Agrosmart CI - Système Agricole Intelligent
 * 
 * Ce script remplit TOUTES les tables de la base de données avec des données réalistes
 * pour permettre des tests complets de l'application mobile et web.
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// Données réalistes pour la Côte d'Ivoire
const REGIONS_CI = [
  { nom: 'Abidjan', code: 'ABJ', chefLieu: 'Abidjan', superficieKm2: 2119 },
  { nom: 'Yamoussoukro', code: 'YAM', chefLieu: 'Yamoussoukro', superficieKm2: 3500 },
  { nom: 'Bouaké', code: 'BKE', chefLieu: 'Bouaké', superficieKm2: 6800 },
  { nom: 'Daloa', code: 'DLO', chefLieu: 'Daloa', superficieKm2: 15200 },
  { nom: 'Korhogo', code: 'KRG', chefLieu: 'Korhogo', superficieKm2: 12500 },
  { nom: 'Man', code: 'MAN', chefLieu: 'Man', superficieKm2: 9200 },
  { nom: 'San-Pédro', code: 'SPD', chefLieu: 'San-Pédro', superficieKm2: 6900 }
];

const COOPERATIVES_DATA = [
  { nom: 'Coopérative des Producteurs de Cacao de Daloa', code: 'CPCD-001', nombreMembres: 450 },
  { nom: 'Union des Planteurs de Café de Bouaké', code: 'UPCB-002', nombreMembres: 320 },
  { nom: 'Société Coopérative Agricole de Man', code: 'SCAM-003', nombreMembres: 280 },
  { nom: 'Coopérative Rizicole de Korhogo', code: 'CRK-004', nombreMembres: 560 },
  { nom: "Groupement des Producteurs d'Hévéa de San-Pédro", code: 'GPHSP-005', nombreMembres: 390 }
];

const CULTURES_DATA = [
  { 
    nom: 'Cacao', 
    nomScientifique: 'Theobroma cacao',
    categorie: 'FRUITS',
    saisonCulture: 'Toute l\'année',
    dureeJours: 1825,
    phOptimal: 6.5,
    temperatureMin: 21,
    temperatureMax: 32,
    rendementMoyen: 600,
    rendementOptimal: 1200
  },
  { 
    nom: 'Café Robusta', 
    nomScientifique: 'Coffea canephora',
    categorie: 'FRUITS',
    saisonCulture: 'Octobre à Mai',
    dureeJours: 1095,
    phOptimal: 6.0,
    temperatureMin: 20,
    temperatureMax: 30,
    rendementMoyen: 800,
    rendementOptimal: 1500
  },
  { 
    nom: 'Hévéa', 
    nomScientifique: 'Hevea brasiliensis',
    categorie: 'OLEAGINEUX',
    saisonCulture: 'Toute l\'année',
    dureeJours: 2555,
    phOptimal: 5.5,
    temperatureMin: 20,
    temperatureMax: 35,
    rendementMoyen: 1500,
    rendementOptimal: 2500
  },
  { 
    nom: 'Manioc', 
    nomScientifique: 'Manihot esculenta',
    categorie: 'TUBERCULES',
    saisonCulture: 'Mars à Juin',
    dureeJours: 365,
    phOptimal: 6.0,
    temperatureMin: 25,
    temperatureMax: 35,
    rendementMoyen: 12000,
    rendementOptimal: 20000
  },
  { 
    nom: 'Igname', 
    nomScientifique: 'Dioscorea spp',
    categorie: 'TUBERCULES',
    saisonCulture: 'Avril à Juillet',
    dureeJours: 270,
    phOptimal: 6.5,
    temperatureMin: 25,
    temperatureMax: 30,
    rendementMoyen: 10000,
    rendementOptimal: 18000
  },
  { 
    nom: 'Maïs', 
    nomScientifique: 'Zea mays',
    categorie: 'CEREALES',
    saisonCulture: 'Mars à Juin et Septembre à Novembre',
    dureeJours: 120,
    phOptimal: 6.5,
    temperatureMin: 18,
    temperatureMax: 32,
    rendementMoyen: 2500,
    rendementOptimal: 5000
  },
  { 
    nom: 'Riz', 
    nomScientifique: 'Oryza sativa',
    categorie: 'CEREALES',
    saisonCulture: 'Mai à Octobre',
    dureeJours: 135,
    phOptimal: 6.0,
    temperatureMin: 20,
    temperatureMax: 35,
    rendementMoyen: 3000,
    rendementOptimal: 6000
  },
  { 
    nom: 'Banane Plantain', 
    nomScientifique: 'Musa paradisiaca',
    categorie: 'FRUITS',
    saisonCulture: 'Toute l\'année',
    dureeJours: 365,
    phOptimal: 6.5,
    temperatureMin: 25,
    temperatureMax: 35,
    rendementMoyen: 8000,
    rendementOptimal: 15000
  },
  { 
    nom: 'Tomate', 
    nomScientifique: 'Solanum lycopersicum',
    categorie: 'LEGUMES',
    saisonCulture: 'Novembre à Mai',
    dureeJours: 90,
    phOptimal: 6.5,
    temperatureMin: 18,
    temperatureMax: 30,
    rendementMoyen: 30000,
    rendementOptimal: 60000
  },
  { 
    nom: 'Piment', 
    nomScientifique: 'Capsicum annuum',
    categorie: 'LEGUMES',
    saisonCulture: 'Mars à Novembre',
    dureeJours: 120,
    phOptimal: 6.5,
    temperatureMin: 20,
    temperatureMax: 32,
    rendementMoyen: 8000,
    rendementOptimal: 15000
  }
];

const MALADIES_DATA = [
  {
    nom: 'Pourriture brune du cacao',
    nomScientifique: 'Phytophthora palmivora',
    type: 'fongique',
    description: 'Maladie fongique grave affectant les cabosses de cacao',
    symptomes: 'Taches brunes sur cabosses, pourriture rapide, perte de récolte',
    culturesAffectees: ['Cacao'],
    prevention: ['Élagage régulier', 'Drainage adéquat', 'Élimination des cabosses infectées'],
    traitements: ['Fongicides à base de cuivre', 'Biofongicides', 'Quarantaine des zones infectées']
  },
  {
    nom: 'Swollen Shoot du cacao',
    nomScientifique: 'Cacao swollen shoot virus',
    type: 'virale',
    description: 'Maladie virale transmise par cochenilles',
    symptomes: 'Gonflement des tiges, déformation des feuilles, baisse de rendement sévère',
    culturesAffectees: ['Cacao'],
    prevention: ['Contrôle des vecteurs', 'Utilisation de plants sains', 'Quarantaine'],
    traitements: ['Arrachage des plants infectés', 'Lutte contre cochenilles']
  },
  {
    nom: 'Rouille orangée du caféier',
    nomScientifique: 'Hemileia vastatrix',
    type: 'fongique',
    description: 'Maladie fongique la plus destructrice du café',
    symptomes: 'Pustules orangées sous les feuilles, jaunissement, chute précoce',
    culturesAffectees: ['Café Robusta'],
    prevention: ['Espacement adéquat', 'Ombrage contrôlé', 'Nutrition équilibrée'],
    traitements: ['Fongicides systémiques', 'Cuivre', 'Variétés résistantes']
  },
  {
    nom: 'Anthracnose',
    nomScientifique: 'Colletotrichum spp',
    type: 'fongique',
    description: 'Maladie fongique à large spectre',
    symptomes: 'Taches noires circulaires, nécroses, dépérissement des tissus',
    culturesAffectees: ['Manioc', 'Igname', 'Tomate', 'Piment'],
    prevention: ['Rotation culturale', 'Semences saines', 'Hygiène des parcelles'],
    traitements: ['Fongicides de contact', 'Cuivre', 'Trichoderma']
  },
  {
    nom: 'Mosaïque du manioc',
    nomScientifique: 'Cassava mosaic virus',
    type: 'virale',
    description: 'Maladie virale transmise par aleurodes',
    symptomes: 'Marbrure chlorotique des feuilles, déformation, nanisme',
    culturesAffectees: ['Manioc'],
    prevention: ['Boutures saines', 'Contrôle des aleurodes', 'Variétés résistantes'],
    traitements: ['Élimination plants infectés', 'Lutte contre vecteurs']
  },
  {
    nom: 'Mildiou de la tomate',
    nomScientifique: 'Phytophthora infestans',
    type: 'fongique',
    description: 'Maladie dévastatrice des solanacées',
    symptomes: 'Taches brunes humides, feutrage blanc, pourriture fruits',
    culturesAffectees: ['Tomate', 'Piment'],
    prevention: ['Espacement suffisant', 'Éviter arrosage foliaire', 'Mulching'],
    traitements: ['Fongicides préventifs', 'Cuivre', 'Biofongicides']
  },
  {
    nom: 'Helminthosporiose du riz',
    nomScientifique: 'Cochliobolus miyabeanus',
    type: 'fongique',
    description: 'Maladie fongique commune du riz',
    symptomes: 'Taches brunes allongées sur feuilles, dessèchement',
    culturesAffectees: ['Riz'],
    prevention: ['Variétés résistantes', 'Gestion de l\'azote', 'Rotation'],
    traitements: ['Fongicides', 'Tricyclazole', 'Carbendazime']
  },
  {
    nom: 'Panama du bananier',
    nomScientifique: 'Fusarium oxysporum',
    type: 'fongique',
    description: 'Maladie vasculaire du bananier',
    symptomes: 'Jaunissement des feuilles, flétrissement, mort du plant',
    culturesAffectees: ['Banane Plantain'],
    prevention: ['Plants certifiés', 'Désinfection outils', 'Rotation longue'],
    traitements: ['Pratiquement incurable', 'Variétés résistantes', 'Biosécurité stricte']
  }
];

const PRODUITS_MARKETPLACE = [
  { nom: 'Cacao séché premium', categorie: 'recolte', prix: 1500, unite: 'kg', stock: 500, description: 'Fèves de cacao séchées et fermentées, qualité export' },
  { nom: 'Café Robusta grain', categorie: 'recolte', prix: 2000, unite: 'kg', stock: 300, description: 'Grains de café Robusta séchés, première qualité' },
  { nom: 'Latex d\'hévéa', categorie: 'recolte', prix: 800, unite: 'kg', stock: 1000, description: 'Latex naturel frais, coagulum de qualité' },
  { nom: 'Manioc frais', categorie: 'recolte', prix: 400, unite: 'kg', stock: 800, description: 'Tubercules de manioc fraîchement récoltés' },
  { nom: 'Igname Kponan', categorie: 'recolte', prix: 700, unite: 'kg', stock: 400, description: 'Igname de qualité supérieure, variété Kponan' },
  { nom: 'Maïs grain', categorie: 'recolte', prix: 350, unite: 'kg', stock: 1200, description: 'Grains de maïs jaune séchés' },
  { nom: 'Riz paddy local', categorie: 'recolte', prix: 450, unite: 'kg', stock: 900, description: 'Riz paddy non décortiqué, production locale' },
  { nom: 'Banane plantain mûr', categorie: 'recolte', prix: 500, unite: 'kg', stock: 600, description: 'Régimes de plantain mûr à point' },
  { nom: 'Tomates fraîches', categorie: 'recolte', prix: 600, unite: 'kg', stock: 300, description: 'Tomates bio récoltées du jour' },
  { nom: 'Piment frais', categorie: 'recolte', prix: 1200, unite: 'kg', stock: 150, description: 'Piment fort variété locale' },
  // Intrants
  { nom: 'Engrais NPK 15-15-15', categorie: 'intrants', prix: 28000, unite: 'sac 50kg', stock: 80, description: 'Engrais complet NPK équilibré' },
  { nom: 'Engrais Urée 46%', categorie: 'intrants', prix: 25000, unite: 'sac 50kg', stock: 60, description: 'Engrais azoté à libération rapide' },
  { nom: 'Fongicide Mancozèbe', categorie: 'intrants', prix: 12000, unite: 'kg', stock: 40, description: 'Fongicide de contact à large spectre' },
  { nom: 'Insecticide Lambda-cyhalothrine', categorie: 'intrants', prix: 15000, unite: 'litre', stock: 30, description: 'Insecticide pyréthrinoïde' },
  { nom: 'Herbicide Glyphosate', categorie: 'intrants', prix: 8000, unite: 'litre', stock: 50, description: 'Herbicide systémique total' },
  // Semences
  { nom: 'Semences Maïs hybride', categorie: 'semences', prix: 5000, unite: 'kg', stock: 200, description: 'Semences certifiées à haut rendement' },
  { nom: 'Semences Riz NERICA', categorie: 'semences', prix: 4500, unite: 'kg', stock: 150, description: 'Riz africain nouvelle génération' },
  { nom: 'Boutures Manioc TMS', categorie: 'semences', prix: 200, unite: 'unité', stock: 5000, description: 'Boutures résistantes à la mosaïque' },
  { nom: 'Plants Tomate F1', categorie: 'semences', prix: 150, unite: 'plant', stock: 1000, description: 'Plants hybrides vigoureux' },
  { nom: 'Tubercules Igname semence', categorie: 'semences', prix: 800, unite: 'kg', stock: 300, description: 'Ignames semencières certifiées' }
];

const FORMATIONS_DATA = [
  {
    titre: 'Introduction à l\'agriculture intelligente',
    description: 'Découvrez les bases de l\'agriculture de précision et les technologies IoT',
    categorie: 'technologie',
    niveau: 'Débutant',
    dureeMinutes: 90,
    modules: [
      { titre: 'Qu\'est-ce que l\'agriculture intelligente ?', contenu: 'Introduction aux concepts de base', ordre: 1 },
      { titre: 'Les capteurs IoT en agriculture', contenu: 'Types de capteurs et leurs utilisations', ordre: 2 },
      { titre: 'Interprétation des données', contenu: 'Comment lire et utiliser les données collectées', ordre: 3 }
    ]
  },
  {
    titre: 'Culture du cacao : de la plantation à la récolte',
    description: 'Formation complète sur les techniques modernes de cacaoculture',
    categorie: 'culture',
    niveau: 'Intermédiaire',
    dureeMinutes: 180,
    modules: [
      { titre: 'Préparation du terrain', contenu: 'Choix du site et préparation du sol', ordre: 1 },
      { titre: 'Plantation et entretien', contenu: 'Techniques de plantation et soins jeunes plants', ordre: 2 },
      { titre: 'Taille et élagage', contenu: 'Techniques de formation et entretien', ordre: 3 },
      { titre: 'Récolte et post-récolte', contenu: 'Cueillette, fermentation et séchage', ordre: 4 }
    ]
  },
  {
    titre: 'Gestion intégrée des ravageurs',
    description: 'Méthodes écologiques de lutte contre les ravageurs et maladies',
    categorie: 'protection',
    niveau: 'Avancé',
    dureeMinutes: 120,
    modules: [
      { titre: 'Principes de la lutte intégrée', contenu: 'Approche holistique de protection des cultures', ordre: 1 },
      { titre: 'Identification des ravageurs', contenu: 'Reconnaissance des principaux ravageurs', ordre: 2 },
      { titre: 'Méthodes de contrôle biologique', contenu: 'Auxiliaires et biopesticides', ordre: 3 }
    ]
  },
  {
    titre: 'Irrigation efficace et gestion de l\'eau',
    description: 'Optimisez votre consommation d\'eau avec les techniques modernes',
    categorie: 'pratique',
    niveau: 'Intermédiaire',
    dureeMinutes: 150,
    modules: [
      { titre: 'Besoins en eau des cultures', contenu: 'Calcul des besoins hydriques', ordre: 1 },
      { titre: 'Systèmes d\'irrigation', contenu: 'Goutte-à-goutte, aspersion, gravitaire', ordre: 2 },
      { titre: 'Pilotage de l\'irrigation', contenu: 'Utilisation des capteurs d\'humidité', ordre: 3 }
    ]
  },
  {
    titre: 'Fertilisation raisonnée',
    description: 'Optimisez vos apports d\'engrais pour un meilleur rendement',
    categorie: 'pratique',
    niveau: 'Intermédiaire',
    dureeMinutes: 120,
    modules: [
      { titre: 'Analyse de sol', contenu: 'Interprétation des analyses et carences', ordre: 1 },
      { titre: 'Plan de fertilisation', contenu: 'Calcul des doses et périodes d\'apport', ordre: 2 },
      { titre: 'Fertilisants organiques', contenu: 'Compost, fumier et engrais verts', ordre: 3 }
    ]
  }
];

const BADGES_DATA = [
  {
    nom: 'Pionnier',
    description: 'Première connexion à l\'application',
    icone: '🌱',
    points: 10,
    condition: { type: 'login', count: 1 }
  },
  {
    nom: 'Connecté',
    description: 'Se connecter 7 jours consécutifs',
    icone: '🔥',
    points: 50,
    condition: { type: 'consecutive_days', count: 7 }
  },
  {
    nom: 'Gestionnaire',
    description: 'Créer 5 parcelles',
    icone: '🗺️',
    points: 30,
    condition: { type: 'parcelle_count', count: 5 }
  },
  {
    nom: 'Technicien IoT',
    description: 'Installer 10 capteurs',
    icone: '📡',
    points: 40,
    condition: { type: 'capteur_count', count: 10 }
  },
  {
    nom: 'Étudiant assidu',
    description: 'Compléter 3 formations',
    icone: '🎓',
    points: 60,
    condition: { type: 'formation_completed', count: 3 }
  },
  {
    nom: 'Expert agricole',
    description: 'Compléter 10 formations',
    icone: '👨‍🌾',
    points: 150,
    condition: { type: 'formation_completed', count: 10 }
  },
  {
    nom: 'Détective',
    description: 'Réaliser 5 diagnostics de maladies',
    icone: '🔍',
    points: 35,
    condition: { type: 'diagnostic_count', count: 5 }
  },
  {
    nom: 'Commerçant',
    description: 'Publier 5 produits sur la marketplace',
    icone: '🛒',
    points: 25,
    condition: { type: 'produit_count', count: 5 }
  },
  {
    nom: 'Producteur exemplaire',
    description: 'Atteindre un rendement optimal sur une parcelle',
    icone: '🏆',
    points: 100,
    condition: { type: 'rendement_optimal', threshold: 0.9 }
  }
];

const REALISATIONS_DATA = [
  {
    nom: 'Première récolte',
    description: 'Enregistrer votre première récolte',
    points: 20,
    objectif: { type: 'recolte', count: 1 }
  },
  {
    nom: 'Récolte abondante',
    description: 'Récolter plus de 1000 kg au total',
    points: 50,
    objectif: { type: 'recolte_total_kg', threshold: 1000 }
  },
  {
    nom: 'Explorateur de données',
    description: 'Consulter vos statistiques 10 fois',
    points: 15,
    objectif: { type: 'stats_view', count: 10 }
  },
  {
    nom: 'Communicateur',
    description: 'Participer à 5 discussions sur le forum',
    points: 30,
    objectif: { type: 'forum_posts', count: 5 }
  },
  {
    nom: 'Entraide agricole',
    description: 'Répondre à 10 questions sur le forum',
    points: 40,
    objectif: { type: 'forum_responses', count: 10 }
  }
];

const ACHATS_GROUPES_DATA = [
  {
    titre: 'Engrais NPK 15-15-15 en gros',
    description: 'Achat groupé d\'engrais pour réduire les coûts. Livraison dans 3 semaines.',
    categorie: 'intrants',
    prixUnitaire: 30000,
    prixGroupe: 25000,
    quantiteObjectif: 100,
    minParPersonne: 2,
    dateLimite: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // Dans 14 jours
  },
  {
    titre: 'Semences de Maïs hybride certifiées',
    description: 'Achat groupé de semences certifiées à haut rendement',
    categorie: 'semences',
    prixUnitaire: 5500,
    prixGroupe: 4500,
    quantiteObjectif: 200,
    minParPersonne: 5,
    dateLimite: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000) // Dans 21 jours
  },
  {
    titre: 'Système d\'irrigation goutte-à-goutte',
    description: 'Kit complet d\'irrigation pour 1 hectare',
    categorie: 'equipement',
    prixUnitaire: 500000,
    prixGroupe: 420000,
    quantiteObjectif: 20,
    minParPersonne: 1,
    dateLimite: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // Dans 30 jours
  }
];

async function cleanDatabase() {
  console.log('🧹 Nettoyage de la base de données...');
  
  // Désactiver les contraintes de clés étrangères temporairement
  await prisma.$executeRaw`SET FOREIGN_KEY_CHECKS = 0;`;
  
  // Supprimer toutes les données (dans l'ordre inverse des dépendances)
  const tables = [
    'Mesure', 'Alerte', 'Capteur', 'Station', 
    'DetectionMaladie', 'Diagnostic', 'Recommandation',
    'Recolte', 'Plantation', 'RendementParCulture',
    'PerformanceParcelle', 'Economies', 'RoiTracking',
    'MouvementStock', 'AlerteStock', 'Stock',
    'CalendrierActivite', 'UserPoint',
    'ForumReponse', 'ForumPost', 'Message', 'Conversation',
    'ProgressionFormation', 'ModuleFormation', 'Formation',
    'FichePratique', 'UserFormationLegacy',
    'UserRealisation', 'Realisation', 'UserBadge', 'Badge',
    'ParticipationAchatGroupe', 'AchatGroupe',
    'TransactionPaiement', 'Location', 'EquipementLocation',
    'MarketplaceTransaction', 'MarketplaceCommande',
    'Avis', 'WishlistItem', 'Wishlist', 'CartItem', 'Cart', 'Favorite',
    'MarketplaceProduit',
    'Notification', 'ActivitiesLog', 'AuditLog',
    'LocationMateriel', 'RefreshToken', 'OtpCode', 'PasswordHistory',
    'Parcelle', 'Cooperative', 'User', 'Region',
    'Maladie', 'Culture', 'Meteo', 'Configuration'
  ];
  
  for (const table of tables) {
    try {
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${table};`);
    } catch (error) {
      // Certaines tables peuvent ne pas exister, on continue
      console.log(`  ⚠️  Table ${table} non trouvée ou déjà vide`);
    }
  }
  
  // Réactiver les contraintes
  await prisma.$executeRaw`SET FOREIGN_KEY_CHECKS = 1;`;
  
  console.log('  ✅ Base de données nettoyée\n');
}

async function seedRegions() {
  console.log('📍 Création des régions...');
  
  const regions = [];
  for (const region of REGIONS_CI) {
    const created = await prisma.region.create({
      data: region
    });
    regions.push(created);
  }
  
  console.log(`  ✅ ${regions.length} régions créées\n`);
  return regions;
}

async function seedCooperatives(regions) {
  console.log('🤝 Création des coopératives...');
  
  const cooperatives = [];
  for (let i = 0; i < COOPERATIVES_DATA.length; i++) {
    const data = COOPERATIVES_DATA[i];
    const cooperative = await prisma.cooperative.create({
      data: {
        ...data,
        regionId: regions[i % regions.length].id,
        adresse: `${data.nom}, ${regions[i % regions.length].chefLieu}`,
        telephone: `+225 ${20 + i} ${10 + i * 2} ${20 + i * 3} ${30 + i * 4}`,
        email: `contact@${data.code.toLowerCase()}.ci`,
        dateCreation: new Date(2020 + i, i % 12, 1)
      }
    });
    cooperatives.push(cooperative);
  }
  
  console.log(`  ✅ ${cooperatives.length} coopératives créées\n`);
  return cooperatives;
}

async function seedUsers(regions) {
  console.log('👤 Création des utilisateurs...');
  
  // ⚠️ Mot de passe par défaut pour les seeds de développement
  // Ne JAMAIS utiliser en production
  const defaultPassword = process.env.SEED_DEFAULT_PASSWORD || 'DevSeed@2024!';
  const hashedPassword = await bcrypt.hash(defaultPassword, 12);
  
  if (!process.env.SEED_DEFAULT_PASSWORD) {
    console.warn('⚠️  SEED: Utilisation du mot de passe par défaut (DEV uniquement)');
  }
  
  const users = [];
  
  // Admin
  const admin = await prisma.user.create({
    data: {
      nom: 'Kouassi',
      prenoms: 'Admin Système',
      email: 'admin@agrosmart.ci',
      telephone: '+2250101010101',
      passwordHash: hashedPassword,
      role: 'ADMIN',
      status: 'ACTIF',
      regionId: regions[0].id, // Abidjan
      emailVerifie: true,
      whatsappVerifie: true,
      points: 1000,
      niveau: 'Expert'
    }
  });
  users.push(admin);
  
  // Agronomes
  const agronomes = [
    { nom: 'Koné', prenoms: 'Ibrahim', region: 1 },
    { nom: 'Diabaté', prenoms: 'Mariam', region: 2 }
  ];
  
  for (let i = 0; i < agronomes.length; i++) {
    const agro = agronomes[i];
    const user = await prisma.user.create({
      data: {
        nom: agro.nom,
        prenoms: agro.prenoms,
        email: `${agro.prenoms.toLowerCase()}.${agro.nom.toLowerCase()}@agrosmart.ci`,
        telephone: `+225010202020${i}`,
        passwordHash: hashedPassword,
        role: 'AGRONOME',
        status: 'ACTIF',
        regionId: regions[agro.region].id,
        emailVerifie: true,
        points: 500,
        niveau: 'Professionnel'
      }
    });
    users.push(user);
  }
  
  // Conseillers
  const conseillers = [
    { nom: 'Touré', prenoms: 'Fanta', region: 3 },
    { nom: 'Soro', prenoms: 'Yacouba', region: 4 }
  ];
  
  for (let i = 0; i < conseillers.length; i++) {
    const cons = conseillers[i];
    const user = await prisma.user.create({
      data: {
        nom: cons.nom,
        prenoms: cons.prenoms,
        email: `${cons.prenoms.toLowerCase()}.${cons.nom.toLowerCase()}@agrosmart.ci`,
        telephone: `+225010303030${i}`,
        passwordHash: hashedPassword,
        role: 'CONSEILLER',
        status: 'ACTIF',
        regionId: regions[cons.region].id,
        emailVerifie: true,
        points: 400,
        niveau: 'Professionnel'
      }
    });
    users.push(user);
  }
  
  // Producteurs (20)
  const prenoms = ['Kouadio', 'Yao', 'N\'Guessan', 'Konan', 'Aya', 'Akissi', 'Adjoua', 'Affoué', 'Amenan', 'Brou'];
  const noms = ['Kouassi', 'Koné', 'Yao', 'Tra', 'Bamba', 'Ouattara', 'Sanogo', 'Coulibaly', 'Diallo', 'Camara'];
  
  for (let i = 0; i < 20; i++) {
    const user = await prisma.user.create({
      data: {
        nom: noms[i % noms.length],
        prenoms: prenoms[i % prenoms.length],
        email: `producteur${i + 1}@agrosmart.ci`,
        telephone: `+225070${String(i + 1).padStart(7, '0')}`,
        passwordHash: hashedPassword,
        role: 'PRODUCTEUR',
        status: 'ACTIF',
        regionId: regions[i % regions.length].id,
        emailVerifie: i % 2 === 0,
        whatsappVerifie: true,
        points: Math.floor(Math.random() * 300) + 50,
        niveau: i < 5 ? 'Expert' : (i < 12 ? 'Intermédiaire' : 'Novice'),
        production3MoisPrecedentsKg: 1000 + Math.random() * 3000,
        typeProducteur: ['Petit exploitant', 'Moyen exploitant', 'Grand exploitant'][i % 3],
        superficieExploitee: 1 + Math.random() * 10,
        uniteSuperficie: 'ha',
        systemeIrrigation: ['Gravitaire', 'Goutte-à-goutte', 'Aspersion', 'Aucun'][i % 4]
      }
    });
    users.push(user);
  }
  
  // Acheteurs (10)
  for (let i = 0; i < 10; i++) {
    const user = await prisma.user.create({
      data: {
        nom: noms[(i + 5) % noms.length],
        prenoms: `Acheteur ${i + 1}`,
        email: `acheteur${i + 1}@agrosmart.ci`,
        telephone: `+225080${String(i + 1).padStart(7, '0')}`,
        passwordHash: hashedPassword,
        role: 'ACHETEUR',
        status: 'ACTIF',
        regionId: regions[i % regions.length].id,
        emailVerifie: true,
        points: Math.floor(Math.random() * 200) + 20,
        niveau: 'Intermédiaire'
      }
    });
    users.push(user);
  }
  
  // Fournisseurs (5)
  for (let i = 0; i < 5; i++) {
    const user = await prisma.user.create({
      data: {
        nom: `Fournisseur ${i + 1}`,
        prenoms: 'Société',
        email: `fournisseur${i + 1}@agrosmart.ci`,
        telephone: `+225090${String(i + 1).padStart(7, '0')}`,
        passwordHash: hashedPassword,
        role: 'FOURNISSEUR',
        status: 'ACTIF',
        regionId: regions[i % regions.length].id,
        emailVerifie: true,
        points: Math.floor(Math.random() * 150) + 30,
        niveau: 'Professionnel'
      }
    });
    users.push(user);
  }
  
  console.log(`  ✅ ${users.length} utilisateurs créés\n`);
  return users;
}

async function seedCultures() {
  console.log('🌿 Création des cultures...');
  
  const cultures = [];
  for (const cultureData of CULTURES_DATA) {
    const culture = await prisma.culture.create({
      data: cultureData
    });
    cultures.push(culture);
  }
  
  console.log(`  ✅ ${cultures.length} cultures créées\n`);
  return cultures;
}

async function seedMaladies() {
  console.log('🦠 Création des maladies...');
  
  const maladies = [];
  for (const maladieData of MALADIES_DATA) {
    const maladie = await prisma.maladie.create({
      data: {
        ...maladieData,
        culturesAffectees: maladieData.culturesAffectees,
        traitements: maladieData.traitements,
        prevention: maladieData.prevention
      }
    });
    maladies.push(maladie);
  }
  
  console.log(`  ✅ ${maladies.length} maladies créées\n`);
  return maladies;
}

async function seedParcelles(users, regions, cultures) {
  console.log('🌾 Création des parcelles...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  const parcelles = [];
  
  const typesoldOptions = ['argileux', 'sablonneux', 'limoneux', 'latéritique', 'humifère'];
  const statutOptions = ['ACTIVE', 'EN_CROISSANCE', 'PREPAREE', 'ENSEMENCEE'];
  
  for (const producteur of producteurs) {
    // Chaque producteur a 2-4 parcelles
    const nbParcelles = 2 + Math.floor(Math.random() * 3);
    
    for (let i = 0; i < nbParcelles; i++) {
      const culture = cultures[Math.floor(Math.random() * cultures.length)];
      const parcelle = await prisma.parcelle.create({
        data: {
          userId: producteur.id,
          nom: `Parcelle ${culture.nom} ${i + 1}`,
          superficie: 0.5 + Math.random() * 5,
          typeSol: typesoldOptions[Math.floor(Math.random() * typesoldOptions.length)],
          latitude: 5 + Math.random() * 5, // Côte d'Ivoire entre 4°N et 10°N
          longitude: -8 + Math.random() * 3, // Entre -8°W et -2°W
          regionId: producteur.regionId,
          cultureActuelle: culture.nom,
          datePlantation: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
          statut: statutOptions[Math.floor(Math.random() * statutOptions.length)],
          sante: Math.random() > 0.2 ? 'OPTIMAL' : (Math.random() > 0.5 ? 'SURVEILLANCE' : 'CRITIQUE')
        }
      });
      parcelles.push(parcelle);
    }
  }
  
  console.log(`  ✅ ${parcelles.length} parcelles créées\n`);
  return parcelles;
}

async function seedStationsEtCapteurs(parcelles) {
  console.log('📡 Création des stations et capteurs...');
  
  let stationCount = 0;
  let capteurCount = 0;
  
  const capteurTypes = [
    { type: 'HUMIDITE_SOL', nom: 'Sonde Humidité Sol', unite: '%', min: 20, max: 80 },
    { type: 'HUMIDITE_TEMPERATURE_AMBIANTE', nom: 'Capteur Ambiant', unite: '°C/%', min: 15, max: 40 },
    { type: 'NPK', nom: 'Sonde NPK', unite: 'mg/kg', min: 10, max: 200 },
    { type: 'UV', nom: 'Capteur UV', unite: 'index', min: 0, max: 12 },
    { type: 'DIRECTION_VENT', nom: 'Anémomètre', unite: 'deg', min: 0, max: 360 },
    { type: 'TRANSPIRATION_PLANTE', nom: 'Capteur Flux', unite: 'mmol', min: 0, max: 10 }
  ];
  
  // 70% des parcelles ont une station
  for (const parcelle of parcelles) {
    if (Math.random() < 0.7) {
      const station = await prisma.station.create({
        data: {
          parcelleId: parcelle.id,
          nom: `Station IoT - ${parcelle.nom}`,
          code: `ST-${parcelle.id.substring(0, 8)}`,
          modele: ['Alpha-100', 'Beta-200', 'Gamma-300'][Math.floor(Math.random() * 3)],
          numeroSerie: `SN${Date.now()}${stationCount}`,
          statut: Math.random() > 0.1 ? 'ACTIVE' : 'MAINTENANCE',
          batterie: 50 + Math.floor(Math.random() * 50),
          signal: 60 + Math.floor(Math.random() * 40),
          latitude: parcelle.latitude,
          longitude: parcelle.longitude,
          derniereConnexion: new Date(Date.now() - Math.random() * 24 * 60 * 60 * 1000)
        }
      });
      stationCount++;
      
      // Chaque station a 3-6 capteurs
      const nbCapteurs = 3 + Math.floor(Math.random() * 4);
      const selectedTypes = capteurTypes
        .sort(() => 0.5 - Math.random())
        .slice(0, nbCapteurs);
      
      for (const capteurType of selectedTypes) {
        await prisma.capteur.create({
          data: {
            stationId: station.id,
            parcelleId: parcelle.id,
            nom: capteurType.nom,
            type: capteurType.type,
            unite: capteurType.unite,
            seuilMin: capteurType.min,
            seuilMax: capteurType.max,
            statut: Math.random() > 0.05 ? 'ACTIF' : (Math.random() > 0.5 ? 'MAINTENANCE' : 'INACTIF'),
            signal: 70 + Math.floor(Math.random() * 30),
            batterie: 60 + Math.floor(Math.random() * 40)
          }
        });
        capteurCount++;
      }
    }
  }
  
  console.log(`  ✅ ${stationCount} stations et ${capteurCount} capteurs créés\n`);
}

async function seedMesures() {
  console.log('📊 Création des mesures...');
  
  const capteurs = await prisma.capteur.findMany();
  let mesureCount = 0;
  
  // Générer des mesures pour les 14 derniers jours
  for (const capteur of capteurs) {
    for (let day = 0; day < 14; day++) {
      // 6 mesures par jour (toutes les 4h)
      for (let hour = 0; hour < 24; hour += 4) {
        const timestamp = new Date();
        timestamp.setDate(timestamp.getDate() - day);
        timestamp.setHours(hour, Math.floor(Math.random() * 60), 0, 0);
        
        let valeur;
        let unite = capteur.unite;
        
        // Générer des valeurs réalistes selon le type
        switch (capteur.type) {
          case 'HUMIDITE_SOL':
            valeur = 30 + Math.random() * 50 + Math.sin(day / 7 * Math.PI) * 10;
            break;
          case 'HUMIDITE_TEMPERATURE_AMBIANTE':
            if (Math.random() > 0.5) {
              valeur = 22 + Math.random() * 10 + Math.sin(hour / 24 * Math.PI) * 5;
              unite = '°C';
            } else {
              valeur = 50 + Math.random() * 40;
              unite = '%';
            }
            break;
          case 'NPK':
            valeur = 40 + Math.random() * 120;
            break;
          case 'UV':
            valeur = Math.max(0, Math.floor(hour / 2 - 2 + Math.random() * 4));
            break;
          case 'DIRECTION_VENT':
            valeur = Math.floor(Math.random() * 360);
            break;
          case 'TRANSPIRATION_PLANTE':
            valeur = 1 + Math.random() * 6;
            break;
          default:
            valeur = Math.random() * 100;
        }
        
        await prisma.mesure.create({
          data: {
            capteurId: capteur.id,
            valeur: valeur,
            unite: unite,
            timestamp: timestamp
          }
        });
        mesureCount++;
      }
    }
  }
  
  console.log(`  ✅ ${mesureCount} mesures créées\n`);
}

async function seedAlertes(users, capteurs) {
  console.log('🚨 Création des alertes...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let alerteCount = 0;
  
  const alertTypes = [
    { type: 'HUMIDITE_BASSE', niveau: 'IMPORTANT', titre: 'Humidité du sol faible' },
    { type: 'TEMPERATURE_HAUTE', niveau: 'CRITIQUE', titre: 'Température critique' },
    { type: 'NPK_BAS', niveau: 'INFO', titre: 'Niveau NPK à surveiller' },
    { type: 'UV_ELEVE', niveau: 'IMPORTANT', titre: 'UV élevé détecté' },
    { type: 'CAPTEUR_OFFLINE', niveau: 'CRITIQUE', titre: 'Capteur hors ligne' }
  ];
  
  for (const producteur of producteurs) {
    // 3-7 alertes par producteur
    const nbAlertes = 3 + Math.floor(Math.random() * 5);
    
    for (let i = 0; i < nbAlertes; i++) {
      const alertType = alertTypes[Math.floor(Math.random() * alertTypes.length)];
      const capteur = capteurs[Math.floor(Math.random() * capteurs.length)];
      
      await prisma.alerte.create({
        data: {
          userId: producteur.id,
          capteurId: Math.random() > 0.3 ? capteur.id : null,
          type: alertType.type,
          niveau: alertType.niveau,
          titre: alertType.titre,
          message: `Alerte automatique pour ${alertType.type}. Action recommandée.`,
          statut: Math.random() > 0.3 ? 'LUE' : 'NOUVELLE',
          donnees: {
            valeur: Math.random() * 100,
            seuil: 50,
            timestamp: new Date()
          },
          createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000)
        }
      });
      alerteCount++;
    }
  }
  
  console.log(`  ✅ ${alerteCount} alertes créées\n`);
}

async function seedDiagnostics(users, parcelles, maladies) {
  console.log('🩺 Création des diagnostics...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let diagnosticCount = 0;
  
  const severities = ['low', 'medium', 'high', 'critical'];
  const cropTypes = ['Cacao', 'Café Robusta', 'Tomate', 'Manioc', 'Maïs', 'Piment'];
  
  for (const producteur of producteurs) {
    // 2-5 diagnostics par producteur
    const nbDiagnostics = 2 + Math.floor(Math.random() * 4);
    
    for (let i = 0; i < nbDiagnostics; i++) {
      const maladie = maladies[Math.floor(Math.random() * maladies.length)];
      const parcelle = parcelles.find(p => p.userId === producteur.id);
      
      await prisma.diagnostic.create({
        data: {
          userId: producteur.id,
          parcelleId: parcelle?.id,
          type: 'disease',
          diseaseName: maladie.nom,
          cropType: cropTypes[Math.floor(Math.random() * cropTypes.length)],
          confidenceScore: 65 + Math.random() * 34,
          severity: severities[Math.floor(Math.random() * severities.length)],
          imageUrl: `https://storage.agrosmart.ci/diagnostics/img_${Date.now()}_${i}.jpg`,
          recommendations: `Basé sur l'analyse, il est recommandé de ${maladie.traitements[0]}`,
          treatmentSuggestions: maladie.traitements.join(', '),
          modeleUtilise: 'PlantDiseaseNet-v2.1',
          scoreConfiance: 70 + Math.random() * 29,
          createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000)
        }
      });
      diagnosticCount++;
    }
  }
  
  console.log(`  ✅ ${diagnosticCount} diagnostics créés\n`);
}

async function seedPlantationsEtRecoltes(parcelles, cultures) {
  console.log('🌱 Création des plantations et récoltes...');
  
  let plantationCount = 0;
  let recolteCount = 0;
  
  for (const parcelle of parcelles) {
    // 1-3 plantations par parcelle
    const nbPlantations = 1 + Math.floor(Math.random() * 3);
    
    for (let i = 0; i < nbPlantations; i++) {
      const culture = cultures.find(c => c.nom === parcelle.cultureActuelle) || cultures[0];
      const datePlantation = new Date(Date.now() - Math.random() * 730 * 24 * 60 * 60 * 1000); // Derniers 2 ans
      
      const plantation = await prisma.plantation.create({
        data: {
          parcelleId: parcelle.id,
          cultureId: culture.id,
          datePlantation: datePlantation,
          quantitePlantee: parcelle.superficie * (100 + Math.random() * 200),
          statut: Math.random() > 0.3 ? 'active' : 'terminee',
          dateFin: Math.random() > 0.5 ? new Date(datePlantation.getTime() + culture.dureeJours * 24 * 60 * 60 * 1000) : null,
          rendementParHectare: culture.rendementMoyen * (0.7 + Math.random() * 0.6)
        }
      });
      plantationCount++;
      
      // Ajouter des récoltes pour les plantations
      if (Math.random() > 0.4) {
        const nbRecoltes = 1 + Math.floor(Math.random() * 3);
        for (let j = 0; j < nbRecoltes; j++) {
          await prisma.recolte.create({
            data: {
              plantationId: plantation.id,
              dateRecolte: new Date(datePlantation.getTime() + (culture.dureeJours + j * 30) * 24 * 60 * 60 * 1000),
              quantiteKg: parcelle.superficie * culture.rendementMoyen * (0.8 + Math.random() * 0.4),
              rendementParHectare: culture.rendementMoyen * (0.8 + Math.random() * 0.4),
              qualite: ['excellente', 'bonne', 'moyenne', 'passable'][Math.floor(Math.random() * 4)],
              notes: Math.random() > 0.5 ? 'Récolte satisfaisante' : null
            }
          });
          recolteCount++;
        }
      }
    }
  }
  
  console.log(`  ✅ ${plantationCount} plantations et ${recolteCount} récoltes créées\n`);
}

async function seedMarketplaceProduits(users) {
  console.log('🛒 Création des produits marketplace...');
  
  const vendeurs = users.filter(u => u.role === 'PRODUCTEUR' || u.role === 'FOURNISSEUR');
  let produitCount = 0;
  
  for (const produitData of PRODUITS_MARKETPLACE) {
    const vendeur = vendeurs[Math.floor(Math.random() * vendeurs.length)];
    
    await prisma.marketplaceProduit.create({
      data: {
        vendeurId: vendeur.id,
        nom: produitData.nom,
        description: produitData.description,
        categorie: produitData.categorie,
        prix: produitData.prix,
        unite: produitData.unite,
        stock: produitData.stock,
        images: [],
        specifications: {
          origine: 'Côte d\'Ivoire',
          certification: Math.random() > 0.5 ? 'Bio' : 'Standard',
          disponibilite: 'Immédiate'
        },
        actif: true
      }
    });
    produitCount++;
  }
  
  console.log(`  ✅ ${produitCount} produits marketplace créés\n`);
}

async function seedCommandesEtTransactions(users) {
  console.log('💳 Création des commandes et transactions...');
  
  const acheteurs = users.filter(u => u.role === 'ACHETEUR' || u.role === 'PRODUCTEUR');
  const produits = await prisma.marketplaceProduit.findMany();
  
  let commandeCount = 0;
  let transactionCount = 0;
  
  for (const acheteur of acheteurs) {
    // 2-5 commandes par acheteur
    const nbCommandes = 2 + Math.floor(Math.random() * 4);
    
    for (let i = 0; i < nbCommandes; i++) {
      const produit = produits[Math.floor(Math.random() * produits.length)];
      const quantite = 1 + Math.floor(Math.random() * 10);
      const prixTotal = produit.prix * quantite;
      
      const statuts = ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
      const statut = statuts[Math.floor(Math.random() * statuts.length)];
      
      const commande = await prisma.marketplaceCommande.create({
        data: {
          acheteurId: acheteur.id,
          vendeurId: produit.vendeurId,
          produitId: produit.id,
          quantite: quantite,
          prixUnitaire: produit.prix,
          prixTotal: prixTotal,
          statut: statut,
          adresseLivraison: `${acheteur.adresse || 'Abidjan'}, Côte d'Ivoire`,
          modeLivraison: ['Standard', 'Express', 'Retrait'][Math.floor(Math.random() * 3)],
          createdAt: new Date(Date.now() - Math.random() * 60 * 24 * 60 * 60 * 1000)
        }
      });
      commandeCount++;
      
      // Créer une transaction si la commande n'est pas annulée
      if (statut !== 'CANCELLED') {
        await prisma.marketplaceTransaction.create({
          data: {
            commandeId: commande.id,
            montant: prixTotal,
            methodePaiement: ['Mobile Money', 'Orange Money', 'Wave', 'Carte bancaire'][Math.floor(Math.random() * 4)],
            statut: statut === 'DELIVERED' ? 'COMPLETED' : 'PENDING',
            referenceTransaction: `TRX-${Date.now()}-${transactionCount}`
          }
        });
        transactionCount++;
      }
    }
  }
  
  console.log(`  ✅ ${commandeCount} commandes et ${transactionCount} transactions créées\n`);
}

async function seedFormations() {
  console.log('📚 Création des formations...');
  
  let formationCount = 0;
  let moduleCount = 0;
  
  for (const formationData of FORMATIONS_DATA) {
    const formation = await prisma.formation.create({
      data: {
        titre: formationData.titre,
        description: formationData.description,
        categorie: formationData.categorie,
        niveau: formationData.niveau,
        dureeMinutes: formationData.dureeMinutes,
        imageUrl: `https://storage.agrosmart.ci/formations/img_${formationCount}.jpg`,
        vues: Math.floor(Math.random() * 500)
      }
    });
    formationCount++;
    
    // Créer les modules
    for (const moduleData of formationData.modules) {
      await prisma.moduleFormation.create({
        data: {
          formationId: formation.id,
          titre: moduleData.titre,
          contenu: moduleData.contenu,
          ordre: moduleData.ordre,
          videoUrl: `https://storage.agrosmart.ci/formations/videos/module_${moduleCount}.mp4`,
          quizData: {
            questions: [
              {
                question: 'Question exemple',
                options: ['A', 'B', 'C', 'D'],
                correct: 0
              }
            ]
          }
        }
      });
      moduleCount++;
    }
  }
  
  console.log(`  ✅ ${formationCount} formations et ${moduleCount} modules créés\n`);
}

async function seedProgressionsFormation(users) {
  console.log('📈 Création des progressions de formation...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  const formations = await prisma.formation.findMany();
  let progressionCount = 0;
  
  for (const producteur of producteurs) {
    // 1-4 formations par producteur
    const nbFormations = 1 + Math.floor(Math.random() * 4);
    const selectedFormations = formations
      .sort(() => 0.5 - Math.random())
      .slice(0, nbFormations);
    
    for (const formation of selectedFormations) {
      const progression = Math.floor(Math.random() * 100);
      const complete = progression === 100;
      
      await prisma.progressionFormation.create({
        data: {
          userId: producteur.id,
          formationId: formation.id,
          progression: progression,
          complete: complete,
          score: complete ? 70 + Math.floor(Math.random() * 30) : null,
          dateDebut: new Date(Date.now() - Math.random() * 60 * 24 * 60 * 60 * 1000),
          dateFin: complete ? new Date() : null
        }
      });
      progressionCount++;
    }
  }
  
  console.log(`  ✅ ${progressionCount} progressions de formation créées\n`);
}

async function seedForum(users) {
  console.log('💬 Création des posts et réponses forum...');
  
  let postCount = 0;
  let reponseCount = 0;
  
  const categories = ['culture', 'maladies', 'equipement', 'vente', 'irrigation', 'fertilisation'];
  const titres = [
    'Meilleur moment pour planter le cacao?',
    'Problème de jaunissement des feuilles',
    'Recommandation de système d\'irrigation',
    'Où vendre ma production de café?',
    'Dosage d\'engrais NPK pour le maïs',
    'Lutte contre les cochenilles du cacao',
    'Installation de capteurs IoT',
    'Prix actuel du cacao au kg'
  ];
  
  for (let i = 0; i < 20; i++) {
    const auteur = users[Math.floor(Math.random() * users.length)];
    const post = await prisma.forumPost.create({
      data: {
        auteurId: auteur.id,
        titre: titres[Math.floor(Math.random() * titres.length)],
        contenu: 'Bonjour à tous, j\'aimerais avoir vos conseils sur ce sujet. Merci d\'avance pour votre aide.',
        categorie: categories[Math.floor(Math.random() * categories.length)],
        vues: Math.floor(Math.random() * 200),
        resolu: Math.random() > 0.5,
        createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000)
      }
    });
    postCount++;
    
    // 2-6 réponses par post
    const nbReponses = 2 + Math.floor(Math.random() * 5);
    for (let j = 0; j < nbReponses; j++) {
      const repondant = users[Math.floor(Math.random() * users.length)];
      await prisma.forumReponse.create({
        data: {
          postId: post.id,
          auteurId: repondant.id,
          contenu: 'Voici mon conseil basé sur mon expérience...',
          estSolution: j === 0 && post.resolu,
          upvotes: Math.floor(Math.random() * 20)
        }
      });
      reponseCount++;
    }
  }
  
  console.log(`  ✅ ${postCount} posts et ${reponseCount} réponses créés\n`);
}

async function seedBadgesEtRealisations() {
  console.log('🏆 Création des badges et réalisations...');
  
  // Badges
  for (const badgeData of BADGES_DATA) {
    await prisma.badge.create({
      data: badgeData
    });
  }
  
  // Réalisations
  for (const realisationData of REALISATIONS_DATA) {
    await prisma.realisation.create({
     data: realisationData
    });
  }
  
  console.log(`  ✅ ${BADGES_DATA.length} badges et ${REALISATIONS_DATA.length} réalisations créés\n`);
}

async function seedUserBadges(users) {
  console.log('🎖️ Attribution des badges aux utilisateurs...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  const badges = await prisma.badge.findMany();
  let userBadgeCount = 0;
  
  for (const producteur of producteurs) {
    // Attribuer 1-4 badges par producteur
    const nbBadges = 1 + Math.floor(Math.random() * 4);
    const selectedBadges = badges
      .sort(() => 0.5 - Math.random())
      .slice(0, nbBadges);
    
    for (const badge of selectedBadges) {
      await prisma.userBadge.create({
        data: {
          userId: producteur.id,
          badgeId: badge.id,
          obtenuLe: new Date(Date.now() - Math.random() * 180 * 24 * 60 * 60 * 1000)
        }
      });
      userBadgeCount++;
    }
  }
  
  console.log(`  ✅ ${userBadgeCount} badges attribués aux utilisateurs\n`);
}

async function seedAchatsGroupes() {
  console.log('🤝 Création des achats groupés...');
  
  let achatGroupeCount = 0;
  
  for (const achatData of ACHATS_GROUPES_DATA) {
    await prisma.achatGroupe.create({
      data: {
        ...achatData,
        quantiteActuelle: Math.floor(Math.random() * achatData.quantiteObjectif * 0.7)
      }
    });
    achatGroupeCount++;
  }
  
  console.log(`  ✅ ${achatGroupeCount} achats groupés créés\n`);
}

async function seedStocks(users, parcelles) {
  console.log('📦 Création des stocks...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let stockCount = 0;
  let mouvementCount = 0;
  
  const categories = ['SEMENCES', 'ENGRAIS', 'PESTICIDES', 'HERBICIDES', 'OUTILS', 'RECOLTES'];
  const nomsProduits = {
    SEMENCES: ['Maïs hybride', 'Riz NERICA', 'Boutures manioc'],
    ENGRAIS: ['NPK 15-15-15', 'Urée 46%', 'Compost'],
    PESTICIDES: ['Lambda-cyhalothrine', 'Deltaméthrine'],
    HERBICIDES: ['Glyphosate', 'Paraquat'],
    OUTILS: ['Machettes', 'Houes', 'Pelles'],
    RECOLTES: ['Cacao séché', 'Café grain', 'Maïs grain']
  };
  
  for (const producteur of producteurs) {
    const userParcelles = parcelles.filter(p => p.userId === producteur.id);
    
    // 3-8 stocks par producteur
    const nbStocks = 3 + Math.floor(Math.random() * 6);
    
    for (let i = 0; i < nbStocks; i++) {
      const categorie = categories[Math.floor(Math.random() * categories.length)];
      const noms = nomsProduits[categorie];
      const nom = noms[Math.floor(Math.random() * noms.length)];
      
      const quantite = 10 + Math.random() * 500;
      const seuilAlerte = quantite * 0.2;
      
      const stock = await prisma.stock.create({
        data: {
          userId: producteur.id,
          parcelleId: userParcelles.length > 0 && Math.random() > 0.5 ? userParcelles[0].id : null,
          nom: nom,
          categorie: categorie,
          type: nom,
          quantite: quantite,
          unite: categorie === 'RECOLTES' ? 'kg' : (categorie === 'OUTILS' ? 'unité' : 'kg'),
          seuilAlerte: seuilAlerte,
          prixUnitaire: 500 + Math.random() * 5000,
          dateAchat: new Date(Date.now() - Math.random() * 180 * 24 * 60 * 60 * 1000),
          dateExpiration: categorie !== 'OUTILS' ? new Date(Date.now() + Math.random() * 365 * 24 * 60 * 60 * 1000) : null,
          fournisseur: `Fournisseur ${Math.floor(Math.random() * 5) + 1}`,
          localisation: `Magasin ${Math.floor(Math.random() * 3) + 1}`
        }
      });
      stockCount++;
      
      // 2-5 mouvements par stock
      const nbMouvements = 2 + Math.floor(Math.random() * 4);
      let quantiteActuelle = quantite;
      
      for (let j = 0; j < nbMouvements; j++) {
        const typeMouvement = ['ENTREE', 'SORTIE', 'AJUSTEMENT'][Math.floor(Math.random() * 3)];
        const quantiteMouvement = Math.random() * 50;
        const quantiteAvant = quantiteActuelle;
        
        if (typeMouvement === 'ENTREE') {
          quantiteActuelle += quantiteMouvement;
        } else {
          quantiteActuelle = Math.max(0, quantiteActuelle - quantiteMouvement);
        }
        
        await prisma.mouvementStock.create({
          data: {
            stockId: stock.id,
            typeMouvement: typeMouvement,
            quantite: quantiteMouvement,
            quantiteAvant: quantiteAvant,
            quantiteApres: quantiteActuelle,
            motif: typeMouvement === 'ENTREE' ? 'Achat' : 'Utilisation parcelle',
            reference: `REF-${Date.now()}-${j}`,
            createdAt: new Date(Date.now() - Math.random() * 90 * 24 * 60 * 60 * 1000)
          }
        });
        mouvementCount++;
      }
      
      // Créer une alerte si stock bas
      if (quantiteActuelle < seuilAlerte) {
        await prisma.alerteStock.create({
          data: {
            stockId: stock.id,
            typeAlerte: 'STOCK_BAS',
            message: `Le stock de ${nom} est en dessous du seuil d'alerte (${quantiteActuelle.toFixed(2)} ${stock.unite})`,
            estLue: Math.random() > 0.5
          }
        });
      }
    }
  }
  
  console.log(`  ✅ ${stockCount} stocks et ${mouvementCount} mouvements créés\n`);
}

async function seedCalendrierActivites(users, parcelles) {
  console.log('📅 Création des activités du calendrier...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let activiteCount = 0;
  
  const typesActivites = ['SEMIS', 'PLANTATION', 'ARROSAGE', 'FERTILISATION', 'TRAITEMENT', 'DESHERBAGE', 'RECOLTE'];
  const priorites = ['BASSE', 'MOYENNE', 'HAUTE', 'URGENTE'];
  
  for (const producteur of producteurs) {
    const userParcelles = parcelles.filter(p => p.userId === producteur.id);
    
    // 5-15 activités par producteur
    const nbActivites = 5 + Math.floor(Math.random() * 11);
    
    for (let i = 0; i < nbActivites; i++) {
      const typeActivite = typesActivites[Math.floor(Math.random() * typesActivites.length)];
      const dateDebut = new Date(Date.now() + (Math.random() - 0.5) * 60 * 24 * 60 * 60 * 1000);
      
      await prisma.calendrierActivite.create({
        data: {
          userId: producteur.id,
          parcelleId: userParcelles.length > 0 && Math.random() > 0.3 ? userParcelles[Math.floor(Math.random() * userParcelles.length)].id : null,
          titre: `${typeActivite} - ${Math.random() > 0.5 ? 'Cacao' : 'Maïs'}`,
          description: `Activité de ${typeActivite.toLowerCase()} planifiée`,
          typeActivite: typeActivite,
          statut: dateDebut < new Date() ? 'TERMINEE' : 'PLANIFIEE',
          priorite: priorites[Math.floor(Math.random() * priorites.length)],
          dateDebut: dateDebut,
          dateFin: new Date(dateDebut.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000),
          dateRappel: new Date(dateDebut.getTime() - 24 * 60 * 60 * 1000),
          estRecurrente: Math.random() > 0.7,
          frequenceJours: Math.random() > 0.7 ? 7 : null,
          coutEstime: Math.random() * 50000
        }
      });
      activiteCount++;
    }
  }
  
  console.log(`  ✅ ${activiteCount} activités de calendrier créées\n`);
}

async function seedEconomiesEtROI(users, parcelles) {
  console.log('💰 Création des économies et ROI...');
  
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let economieCount = 0;
  let roiCount = 0;
  
  for (const producteur of producteurs) {
    // 2-4 périodes d'économies par producteur
    const nbEconomies = 2 + Math.floor(Math.random() * 3);
    
    for (let i = 0; i < nbEconomies; i++) {
      const dateDebut = new Date(Date.now() - (i + 1) * 90 * 24 * 60 * 60 * 1000);
      const dateFin = new Date(dateDebut.getTime() + 90 * 24 * 60 * 60 * 1000);
      
      const eauEconomisee = Math.random() * 30;
      const engraisEconomise = Math.random() * 25;
      const pertesEvitees = Math.random() * 15;
      
      await prisma.economies.create({
        data: {
          userId: producteur.id,
          eauEconomiseePourcentage: eauEconomisee,
          engraisEconomisePourcentage: engraisEconomise,
          pertesEviteesPourcentage: pertesEvitees,
          valeurEauEconomiseeFcfa: eauEconomisee * 10000,
          valeurEngraisEconomiseFcfa: engraisEconomise * 15000,
          valeurPertesEviteesFcfa: pertesEvitees * 20000,
          economiesTotalesFcfa: (eauEconomisee * 10000) + (engraisEconomise * 15000) + (pertesEvitees * 20000),
          dateDebut: dateDebut,
          dateFin: dateFin
        }
      });
      economieCount++;
    }
    
    // 1-3 ROI tracking par producteur
    const userParcelles = parcelles.filter(p => p.userId === producteur.id);
    const nbROI = Math.min(userParcelles.length, 1 + Math.floor(Math.random() * 3));
    
    for (let i = 0; i < nbROI; i++) {
      const parcelle = userParcelles[i];
      const dateDebut = new Date(Date.now() - 180 * 24 * 60 * 60 * 1000);
      const dateFin = new Date();
      
      const coutTotal = 200000 + Math.random() * 500000;
      const quantiteRecoltee = parcelle.superficie * (1000 + Math.random() * 2000);
      const prixVente = 500 + Math.random() * 1500;
      const revenu = quantiteRecoltee * prixVente;
      const roi = ((revenu - coutTotal) / coutTotal) * 100;
      
      await prisma.roiTracking.create({
        data: {
          userId: producteur.id,
          parcelleId: parcelle.id,
          periodeDebut: dateDebut,
          periodeFin: dateFin,
          coutSemences: 30000 + Math.random() * 50000,
          coutEngrais: 50000 + Math.random() * 100000,
          coutPesticides: 20000 + Math.random() * 50000,
          coutIrrigation: 30000 + Math.random() * 70000,
          coutMainOeuvre: 70000 + Math.random() * 200000,
          autresCouts: 10000 + Math.random() * 30000,
          quantiteRecoltee: quantiteRecoltee,
          prixVenteUnitaire: prixVente,
          roiTrend: roi > 20 ? 'croissance' : (roi > 0 ? 'stable' : 'baisse')
        }
      });
      roiCount++;
    }
  }
  
  console.log(`  ✅ ${economieCount} économies et ${roiCount} ROI créés\n`);
}

async function seedCartsAndFavorites(users) {
  console.log('🛒 Création des paniers et favoris...');
  
  const acheteurs = users.filter(u => u.role === 'ACHETEUR' || u.role === 'PRODUCTEUR');
  const produits = await prisma.marketplaceProduit.findMany();
  
  let cartCount = 0;
  let favoriteCount = 0;
  
  for (const acheteur of acheteurs) {
    // Créer un panier avec 1-5 items
    if (Math.random() > 0.3) {
      const cart = await prisma.cart.create({
        data: {
          userId: acheteur.id
        }
      });
      cartCount++;
      
      const nbItems = 1 + Math.floor(Math.random() * 5);
      const selectedProduits = produits
        .sort(() => 0.5 - Math.random())
        .slice(0, nbItems);
      
      for (const produit of selectedProduits) {
        await prisma.cartItem.create({
          data: {
            cartId: cart.id,
            produitId: produit.id,
            quantite: 1 + Math.floor(Math.random() * 5)
          }
        });
      }
    }
    
    // Créer des favoris (2-8 produits)
    const nbFavoris = 2 + Math.floor(Math.random() * 7);
    const favoritesProduits = produits
      .sort(() => 0.5 - Math.random())
      .slice(0, nbFavoris);
    
    for (const produit of favoritesProduits) {
      await prisma.favorite.create({
        data: {
          userId: acheteur.id,
          produitId: produit.id
        }
      });
      favoriteCount++;
    }
  }
  
  console.log(`  ✅ ${cartCount} paniers et ${favoriteCount} favoris créés\n`);
}

async function seedNotifications(users) {
  console.log('🔔 Création des notifications...');
  
  let notificationCount = 0;
  
  const types = ['alerte', 'commande', 'formation', 'rappel', 'systeme'];
  const titres = {
    alerte: ['Alerte humidité', 'Capteur hors ligne', 'Température critique'],
    commande: ['Nouvelle commande', 'Commande livrée', 'Paiement reçu'],
    formation: ['Nouvelle formation disponible', 'Formation terminée', 'Certificat disponible'],
    rappel: ['Activité à venir', 'Récolte planifiée', 'Fertilisation recommandée'],
    systeme: ['Mise à jour disponible', 'Maintenance programmée', 'Nouveau badge obtenu']
  };
  
  for (const user of users) {
    // 3-10 notifications par utilisateur
    const nbNotifications = 3 + Math.floor(Math.random() * 8);
    
    for (let i = 0; i < nbNotifications; i++) {
      const type = types[Math.floor(Math.random() * types.length)];
      const titre = titres[type][Math.floor(Math.random() * titres[type].length)];
      
      await prisma.notification.create({
        data: {
          userId: user.id,
          titre: titre,
          message: `Message de notification ${type}. Plus de détails...`,
          type: type,
          lue: Math.random() > 0.4,
          metadata: {
            priority: ['low', 'medium', 'high'][Math.floor(Math.random() * 3)]
          },
          createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000)
        }
      });
      notificationCount++;
    }
  }
  
  console.log(`  ✅ ${notificationCount} notifications créées\n`);
}

async function main() {
  console.log('🌱 ==================================');
  console.log('🌱 SEED COMPLET - AGROSMART CI');
  console.log('🌱 ==================================\n');
  
  try {
    // Nettoyer la base de données
    await cleanDatabase();
    
    // Seed dans l'ordre des dépendances
    const regions = await seedRegions();
    const cooperatives = await seedCooperatives(regions);
    const users = await seedUsers(regions);
    const cultures = await seedCultures();
    const maladies = await seedMaladies();
    const parcelles = await seedParcelles(users, regions, cultures);
    
    await seedStationsEtCapteurs(parcelles);
    
    const capteurs = await prisma.capteur.findMany();
    await seedMesures();
    await seedAlertes(users, capteurs);
    
    await seedDiagnostics(users, parcelles, maladies);
    await seedPlantationsEtRecoltes(parcelles, cultures);
    
    await seedMarketplaceProduits(users);
    await seedCommandesEtTransactions(users);
    
    await seedFormations();
    await seedProgressionsFormation(users);
    
    await seedForum(users);
    
    await seedBadgesEtRealisations();
    await seedUserBadges(users);
    
    await seedAchatsGroupes();
    await seedStocks(users, parcelles);
    await seedCalendrierActivites(users, parcelles);
    await seedEconomiesEtROI(users, parcelles);
    
    await seedCartsAndFavorites(users);
    await seedNotifications(users);
    
    console.log('✨ ==================================');
    console.log('✨ SEED TERMINÉ AVEC SUCCÈS !');
    console.log('✨ ==================================\n');
    console.log('📋 Comptes de test:');
    console.log('   Admin:       +2250101010101 / password123');
    console.log('   Agronome:    +2250102020200 / password123');
    console.log('   Conseiller:  +2250103030300 / password123');
    console.log('   Producteur:  +2250700000001 / password123');
    console.log('   Acheteur:    +2250800000001 / password123');
    console.log('   Fournisseur: +2250900000001 / password123\n');
    
  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Exécution
main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });

module.exports = main;
