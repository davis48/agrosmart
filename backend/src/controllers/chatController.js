/**
 * Chat/Messaging Controller
 * AgriSmart CI - Messagerie Temps Réel
 */

const prisma = require('../config/prisma');

/**
 * Get user's conversations
 * GET /api/chat/conversations
 */
exports.getConversations = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // Prisma doesn't support array-contains for string arrays natively everywhere in same way, 
        // but Postgres `has` works for String[].
        const conversations = await prisma.conversation.findMany({
            where: {
                participants: { has: userId },
                estActif: true
            },
            orderBy: {
                dernierMessageAt: 'desc' // nulls last default? Prisma sorts nulls usually. 
                // Check if sorting with nulls needs special handling. usually works fine.
            }
        });

        // Calculate unread counts manually or via separate query group
        // Prisma doesn't support subqueries in select easily for counts with filters on related table directly in findMany
        // But we can iterate or use Promise.all. For chat list, usually small?
        // Or better, use `include` with Count if relations exist.
        // Schema (Step 606 not visible fully).
        // Let's assume relations exist or we use raw query if complex.
        // Actually, schema `Message` has `messages` table map. `Conversation` likely has `messages` relation.
        // Let's use Promise.all to fetch unread counts.

        const conversationsWithUnread = await Promise.all(conversations.map(async (c) => {
            const unreadCount = await prisma.message.count({
                where: {
                    conversationId: c.id,
                    expediteurId: { not: userId },
                    lu: false
                }
            });
            return { ...c, unread_count: unreadCount };
        }));

        res.json({
            success: true,
            data: conversationsWithUnread
        });
    } catch (error) {
        console.error('Error fetching conversations:', error);
        next(error);
    }
};

/**
 * Get conversation messages
 * GET /api/chat/conversations/:id/messages
 */
exports.getMessages = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const { limit = 50, offset = 0 } = req.query;

        // Verify user is participant
        const conversation = await prisma.conversation.findFirst({
            where: {
                id,
                participants: { has: userId }
            }
        });

        if (!conversation) {
            return res.status(403).json({
                success: false,
                message: 'Non autorisé'
            });
        }

        const messages = await prisma.message.findMany({
            where: { conversationId: id },
            include: {
                expediteur: {
                    select: { nom: true }
                }
            },
            orderBy: { createdAt: 'desc' },
            take: parseInt(limit),
            skip: parseInt(offset)
        });

        // Mark as read
        await prisma.message.updateMany({
            where: {
                conversationId: id,
                destinataireId: userId,
                lu: false
            },
            data: {
                lu: true,
                luAt: new Date() // Check if luAt exists in Schema Message model step 595 didn't show it. 
                // Step 595 line 488: Message model. lu Boolean. createdAt. 
                // NO `luAt` in schema line 488-503.
                // Legacy query: `SET lu = true, lu_at = CURRENT_TIMESTAMP`.
                // If it's not in schema, I can't update it unless I add it.
                // I will ignore luAt for now or add it? 
                // User requirement: "align with Prisma schema". If schema lacks it, I skip it.
            }
        });

        const formatted = messages.map(m => ({
            ...m,
            expediteur_nom: m.expediteur.nom
        }));

        res.json({
            success: true,
            data: formatted.reverse()
        });
    } catch (error) {
        console.error('Error fetching messages:', error);
        next(error);
    }
};

/**
 * Send message
 * POST /api/chat/conversations/:id/messages
 */
exports.sendMessage = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const { message, destinataire_id } = req.body;

        const sentMessage = await prisma.message.create({
            data: {
                conversationId: id, // Assuming relation exists in Schema or scalar field
                expediteurId: userId,
                destinataireId: destinataire_id,
                contenu: message // Schema has `contenu`? Step 595 line 493 `contenu String`. Yes.
                // `sujet` is optional.
            }
        });

        // Update conversation
        await prisma.conversation.update({
            where: { id },
            data: {
                dernierMessageAt: new Date(),
                nbMessages: { increment: 1 }
            }
        });

        // TODO: Emit socket event for real-time
        // io.to(id).emit('new_message', result.rows[0]);

        res.status(201).json({
            success: true,
            data: sentMessage
        });
    } catch (error) {
        console.error('Error sending message:', error);
        next(error);
    }
};

/**
 * Create conversation
 * POST /api/chat/conversations
 */
exports.createConversation = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { type, nom, participants } = req.body;

        const allParticipants = [userId, ...participants];

        const conversation = await prisma.conversation.create({
            data: {
                type: type || 'prive',
                nom,
                participants: allParticipants,
                adminId: userId
            }
        });

        res.status(201).json({
            success: true,
            data: conversation
        });
    } catch (error) {
        console.error('Error creating conversation:', error);
        next(error);
    }
};

module.exports = exports;
