const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

router.get('/today', authMiddleware, async (req, res) => {
  const userId = req.query.userId || req.user.userId;
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  try {
    const result = await db.query(
      `SELECT reto, estado
       FROM public.reto_validations
       WHERE user_id = $1 AND created_at >= $2 AND estado != 'rechazado'`,
      [userId, todayStart]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener retos del usuario' });
  }
});

router.get('/', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const validationsResult = await db.query(
      `SELECT id, user_id AS "userId", usuario, avatar, color, reto, hora, xp, monedas, evidencias, requiere_evidencia AS "requiereEvidencia", estado
       FROM public.reto_validations
       WHERE family_id = $1 AND estado = 'pendiente'
       ORDER BY created_at DESC`,
      [familyId]
    );
    res.json(validationsResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener validaciones pendientes' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const { familyId, userId, usuario, avatar, color, reto, hora, xp, monedas, evidencias, requiereEvidencia } = req.body;
  if (!familyId || !userId || !reto) {
    return res.status(400).json({ error: 'familyId, userId y reto requeridos' });
  }

  try {
    let resolvedUsuario = usuario;
    let resolvedAvatar = avatar;
    let resolvedColor = color;

    if (!resolvedUsuario) {
      const profileRes = await db.query(
        'SELECT nombre, avatar_letra, avatar_color FROM public.profiles WHERE id = $1',
        [userId]
      );
      if (profileRes.rows.length > 0) {
        resolvedUsuario = profileRes.rows[0].nombre;
        resolvedAvatar = profileRes.rows[0].avatar_letra;
        resolvedColor = profileRes.rows[0].avatar_color;
      }
    }

    const validationResult = await db.query(
      `INSERT INTO public.reto_validations (family_id, user_id, usuario, avatar, color, reto, hora, xp, monedas, evidencias, requiere_evidencia, estado)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pendiente')
       RETURNING id, user_id AS "userId", usuario, avatar, color, reto, hora, xp, monedas, evidencias, requiere_evidencia AS "requiereEvidencia", estado`,
      [
        familyId,
        userId,
        resolvedUsuario || 'Usuario',
        resolvedAvatar || 'U',
        resolvedColor || '#2e7d32',
        reto,
        hora || 'Recién',
        xp || 0,
        monedas || 0,
        evidencias || [],
        requiereEvidencia || false,
      ]
    );
    res.status(201).json(validationResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al enviar validación' });
  }
});

router.post('/:id/approve', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    const validationResult = await client.query('SELECT * FROM public.reto_validations WHERE id = $1', [id]);
    if (validationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Validación no encontrada' });
    }

    const val = validationResult.rows[0];
    if (val.estado !== 'pendiente') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'La validación ya fue procesada' });
    }

    const coinsToAdd = val.monedas > 0 ? val.monedas : 0;
    let leveledUp = false;

    const profileRes = await client.query('SELECT xp, nivel, monedas FROM public.profiles WHERE id = $1', [val.user_id]);
    if (profileRes.rows.length > 0) {
      let currentXp = profileRes.rows[0].xp || 0;
      let currentNivel = profileRes.rows[0].nivel || 1;
      let currentMonedas = profileRes.rows[0].monedas || 0;

      currentXp += val.xp;
      currentMonedas += coinsToAdd;

      const xpNeeded = currentNivel * 500;
      if (currentXp >= xpNeeded) {
        currentNivel++;
        currentXp -= xpNeeded;
        leveledUp = true;
      }

      await client.query(
        'UPDATE public.profiles SET xp = $1, nivel = $2, monedas = $3 WHERE id = $4',
        [currentXp, currentNivel, currentMonedas, val.user_id]
      );
    }

    const updatedValResult = await client.query(
      "UPDATE public.reto_validations SET estado = 'aprobado' WHERE id = $1 RETURNING *",
      [id]
    );

    await client.query(
      `INSERT INTO public.notifications (user_id, title, desc_text, icon_code, color_hex, is_read)
       VALUES ($1, $2, $3, $4, $5, false)`,
      [
        val.user_id,
        'Reto Aprobado 🌟',
        `Tu reto "${val.reto}" fue aprobado. Ganaste +${val.xp} XP y +${coinsToAdd} monedas.`,
        'check_circle',
        '#2e7d32',
      ]
    );

    await client.query('COMMIT');
    res.json({ success: true, validation: updatedValResult.rows[0], leveledUp });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Error al aprobar la validación' });
  } finally {
    client.release();
  }
});

router.post('/:id/reject', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    const validationResult = await client.query('SELECT * FROM public.reto_validations WHERE id = $1', [id]);
    if (validationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Validación no encontrada' });
    }

    const val = validationResult.rows[0];
    if (val.estado !== 'pendiente') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'La validación ya fue procesada' });
    }

    if (val.monedas < 0) {
      await client.query(
        'UPDATE public.profiles SET monedas = monedas + $1 WHERE id = $2',
        [Math.abs(val.monedas), val.user_id]
      );
    }

    const result = await client.query(
      "UPDATE public.reto_validations SET estado = 'rechazado' WHERE id = $1 RETURNING *",
      [id]
    );

    await client.query(
      `INSERT INTO public.notifications (user_id, title, desc_text, icon_code, color_hex, is_read)
       VALUES ($1, $2, $3, $4, $5, false)`,
      [
        val.user_id,
        val.monedas < 0 ? 'Canje Rechazado ❌' : 'Reto Rechazado ❌',
        val.monedas < 0
          ? `Tu canje de "${val.reto.replace('Canjear: ', '')}" fue rechazado. Se devolvieron tus monedas.`
          : `Tu reto "${val.reto}" no cumple con los requisitos de evidencia solicitados.`,
        'cancel',
        '#d32f2f',
      ]
    );

    await client.query('COMMIT');
    res.json({ success: true, validation: result.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Error al rechazar la validación' });
  } finally {
    client.release();
  }
});

module.exports = router;
