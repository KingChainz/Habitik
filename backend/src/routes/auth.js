const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const authMiddleware = require('../middleware/auth');

// Register a new user and profile
router.post('/register', async (req, res) => {
  const { email, password, nombre, avatarLetra, avatarColor } = req.body;
  if (!email || !password || !nombre) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  try {
    const userExist = await db.query('SELECT id FROM public.users WHERE email = $1', [email]);
    if (userExist.rows.length > 0) {
      return res.status(400).json({ error: 'El email ya está registrado' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Insert user
    const userResult = await db.query(
      'INSERT INTO public.users (email, password_hash) VALUES ($1, $2) RETURNING id',
      [email, passwordHash]
    );
    const userId = userResult.rows[0].id;

    // Insert profile
    const profileResult = await db.query(
      `INSERT INTO public.profiles (id, email, nombre, avatar_letra, avatar_color, rol, xp, nivel, monedas)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [userId, email, nombre, avatarLetra || 'U', avatarColor || '#2e7d32', 'miembro', 0, 1, 0]
    );

    const token = jwt.sign({ userId, email }, process.env.JWT_SECRET || 'supersecretkeyforhabitikapp');
    res.status(201).json({ token, profile: profileResult.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error del servidor al registrar' });
  }
});

// Login user
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña requeridos' });
  }

  try {
    const userResult = await db.query('SELECT * FROM public.users WHERE email = $1', [email]);
    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: 'Credenciales inválidas' });
    }

    const user = userResult.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ error: 'Credenciales inválidas' });
    }

    const profileResult = await db.query('SELECT * FROM public.profiles WHERE id = $1', [user.id]);
    const token = jwt.sign({ userId: user.id, email: user.email }, process.env.JWT_SECRET || 'supersecretkeyforhabitikapp');

    res.json({ token, profile: profileResult.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error del servidor al iniciar sesión' });
  }
});

// Get current profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const profileResult = await db.query('SELECT * FROM public.profiles WHERE id = $1', [req.user.userId]);
    if (profileResult.rows.length === 0) {
      return res.status(404).json({ error: 'Perfil no encontrado' });
    }
    res.json(profileResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error del servidor' });
  }
});

// Update profile XP, Level, Monedas
router.post('/profile/xp-monedas', authMiddleware, async (req, res) => {
  const { xp, nivel, monedas, triviaCorrectCount, triviaLastUpdated } = req.body;
  try {
    const profileResult = await db.query(
      `UPDATE public.profiles
       SET xp = COALESCE($1, xp),
           nivel = COALESCE($2, nivel),
           monedas = COALESCE($3, monedas),
           trivia_correct_count = COALESCE($4, trivia_correct_count),
           trivia_last_updated = COALESCE($5, trivia_last_updated)
       WHERE id = $6 RETURNING *`,
      [xp, nivel, monedas, triviaCorrectCount, triviaLastUpdated, req.user.userId]
    );
    res.json(profileResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar el perfil' });
  }
});

// Claim Daily Bonus
router.post('/profile/bonus', authMiddleware, async (req, res) => {
  const { claimedAt, xpToAdd, coinsToAdd } = req.body;
  try {
    const profileResult = await db.query(
      `UPDATE public.profiles
       SET daily_bonus_claimed_at = $1,
           xp = xp + $2,
           monedas = monedas + $3
       WHERE id = $4 RETURNING *`,
      [claimedAt, xpToAdd || 0, coinsToAdd || 0, req.user.userId]
    );
    res.json(profileResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al reclamar bono diario' });
  }
});

router.post('/profile/avatar', authMiddleware, async (req, res) => {
  const { avatarUrl } = req.body;
  try {
    const profileResult = await db.query(
      'UPDATE public.profiles SET avatar_url = $1 WHERE id = $2 RETURNING *',
      [avatarUrl, req.user.userId]
    );
    res.json(profileResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar avatar' });
  }
});

router.post('/profile/reward', authMiddleware, async (req, res) => {
  const { xpToAdd, coinsToAdd } = req.body;
  try {
    const profileRes = await db.query('SELECT xp, nivel, monedas FROM public.profiles WHERE id = $1', [req.user.userId]);
    if (profileRes.rows.length === 0) {
      return res.status(404).json({ error: 'Perfil no encontrado' });
    }

    let currentXp = profileRes.rows[0].xp || 0;
    let currentNivel = profileRes.rows[0].nivel || 1;
    let currentMonedas = profileRes.rows[0].monedas || 0;

    currentXp += xpToAdd || 0;
    currentMonedas += coinsToAdd || 0;

    let leveledUp = false;
    const xpNeeded = currentNivel * 500;

    if (currentXp >= xpNeeded) {
      currentNivel++;
      currentXp -= xpNeeded;
      leveledUp = true;
    }

    const updated = await db.query(
      `UPDATE public.profiles
       SET xp = $1, nivel = $2, monedas = $3
       WHERE id = $4 RETURNING *`,
      [currentXp, currentNivel, currentMonedas, req.user.userId]
    );

    res.json({ success: true, profile: updated.rows[0], leveledUp });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al recompensar al usuario' });
  }
});

module.exports = router;
