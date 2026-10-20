'use strict';

require('dotenv').config();

const express = require('express');
const cors = require('cors');

const db = require('./db/database');
const { runMigrations } = require('./db/migrations');
const { seedProducts } = require('./db/seed');

const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');

const app = express();

// ── Middleware ──────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// ── Database initialisation ─────────────────────────────────────────────────
runMigrations(db);
seedProducts(db);

// ── Routes ──────────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);

// ── 404 handler ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ── Global error handler ────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Invalid JSON request body' });
  }
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

// ── Start server only when run directly (not when required by tests) ─────────
if (require.main === module) {
  if (!process.env.JWT_SECRET) throw new Error('Set JWT_SECRET in server/.env before starting the API');
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`[server] Grand Line Store API listening on port ${PORT}`);
  });
}

module.exports = app;
