const express = require('express');
const router = express.Router();
const db = require('../db');
const authMiddleware = require('../middleware/auth');

// Get all tasks in family
router.get('/', authMiddleware, async (req, res) => {
  const { familyId } = req.query;
  if (!familyId) {
    return res.status(400).json({ error: 'familyId requerido' });
  }

  try {
    const tasksResult = await db.query(
      'SELECT id, family_id AS "familyId", tarea, asignado_id AS "asignado", hecho, xp, tipo FROM public.tasks WHERE family_id = $1 ORDER BY created_at ASC',
      [familyId]
    );
    res.json(tasksResult.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener tareas' });
  }
});

// Create a task
router.post('/', authMiddleware, async (req, res) => {
  const { familyId, tarea, asignado, hecho, xp, tipo } = req.body;
  if (!familyId || !tarea) {
    return res.status(400).json({ error: 'familyId y tarea requeridos' });
  }

  try {
    const taskResult = await db.query(
      `INSERT INTO public.tasks (family_id, tarea, asignado_id, hecho, xp, tipo)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, family_id AS "familyId", tarea, asignado_id AS "asignado", hecho, xp, tipo`,
      [familyId, tarea, asignado || null, hecho || false, xp || 0, tipo || 'general']
    );
    res.status(201).json(taskResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear la tarea' });
  }
});

// Toggle task status
router.put('/:id/toggle', authMiddleware, async (req, res) => {
  const { hecho } = req.body;
  const { id } = req.params;

  try {
    const taskResult = await db.query(
      `UPDATE public.tasks
       SET hecho = $1
       WHERE id = $2
       RETURNING id, family_id AS "familyId", tarea, asignado_id AS "asignado", hecho, xp, tipo`,
      [hecho, id]
    );

    if (taskResult.rows.length === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }

    res.json(taskResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar estado de la tarea' });
  }
});

// Delete a task
router.delete('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await db.query('DELETE FROM public.tasks WHERE id = $1 RETURNING id', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Tarea no encontrada' });
    }
    res.json({ success: true, id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al eliminar la tarea' });
  }
});

module.exports = router;
