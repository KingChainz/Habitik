const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

router.post('/create', authMiddleware, async (req, res) => {
  const { nombre } = req.body;
  if (!nombre) {
    return res.status(400).json({ error: 'Nombre de familia requerido' });
  }

  try {
    const familyCode = 'HAB-' + Math.random().toString(36).substring(2, 10).toUpperCase();

    const familyResult = await db.query(
      'INSERT INTO public.families (nombre, family_code) VALUES ($1, $2) RETURNING *',
      [nombre, familyCode]
    );
    const family = familyResult.rows[0];

    const profileResult = await db.query(
      "UPDATE public.profiles SET family_id = $1, rol = 'jefe' WHERE id = $2 RETURNING *",
      [family.id, req.user.userId]
    );

    res.status(201).json({ family, profile: profileResult.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error del servidor al crear grupo familiar' });
  }
});

router.post('/join', authMiddleware, async (req, res) => {
  const { familyId } = req.body;
  if (!familyId) {
    return res.status(400).json({ error: 'ID de familia requerido' });
  }

  try {
    const familyExist = await db.query('SELECT * FROM public.families WHERE id = $1', [familyId]);
    if (familyExist.rows.length === 0) {
      return res.status(404).json({ error: 'El grupo familiar no existe' });
    }

    const family = familyExist.rows[0];

    const profileResult = await db.query(
      "UPDATE public.profiles SET family_id = $1, rol = 'miembro' WHERE id = $2 RETURNING *",
      [family.id, req.user.userId]
    );

    res.json({ family, profile: profileResult.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error del servidor al unirse al grupo familiar' });
  }
});

router.get('/members', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const membersResult = await db.query(
      'SELECT id, nombre, rol, xp, nivel, avatar_letra, avatar_color, avatar_url, trivia_correct_count, trivia_last_updated FROM public.profiles WHERE family_id = $1 ORDER BY xp DESC',
      [familyId]
    );
    res.json(membersResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener miembros de la familia' });
  }
});

router.get('/details', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const result = await db.query('SELECT * FROM public.families WHERE id = $1', [familyId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Grupo familiar no encontrado' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener detalles de la familia' });
  }
});

router.put('/metas', authMiddleware, async (req, res) => {
  const { familyId, metaLuz, metaAgua } = req.body;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const result = await db.query(
      'UPDATE public.families SET meta_luz = $1, meta_agua = $2 WHERE id = $3 RETURNING *',
      [metaLuz || 0, metaAgua || 0, familyId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Grupo familiar no encontrado' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar metas de la familia' });
  }
});

router.post('/:familyId/qr', authMiddleware, async (req, res) => {
  const { familyId } = req.params;
  const { forceNew } = req.body;

  try {
    if (!forceNew) {
      const activeTokenResult = await db.query(
        "SELECT token, expires_at FROM public.qr_tokens WHERE family_id = $1 AND used = false AND expires_at > NOW() ORDER BY expires_at DESC LIMIT 1",
        [familyId]
      );
      if (activeTokenResult.rows.length > 0) {
        const activeToken = activeTokenResult.rows[0];
        const timeLeft = Math.floor((new Date(activeToken.expires_at) - new Date()) / 1000);
        return res.json({ token: activeToken.token, timeLeft });
      }
    }

    const token = 'HAB-' + Math.random().toString(36).substring(2, 10).toUpperCase();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await db.query(
      "INSERT INTO public.qr_tokens (family_id, token, expires_at) VALUES ($1, $2, $3)",
      [familyId, token, expiresAt]
    );

    res.status(201).json({ token, timeLeft: 600 });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al generar token QR' });
  }
});

router.post('/validate-code', authMiddleware, async (req, res) => {
  const { code } = req.body;
  if (!code) {
    return res.status(400).json({ error: 'Código requerido' });
  }

  try {
    const familyResult = await db.query(
      "SELECT id FROM public.families WHERE family_code = $1",
      [code]
    );
    if (familyResult.rows.length > 0) {
      return res.json({ familyId: familyResult.rows[0].id });
    }

    const qrResult = await db.query(
      "SELECT family_id, id FROM public.qr_tokens WHERE token = $1 AND used = false AND expires_at > NOW()",
      [code]
    );
    if (qrResult.rows.length > 0) {
      const qrToken = qrResult.rows[0];
      await db.query(
        "UPDATE public.qr_tokens SET used = true WHERE id = $1",
        [qrToken.id]
      );
      return res.json({ familyId: qrToken.family_id });
    }

    res.status(400).json({ error: 'Código inválido o expirado' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al validar código' });
  }
});

router.put('/members/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;
  const { nombre, rol } = req.body;

  try {
    const result = await db.query(
      `UPDATE public.profiles
       SET nombre = COALESCE($1, nombre),
           rol = COALESCE($2, rol)
       WHERE id = $3 RETURNING *`,
      [nombre, rol, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Miembro no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar miembro' });
  }
});

router.put('/:familyId', authMiddleware, async (req, res) => {
  const { familyId } = req.params;
  const { nombre, avatarUrl } = req.body;

  try {
    const result = await db.query(
      `UPDATE public.families
       SET nombre = COALESCE($1, nombre),
           avatar_url = COALESCE($2, avatar_url)
       WHERE id = $3 RETURNING *`,
      [nombre, avatarUrl, familyId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Grupo familiar no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar grupo familiar' });
  }
});

module.exports = router;
