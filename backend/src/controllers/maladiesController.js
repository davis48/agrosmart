/**
 * Contrôleur des maladies et détection IA
 * AgriSmart CI - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const logger = require('../utils/logger');
const sharp = require('sharp');
const path = require('path');
const fsPromises = require('fs').promises;
const fs = require('fs');
const config = require('../config');
const axios = require('axios');
const FormData = require('form-data');

/* ========== CATALOGUE DES MALADIES ========== */

exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const { type } = req.query;

    const where = {};
    if (type) where.type = type;

    const maladies = await prisma.maladie.findMany({
      where,
      orderBy: { nom: 'asc' },
      take: limit,
      skip: offset
    });

    res.json({
      success: true,
      data: maladies
    });
  } catch (error) {
    next(error);
  }
};

exports.search = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.json({ success: true, data: [] });
    }

    const maladies = await prisma.maladie.findMany({
      where: {
        OR: [
          { nom: { contains: q, mode: 'insensitive' } },
          { nomScientifique: { contains: q, mode: 'insensitive' } },
          { symptomes: { contains: q, mode: 'insensitive' } },
        ]
      },
      orderBy: { nom: 'asc' },
      take: 20
    });

    res.json({
      success: true,
      data: maladies
    });
  } catch (error) {
    next(error);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { nom, nom_scientifique, type, description, symptomes,
      traitements, prevention, cultures_affectees } = req.body;

    const maladie = await prisma.maladie.create({
      data: {
        nom,
        nomScientifique: nom_scientifique,
        type,
        description,
        symptomes,
        traitements,
        prevention,
        culturesAffectees: cultures_affectees || []
      }
    });

    logger.audit('Création maladie', { userId: req.user.id, maladieId: maladie.id });

    res.status(201).json({
      success: true,
      message: 'Maladie ajoutée au catalogue',
      data: maladie
    });
  } catch (error) {
    next(error);
  }
};

exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const maladie = await prisma.maladie.findUnique({
      where: { id }
    });

    if (!maladie) {
      throw errors.notFound('Maladie non trouvée');
    }

    res.json({
      success: true,
      data: maladie
    });
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Whitelist specific fields for update
    const allowed = ['nom', 'nom_scientifique', 'type', 'description',
      'symptomes', 'traitements', 'prevention', 'cultures_affectees'];

    const data = {};
    for (const field of allowed) {
      if (req.body[field] !== undefined) {
        if (field === 'nom_scientifique') data.nomScientifique = req.body[field];
        else if (field === 'cultures_affectees') data.culturesAffectees = req.body[field];
        else data[field] = req.body[field];
      }
    }

    if (Object.keys(data).length === 0) {
      throw errors.badRequest('Aucune donnée à mettre à jour');
    }

    const updated = await prisma.maladie.update({
      where: { id },
      data
    });

    res.json({
      success: true,
      message: 'Maladie mise à jour',
      data: updated
    });
  } catch (error) {
    if (error.code === 'P2025') {
      throw errors.notFound('Maladie non trouvée');
    }
    next(error);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.maladie.delete({
      where: { id }
    });

    logger.audit('Suppression maladie', { userId: req.user.id, maladieId: id });

    res.json({
      success: true,
      message: 'Maladie supprimée'
    });
  } catch (error) {
    if (error.code === 'P2025') {
      throw errors.notFound('Maladie non trouvée');
    }
    next(error);
  }
};

/* ========== DÉTECTION IA ========== */

