const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

// Get all bills in family
router.get('/', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const billsResult = await db.query(
      `SELECT id, family_id AS "familyId", tipo, consumo, monto, periodo, empresa, cuenta, tarifa, imagen_url AS "imagenUrl"
       FROM public.bills
       WHERE family_id = $1
       ORDER BY created_at DESC`,
      [familyId]
    );
    res.json(billsResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener recibos' });
  }
});

// Create new bill
router.post('/', authMiddleware, async (req, res) => {
  const { familyId, tipo, consumo, monto, periodo, empresa, cuenta, tarifa, imagenUrl } = req.body;
  if (!familyId || !tipo || !monto || !periodo) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  try {
    const billResult = await db.query(
      `INSERT INTO public.bills (family_id, tipo, consumo, monto, periodo, empresa, cuenta, tarifa, imagen_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, family_id AS "familyId", tipo, consumo, monto, periodo, empresa, cuenta, tarifa, imagen_url AS "imagenUrl"`,
      [familyId, tipo, consumo || '', monto, periodo, empresa || '', cuenta || '', tarifa || '', imagenUrl || null]
    );
    res.status(201).json(billResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al registrar recibo' });
  }
});

// Delete bill
router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query('DELETE FROM public.bills WHERE id = $1 RETURNING id', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Recibo no encontrado' });
    }
    res.json({ success: true, id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al eliminar el recibo' });
  }
});

module.exports = router;
