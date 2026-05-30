const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

// Get unlocked achievements for user
router.get('/', authMiddleware, async (req, res) => {
  const { userId } = req.query;
  const targetUserId = userId || req.user.userId;

  try {
    const result = await db.query(
      `SELECT logro_key, desbloqueado_en AS "desbloqueado_en"
       FROM public.achievements
       WHERE user_id = $1`,
      [targetUserId]
    );

    const mapped = result.rows.map(row => ({
      logro_key: row.logro_key,
      desbloqueado: true,
      desbloqueado_en: row.desbloqueado_en
    }));
    
    res.json(mapped);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener logros desbloqueados' });
  }
});

// Unlock an achievement (simply records the unlock; client handles rewarding)
router.post('/unlock', authMiddleware, async (req, res) => {
  const { key } = req.body;
  if (!key) {
    return res.status(400).json({ error: 'Falta la clave del logro (key)' });
  }

  try {
    const checkResult = await db.query(
      'SELECT id FROM public.achievements WHERE user_id = $1 AND logro_key = $2',
      [req.user.userId, key]
    );

    if (checkResult.rows.length > 0) {
      return res.status(400).json({ error: 'Logro ya desbloqueado previamente' });
    }

    const unlockResult = await db.query(
      'INSERT INTO public.achievements (user_id, logro_key) VALUES ($1, $2) RETURNING logro_key, desbloqueado_en',
      [req.user.userId, key]
    );

    res.status(201).json({
      success: true,
      achievement: {
        logro_key: unlockResult.rows[0].logro_key,
        desbloqueado: true,
        desbloqueado_en: unlockResult.rows[0].desbloqueado_en
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al registrar el logro' });
  }
});

module.exports = router;