exports.detectFromImage = async (req, res, next) => {
  try {
    if (!req.file) {
      throw errors.badRequest('Image requise');
    }

    const { parcelle_id, culture_id, description } = req.body;

    // Traiter l'image avec Sharp
    const processedImage = await sharp(req.file.buffer)
      .resize(640, 640, { fit: 'inside' })
      .jpeg({ quality: 85 })
      .toBuffer();

    // Générer un nom de fichier unique
    const filename = `detection_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.jpg`;
    const uploadPath = path.join(config.upload.path, 'detections', filename);

    // Créer le dossier si nécessaire
    await fsPromises.mkdir(path.dirname(uploadPath), { recursive: true });
    await fsPromises.writeFile(uploadPath, processedImage);

    const imageUrl = `/uploads/detections/${filename}`;

    // Appel au microservice IA Python
    const formData = new FormData();
    formData.append('image', fs.createReadStream(uploadPath));

    let detectionResult;
    try {
      const aiResponse = await axios.post('http://localhost:5000/predict/disease', formData, {
        headers: {
          ...formData.getHeaders()
        }
      });

      const { disease, confidence, recommendation } = aiResponse.data;

      // Trouver l'ID de la maladie correspondante
      const maladie = await prisma.maladie.findUnique({
        where: { nom: disease }
      });
      const maladieId = maladie ? maladie.id : null;

      detectionResult = {
        maladie_id: maladieId,
        confiance: confidence,
        raw: aiResponse.data
      };
    } catch (aiError) {
      logger.error('Erreur service IA', { error: aiError.message });
      detectionResult = {
        maladie_id: null,
        confiance: 0,
        raw: { error: 'Service IA indisponible' }
      };
    }

    // Enregistrer la détection
    const detection = await prisma.detectionMaladie.create({
      data: {
        userId: req.user.id,
        parcelleId: parcelle_id,
        cultureId: culture_id,
        imageUrl,
        maladieDetecteeId: detectionResult.maladie_id,
        confiance: detectionResult.confiance,
        description,
        resultatsBruts: detectionResult.raw
      }
    });

    let maladie = null;
    if (detectionResult.maladie_id) {
      maladie = await prisma.maladie.findUnique({ where: { id: detectionResult.maladie_id } });
    }

    logger.audit('Détection maladie', { userId: req.user.id, detectionId: detection.id });

    res.status(201).json({
      success: true,
      data: {
        detection,
        maladie,
        recommendations: maladie ? generateRecommendations(maladie) : null
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.detectFromImageBatch = async (req, res, next) => {
  try {
    if (!req.files || req.files.length === 0) {
      throw errors.badRequest('Au moins une image requise');
    }

    const results = [];

    for (const file of req.files) {
      const processedImage = await sharp(file.buffer)
        .resize(640, 640, { fit: 'inside' })
        .jpeg({ quality: 85 })
        .toBuffer();

      const detectionResult = await simulateAIDetection(processedImage);
      results.push({
        filename: file.originalname,
        ...detectionResult
      });
    }

    res.json({
      success: true,
      data: results
    });
  } catch (error) {
    next(error);
  }
};

/* ========== HISTORIQUE DES DÉTECTIONS ========== */

exports.getDetections = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const detections = await prisma.detectionMaladie.findMany({
      where: { userId: req.user.id },
      include: {
        maladieDetectee: { select: { nom: true } },
        parcelle: { select: { nom: true } },
        culture: { select: { nom: true } }
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset
    });

    const formatted = detections.map(d => ({
      ...d,
      maladie_nom: d.maladieDetectee?.nom,
      parcelle_nom: d.parcelle?.nom,
      culture_nom: d.culture?.nom
    }));

    res.json({
      success: true,
      data: formatted
    });
  } catch (error) {
    next(error);
  }
};

exports.getDetectionById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const detection = await prisma.detectionMaladie.findUnique({
      where: { id },
      include: {
        maladieDetectee: true,
        parcelle: { select: { nom: true } },
        culture: { select: { nom: true } }
      }
    });

    if (!detection) {
      throw errors.notFound('Détection non trouvée');
    }

    const formatted = {
      ...detection,
      ...detection.maladieDetectee,
      maladie_nom: detection.maladieDetectee?.nom,
      parcelle_nom: detection.parcelle?.nom,
      culture_nom: detection.culture?.nom
    };

    res.json({
      success: true,
      data: formatted
    });
  } catch (error) {
    next(error);
  }
};

exports.confirmDetection = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { confirmed, maladie_corrigee_id, notes } = req.body;

    const result = await prisma.detectionMaladie.update({
      where: { id },
      data: {
        confirme: confirmed,
        maladieCorrigeeId: maladie_corrigee_id,
        notesCorrection: notes,
        dateConfirmation: new Date()
      }
    });

    res.json({
      success: true,
      message: 'Détection mise à jour',
      data: result
    });
  } catch (error) {
    if (error.code === 'P2025') {
      throw errors.notFound('Détection non trouvée');
    }
    next(error);
  }
};

exports.getStats = async (req, res, next) => {
  try {
    const totalDetections = await prisma.detectionMaladie.count();
    const hauteConfiance = await prisma.detectionMaladie.count({ where: { confiance: { gt: 0.8 } } });
    const confirmees = await prisma.detectionMaladie.count({ where: { confirme: true } });
    const maladiesDetectees = await prisma.detectionMaladie.count({ where: { maladieDetecteeId: { not: null } } });
    const dernierMois = await prisma.detectionMaladie.count({
      where: { createdAt: { gt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } }
    });

    const parMaladie = await prisma.detectionMaladie.groupBy({
      by: ['maladieDetecteeId'],
      where: {
        createdAt: { gt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
        maladieDetecteeId: { not: null }
      },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 10
    });

    const parMaladieDetails = await Promise.all(parMaladie.map(async (item) => {
      const m = await prisma.maladie.findUnique({ where: { id: item.maladieDetecteeId } });
      return { nom: m?.nom, count: item._count.id };
    }));

    res.json({
      success: true,
      data: {
        total_detections: totalDetections,
        haute_confiance: hauteConfiance,
        confirmees: confirmees,
        maladies_detectees: maladiesDetectees,
        dernier_mois: dernierMois,
        par_maladie: parMaladieDetails
      }
    });
  } catch (error) {
    next(error);
  }
};

/* ========== HELPERS ========== */

async function simulateAIDetection(imageBuffer) {
  const count = await prisma.maladie.count();

  if (count === 0) {
    return {
      maladie_id: null,
      confiance: 0,
      raw: { message: 'Aucune maladie dans la base de données' }
    };
  }

  if (Math.random() > 0.3) {
    const skip = Math.floor(Math.random() * count);
    const randomMaladie = (await prisma.maladie.findMany({ take: 1, skip }))[0];

    return {
      maladie_id: randomMaladie.id,
      confiance: 0.7 + Math.random() * 0.25,
      raw: {
        model: 'simulation_v1',
        predictions: [
          { maladie: randomMaladie.nom, confiance: 0.7 + Math.random() * 0.25 }
        ]
      }
    };
  }

  return {
    maladie_id: null,
    confiance: 0,
    raw: { model: 'simulation_v1', message: 'Plante saine' }
  };
}

function generateRecommendations(maladie) {
  const recommendations = [];

  if (maladie.traitements) {
    recommendations.push({
      type: 'traitement',
      priorite: 'haute',
      contenu: maladie.traitements
    });
  }

  if (maladie.prevention) {
    recommendations.push({
      type: 'prevention',
      priorite: 'moyenne',
      contenu: maladie.prevention
    });
  }

  recommendations.push({
    type: 'general',
    priorite: 'basse',
    contenu: 'Surveillez régulièrement vos cultures et isolez les plants affectés si possible.'
  });

  return recommendations;
}
