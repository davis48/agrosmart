const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middlewares/auth');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Get user's wishlist
router.get('/wishlist', authenticateToken, async (req, res) => {
  try {
    const utilisateurId = req.user.id;

    const wishlist = await prisma.wishlist.findFirst({
      where: { utilisateur_id: utilisateurId },
      include: {
        items: {
          include: {
            produit: {
              select: {
                id: true,
                nom: true,
                prix: true,
                image_url: true,
                quantite_stock: true,
              },
            },
          },
          orderBy: { added_at: 'desc' },
        },
      },
    });

    if (!wishlist) {
      // Create empty wishlist
      const newWishlist = await prisma.wishlist.create({
        data: {
          utilisateur_id: utilisateurId,
        },
      });

      return res.json({
        data: {
          id: newWishlist.id,
          utilisateur_id: newWishlist.utilisateur_id,
          items: [],
          created_at: newWishlist.created_at,
          updated_at: newWishlist.updated_at,
        },
      });
    }

    const formattedItems = wishlist.items.map(item => ({
      id: item.id,
      produit_id: item.produit_id,
      nom: item.produit.nom,
      prix: item.produit.prix,
      image_url: item.produit.image_url,
      disponible: item.produit.quantite_stock > 0,
      added_at: item.added_at,
    }));

    res.json({
      data: {
        id: wishlist.id,
        utilisateur_id: wishlist.utilisateur_id,
        items: formattedItems,
        created_at: wishlist.created_at,
        updated_at: wishlist.updated_at,
      },
    });
  } catch (error) {
    console.error('Error fetching wishlist:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de la wishlist' });
  }
});

// Add product to wishlist
router.post('/wishlist', authenticateToken, async (req, res) => {
  try {
    const { produit_id } = req.body;
    const utilisateurId = req.user.id;

    if (!produit_id) {
      return res.status(400).json({ error: 'produit_id est requis' });
    }

    // Check if product exists
    const product = await prisma.produit.findUnique({
      where: { id: produit_id },
    });

    if (!product) {
      return res.status(404).json({ error: 'Produit non trouvé' });
    }

    // Get or create wishlist
    let wishlist = await prisma.wishlist.findFirst({
      where: { utilisateur_id: utilisateurId },
    });

    if (!wishlist) {
      wishlist = await prisma.wishlist.create({
        data: { utilisateur_id: utilisateurId },
      });
    }

    // Check if item already in wishlist
    const existingItem = await prisma.wishlistItem.findFirst({
      where: {
        wishlist_id: wishlist.id,
        produit_id,
      },
    });

    if (existingItem) {
      return res.status(409).json({ 
        error: 'Ce produit est déjà dans vos favoris' 
      });
    }

    // Add item to wishlist
    const item = await prisma.wishlistItem.create({
      data: {
        wishlist_id: wishlist.id,
        produit_id,
      },
    });

    // Update wishlist timestamp
    await prisma.wishlist.update({
      where: { id: wishlist.id },
      data: { updated_at: new Date() },
    });

    res.status(201).json({
      data: {
        id: item.id,
        produit_id: item.produit_id,
        nom: product.nom,
        prix: product.prix,
        image_url: product.image_url,
        disponible: product.quantite_stock > 0,
        added_at: item.added_at,
      },
    });
  } catch (error) {
    console.error('Error adding to wishlist:', error);
    res.status(500).json({ error: 'Erreur lors de l\'ajout à la wishlist' });
  }
});

// Remove product from wishlist
router.delete('/wishlist/:produitId', authenticateToken, async (req, res) => {
  try {
    const { produitId } = req.params;
    const utilisateurId = req.user.id;

    const wishlist = await prisma.wishlist.findFirst({
      where: { utilisateur_id: utilisateurId },
    });

    if (!wishlist) {
      return res.status(404).json({ error: 'Wishlist non trouvée' });
    }

    const item = await prisma.wishlistItem.findFirst({
      where: {
        wishlist_id: wishlist.id,
        produit_id: produitId,
      },
    });

    if (!item) {
      return res.status(404).json({ error: 'Produit non trouvé dans la wishlist' });
    }

    await prisma.wishlistItem.delete({
      where: { id: item.id },
    });

    // Update wishlist timestamp
    await prisma.wishlist.update({
      where: { id: wishlist.id },
      data: { updated_at: new Date() },
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error removing from wishlist:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression de la wishlist' });
  }
});

// Clear wishlist
router.delete('/wishlist', authenticateToken, async (req, res) => {
  try {
    const utilisateurId = req.user.id;

    const wishlist = await prisma.wishlist.findFirst({
      where: { utilisateur_id: utilisateurId },
    });

    if (!wishlist) {
      return res.status(404).json({ error: 'Wishlist non trouvée' });
    }

    await prisma.wishlistItem.deleteMany({
      where: { wishlist_id: wishlist.id },
    });

    // Update wishlist timestamp
    await prisma.wishlist.update({
      where: { id: wishlist.id },
      data: { updated_at: new Date() },
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error clearing wishlist:', error);
    res.status(500).json({ error: 'Erreur lors du vidage de la wishlist' });
  }
});

// Check if product is in wishlist
router.get('/wishlist/check/:produitId', authenticateToken, async (req, res) => {
  try {
    const { produitId } = req.params;
    const utilisateurId = req.user.id;

    const wishlist = await prisma.wishlist.findFirst({
      where: { utilisateur_id: utilisateurId },
    });

    if (!wishlist) {
      return res.json({ inWishlist: false });
    }

    const item = await prisma.wishlistItem.findFirst({
      where: {
        wishlist_id: wishlist.id,
        produit_id: produitId,
      },
    });

    res.json({ inWishlist: !!item });
  } catch (error) {
    console.error('Error checking wishlist:', error);
    res.status(500).json({ error: 'Erreur lors de la vérification' });
  }
});

module.exports = router;
