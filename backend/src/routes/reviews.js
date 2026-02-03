const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middlewares/auth');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Get product reviews
router.get('/produits/:produitId/avis', async (req, res) => {
  try {
    const { produitId } = req.params;

    const reviews = await prisma.avis.findMany({
      where: { produit_id: produitId },
      include: {
        utilisateur: {
          select: {
            id: true,
            nom: true,
            prenom: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    const formattedReviews = reviews.map(review => ({
      id: review.id,
      produit_id: review.produit_id,
      utilisateur_id: review.utilisateur_id,
      utilisateur_nom: `${review.utilisateur.prenom} ${review.utilisateur.nom}`,
      note: review.note,
      commentaire: review.commentaire,
      images: review.images ? JSON.parse(review.images) : null,
      created_at: review.created_at,
    }));

    res.json({ data: formattedReviews });
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des avis' });
  }
});

// Get product review stats
router.get('/produits/:produitId/avis/stats', async (req, res) => {
  try {
    const { produitId } = req.params;

    const reviews = await prisma.avis.findMany({
      where: { produit_id: produitId },
      select: { note: true },
    });

    if (reviews.length === 0) {
      return res.json({
        data: {
          moyenne_note: 0,
          nombre_avis: 0,
          repartition_notes: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
        },
      });
    }

    const totalNotes = reviews.reduce((sum, r) => sum + r.note, 0);
    const moyenneNote = totalNotes / reviews.length;

    const repartitionNotes = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    reviews.forEach(r => {
      repartitionNotes[r.note]++;
    });

    res.json({
      data: {
        moyenne_note: moyenneNote,
        nombre_avis: reviews.length,
        repartition_notes: repartitionNotes,
      },
    });
  } catch (error) {
    console.error('Error fetching review stats:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// Create review
router.post('/avis', authenticateToken, async (req, res) => {
  try {
    const { produit_id, note, commentaire, images } = req.body;
    const utilisateurId = req.user.id;

    // Validate note
    if (!note || note < 1 || note > 5) {
      return res.status(400).json({ error: 'La note doit être entre 1 et 5' });
    }

    // Check if user already reviewed this product
    const existingReview = await prisma.avis.findFirst({
      where: {
        produit_id,
        utilisateur_id: utilisateurId,
      },
    });

    if (existingReview) {
      return res.status(409).json({ 
        error: 'Vous avez déjà donné un avis pour ce produit' 
      });
    }

    const review = await prisma.avis.create({
      data: {
        produit_id,
        utilisateur_id: utilisateurId,
        note,
        commentaire,
        images: images ? JSON.stringify(images) : null,
      },
      include: {
        utilisateur: {
          select: {
            id: true,
            nom: true,
            prenom: true,
          },
        },
      },
    });

    res.status(201).json({
      data: {
        id: review.id,
        produit_id: review.produit_id,
        utilisateur_id: review.utilisateur_id,
        utilisateur_nom: `${review.utilisateur.prenom} ${review.utilisateur.nom}`,
        note: review.note,
        commentaire: review.commentaire,
        images: review.images ? JSON.parse(review.images) : null,
        created_at: review.created_at,
      },
    });
  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({ error: 'Erreur lors de la création de l\'avis' });
  }
});

// Update review
router.put('/avis/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { note, commentaire } = req.body;
    const utilisateurId = req.user.id;

    // Validate note
    if (note && (note < 1 || note > 5)) {
      return res.status(400).json({ error: 'La note doit être entre 1 et 5' });
    }

    // Check if review exists and belongs to user
    const existingReview = await prisma.avis.findUnique({
      where: { id },
    });

    if (!existingReview) {
      return res.status(404).json({ error: 'Avis non trouvé' });
    }

    if (existingReview.utilisateur_id !== utilisateurId) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    const updatedReview = await prisma.avis.update({
      where: { id },
      data: {
        note: note || existingReview.note,
        commentaire: commentaire !== undefined ? commentaire : existingReview.commentaire,
      },
      include: {
        utilisateur: {
          select: {
            id: true,
            nom: true,
            prenom: true,
          },
        },
      },
    });

    res.json({
      data: {
        id: updatedReview.id,
        produit_id: updatedReview.produit_id,
        utilisateur_id: updatedReview.utilisateur_id,
        utilisateur_nom: `${updatedReview.utilisateur.prenom} ${updatedReview.utilisateur.nom}`,
        note: updatedReview.note,
        commentaire: updatedReview.commentaire,
        images: updatedReview.images ? JSON.parse(updatedReview.images) : null,
        created_at: updatedReview.created_at,
      },
    });
  } catch (error) {
    console.error('Error updating review:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour de l\'avis' });
  }
});

// Delete review
router.delete('/avis/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const utilisateurId = req.user.id;

    // Check if review exists and belongs to user
    const existingReview = await prisma.avis.findUnique({
      where: { id },
    });

    if (!existingReview) {
      return res.status(404).json({ error: 'Avis non trouvé' });
    }

    if (existingReview.utilisateur_id !== utilisateurId) {
      return res.status(403).json({ error: 'Non autorisé' });
    }

    await prisma.avis.delete({
      where: { id },
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting review:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'avis' });
  }
});

module.exports = router;
