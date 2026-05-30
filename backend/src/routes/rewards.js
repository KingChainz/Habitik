const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

// Get all rewards for a family
router.get('/', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const rewardsResult = await db.query(
      `SELECT id, family_id AS "familyId", titulo, costo, descripcion, emoji, disponible, creador_id AS "creador", last_redeemed_at AS "lastRedeemedAt"
       FROM public.family_rewards
       WHERE family_id = $1
       ORDER BY created_at DESC`,
      [familyId]
    );
    res.json(rewardsResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener lista de premios' });
  }
});

router.post('/', authMiddleware, async (req, res) => {
  const { id, familyId, titulo, costo, descripcion, emoji, disponible, creador } = req.body;
  if (!id || !familyId || !titulo || !costo) {
    return res.status(400).json({ error: 'Faltan campos obligatorios para crear premio' });
  }

  try {
    const isUUID = (str) => {
      if (!str) return false;
      const regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      return regex.test(str);
    };
    const creatorId = isUUID(creador) ? creador : null;

    const rewardResult = await db.query(
      `INSERT INTO public.family_rewards (id, family_id, titulo, costo, descripcion, emoji, disponible, creador_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (id) DO UPDATE SET
         titulo = EXCLUDED.titulo,
         costo = EXCLUDED.costo,
         descripcion = EXCLUDED.descripcion,
         emoji = EXCLUDED.emoji,
         disponible = EXCLUDED.disponible,
         creador_id = EXCLUDED.creador_id
       RETURNING id, family_id AS "familyId", titulo, costo, descripcion, emoji, disponible, creador_id AS "creador"`,
      [id, familyId, titulo, costo, descripcion || '', emoji || '🎁', disponible !== false, creatorId]
    );
    res.status(201).json(rewardResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al guardar el premio' });
  }
});

// Update reward
router.put('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  const { disponible, lastRedeemedAt } = req.body;

  try {
    const rewardResult = await db.query(
      `UPDATE public.family_rewards
       SET disponible = COALESCE($1, disponible),
           last_redeemed_at = COALESCE($2, last_redeemed_at)
       WHERE id = $3
       RETURNING id, family_id AS "familyId", titulo, costo, descripcion, emoji, disponible, creador_id AS "creador", last_redeemed_at AS "lastRedeemedAt"`,
      [disponible, lastRedeemedAt || null, id]
    );

    if (rewardResult.rows.length === 0) {
      return res.status(404).json({ error: 'Premio no encontrado' });
    }

    res.json(rewardResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar premio' });
  }
});

// Redeem a reward (Transactional: checks balance, subtracts coins, registers redemption)
router.post('/:id/redeem', authMiddleware, async (req, res) => {
  const { id } = req.params;

  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Get Reward details
    const rewardResult = await client.query('SELECT * FROM public.family_rewards WHERE id = $1', [id]);
    if (rewardResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Premio no encontrado' });
    }

    const reward = rewardResult.rows[0];
    if (!reward.disponible) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Premio no disponible' });
    }

    // 2. Get User Profile Coins
    const profileResult = await client.query('SELECT monedas, nombre FROM public.profiles WHERE id = $1', [req.user.userId]);
    if (profileResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Perfil de usuario no encontrado' });
    }

    const profile = profileResult.rows[0];
    if (profile.monedas < reward.costo) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: `Monedas insuficientes. Necesitas ${reward.costo} y tienes ${profile.monedas}.` });
    }

    // 3. Subtract coins from User
    const updatedProfileResult = await client.query(
      'UPDATE public.profiles SET monedas = monedas - $1 WHERE id = $2 RETURNING monedas',
      [reward.costo, req.user.userId]
    );

    // 4. Update reward last redeemed timestamp
    const now = new Date();
    const updatedRewardResult = await client.query(
      'UPDATE public.family_rewards SET last_redeemed_at = $1 WHERE id = $2 RETURNING *',
      [now, id]
    );

    // 5. Create validation record (the redemption request requires approval by jefe family)
    await client.query(
      `INSERT INTO public.reto_validations (family_id, user_id, usuario, avatar, color, reto, hora, xp, monedas, evidencias, requiere_evidencia, estado)
       VALUES ($1, $2, $3, $4, $5, $6, 'Recién', 0, $7, '{}', false, 'pendiente')`,
      [
        reward.family_id,
        req.user.userId,
        profile.nombre,
        '🎁',
        '#d32f2f',
        `Canjear: ${reward.titulo}`,
        -reward.costo, // Represents spending
      ]
    );

    await client.query('COMMIT');
    res.json({
      success: true,
      newCoins: updatedProfileResult.rows[0].monedas,
      reward: updatedRewardResult.rows[0],
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Error al procesar el canje' });
  } finally {
    client.release();
  }
});

router.get('/history', authMiddleware, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT reto AS "titulo", ABS(monedas) AS "costo", created_at AS "created_at"
       FROM public.reto_validations
       WHERE user_id = $1 AND reto LIKE 'Canjear:%'
       ORDER BY created_at DESC`,
      [req.user.userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener historial de canjes' });
  }
});

router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query('DELETE FROM public.family_rewards WHERE id = $1 RETURNING id', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Premio no encontrado' });
    }
    res.json({ success: true, id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al eliminar el premio' });
  }
});

module.exports = router;
