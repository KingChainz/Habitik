const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/', authMiddleware, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, user_id AS "user_id", title, desc_text AS "desc_text", icon_code AS "icon_code", color_hex AS "color_hex", is_read AS "is_read", created_at AS "created_at"
       FROM public.notifications
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener notificaciones' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const { userId, title, desc, iconCode, colorHex } = req.body;
  if (!userId || !title || !desc) {
    return res.status(400).json({ error: 'userId, title y desc requeridos' });
  }

  try {
    const result = await db.query(
      `INSERT INTO public.notifications (user_id, title, desc_text, icon_code, color_hex, is_read)
       VALUES ($1, $2, $3, $4, $5, false)
       RETURNING id, user_id AS "user_id", title, desc_text AS "desc_text", icon_code AS "icon_code", color_hex AS "color_hex", is_read AS "is_read", created_at AS "created_at"`,
      [userId, title, desc, iconCode || 'notifications', colorHex || '#388E3C']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear la notificación' });
  }
});

router.put('/:id/read', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query(
      `UPDATE public.notifications
       SET is_read = true
       WHERE id = $1 AND user_id = $2
       RETURNING id, is_read`,
      [id, req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notificación no encontrada' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al marcar notificación como leída' });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query(
      'DELETE FROM public.notifications WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Notificación no encontrada' });
    }

    res.json({ success: true, id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al eliminar la notificación' });
  }
});

module.exports = router;
