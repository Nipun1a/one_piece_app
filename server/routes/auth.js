'use strict';

const express = require('express');
const { register, login } = require('../controllers/authController');

const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const db = require('../db/database');

router.get('/me', verifyToken, (req, res) => {
  const user = db.prepare('SELECT id, name, email FROM users WHERE id = ?').get(req.user.id);
  if (!user) return res.status(401).json({ error: 'Session is no longer valid' });
  res.json(user);
});

// POST /api/auth/register
router.post('/register', register);

// POST /api/auth/login
router.post('/login', login);

module.exports = router;
