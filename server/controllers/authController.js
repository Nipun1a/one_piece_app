'use strict';

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db/database');

const BCRYPT_WORK_FACTOR = 10;
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Sign a JWT for the given userId.
 * Expiry comes from JWT_EXPIRES_IN env var, defaulting to '24h'.
 */
function signToken(userId) {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
  );
}

/**
 * POST /api/auth/register
 *
 * Body: { name, email, password }
 *
 * Validates:
 *   - name is present and non-empty                 → 400
 *   - email is present and matches email format     → 400
 *   - password is present and ≥ 8 characters        → 400
 *   - email is not already registered               → 409
 *
 * On success: hashes password with bcrypt (work factor ≥ 10),
 * inserts the user, signs a JWT, returns 201 { token, user }.
 */
async function register(req, res, next) {
  try {
    const { name, email, password } = req.body;

    // --- Field validation ---
    if (!name || typeof name !== 'string' || name.trim() === '') {
      return res.status(400).json({ error: 'Name is required' });
    }
    if (!email || typeof email !== 'string' || email.trim() === '') {
      return res.status(400).json({ error: 'Email is required' });
    }
    if (!EMAIL_REGEX.test(email.trim())) {
      return res.status(400).json({ error: 'Invalid email address' });
    }
    if (!password || typeof password !== 'string') {
      return res.status(400).json({ error: 'Password is required' });
    }
    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }

    const trimmedName = name.trim();
    const trimmedEmail = email.trim().toLowerCase();

    // --- Duplicate email check (parameterised query) ---
    const existing = db
      .prepare('SELECT id FROM users WHERE email = ?')
      .get(trimmedEmail);

    if (existing) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    // --- Hash password (work factor ≥ 10) ---
    const hashedPassword = await bcrypt.hash(password, BCRYPT_WORK_FACTOR);

    // --- Insert user (parameterised query) ---
    const insert = db.prepare(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)'
    );
    const result = insert.run(trimmedName, trimmedEmail, hashedPassword);
    const userId = result.lastInsertRowid;

    // --- Sign JWT ---
    const token = signToken(userId);

    return res.status(201).json({
      token,
      user: {
        id: userId,
        name: trimmedName,
        email: trimmedEmail,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /api/auth/login
 *
 * Body: { email, password }
 *
 * Validates:
 *   - email is present                              → 400
 *   - password is present                          → 400
 *   - user with given email exists in DB           → 401
 *   - supplied password matches stored hash        → 401
 *
 * On success: signs a JWT, returns 200 { token, user }.
 */
async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    // --- Field presence validation ---
    if (!email || typeof email !== 'string' || email.trim() === '') {
      return res.status(400).json({ error: 'Email is required' });
    }
    if (!password || typeof password !== 'string' || password === '') {
      return res.status(400).json({ error: 'Password is required' });
    }

    const trimmedEmail = email.trim().toLowerCase();

    // --- Look up user by email (parameterised query) ---
    const user = db
      .prepare('SELECT id, name, email, password FROM users WHERE email = ?')
      .get(trimmedEmail);

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // --- Compare supplied password against stored hash ---
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // --- Sign JWT ---
    const token = signToken(user.id);

    return res.status(200).json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login };
