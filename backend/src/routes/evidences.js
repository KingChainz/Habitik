const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const feedResult = await db.query(
      `SELECT id, user_id AS "userId", family_id AS "familyId", autor, avatar, color, avatar_url AS "avatarUrl", accion, descripcion AS "desc", likes, created_at AS "tiempo", xp, emoji, imagen_url AS "imagen"
       FROM public.evidences
       WHERE family_id = $1
       ORDER BY created_at DESC`,
      [familyId]
    );
    res.json(feedResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener feed de evidencias' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const { familyId, userId, autor, avatar, color, avatarUrl, accion, desc, xp, emoji, imagen } = req.body;
  if (!familyId || !userId || !accion) {
    return res.status(400).json({ error: 'familyId, userId y accion requeridos' });
  }

  try {
    let resolvedAutor = autor;
    let resolvedAvatar = avatar;
    let resolvedColor = color;
    let resolvedAvatarUrl = avatarUrl;

    if (!resolvedAutor) {
      const profileRes = await db.query(
        'SELECT nombre, avatar_letra, avatar_color, avatar_url FROM public.profiles WHERE id = $1',
        [userId]
      );
      if (profileRes.rows.length > 0) {
        resolvedAutor = profileRes.rows[0].nombre;
        resolvedAvatar = profileRes.rows[0].avatar_letra;
        resolvedColor = profileRes.rows[0].avatar_color;
        resolvedAvatarUrl = profileRes.rows[0].avatar_url;
      }
    }

    const evidenceResult = await db.query(
      `INSERT INTO public.evidences (user_id, family_id, autor, avatar, color, avatar_url, accion, descripcion, likes, xp, emoji, imagen_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 0, $9, $10, $11)
       RETURNING id, user_id AS "userId", family_id AS "familyId", autor, avatar, color, avatar_url AS "avatarUrl", accion, descripcion AS "desc", likes, created_at AS "tiempo", xp, emoji, imagen_url AS "imagen"`,
      [
        userId,
        familyId,
        resolvedAutor || 'Usuario',
        resolvedAvatar || 'U',
        resolvedColor || '#2e7d32',
        resolvedAvatarUrl || null,
        accion,
        desc || '',
        xp || 0,
        emoji || '🌟',
        imagen || null,
      ]
    );
    res.status(201).json(evidenceResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al publicar evidencia' });
  }
});

router.post('/:id/like', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query(
      `UPDATE public.evidences
       SET likes = likes + 1
       WHERE id = $1
       RETURNING id, likes`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Evidencia no encontrada' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al dar like a la evidencia' });
  }
});

router.post('/:id/unlike', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query(
      `UPDATE public.evidences
       SET likes = GREATEST(0, likes - 1)
       WHERE id = $1
       RETURNING id, likes`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Evidencia no encontrada' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al quitar like a la evidencia' });
  }
});

module.exports = router;
