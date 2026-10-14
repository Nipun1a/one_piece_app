'use strict';

/**
 * Runs all CREATE TABLE IF NOT EXISTS statements to initialise the schema.
 * Safe to call on every startup — existing tables are left untouched.
 *
 * @param {import('better-sqlite3').Database} db
 */
function runMigrations(db) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      name      TEXT    NOT NULL,
      email     TEXT    NOT NULL UNIQUE,
      password  TEXT    NOT NULL,
      createdAt TEXT    NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS products (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      description TEXT    NOT NULL,
      price       REAL    NOT NULL CHECK (price >= 0),
      category    TEXT    NOT NULL CHECK (category IN ('Figures','Apparel','Posters','Keychains','Accessories')),
      imageUrl    TEXT    NOT NULL,
      stock       INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
      rating      REAL    NOT NULL DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5)
    );

    CREATE TABLE IF NOT EXISTS orders (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      userId    INTEGER NOT NULL REFERENCES users(id),
      total     REAL    NOT NULL CHECK (total >= 0),
      status    TEXT    NOT NULL DEFAULT 'confirmed',
      address   TEXT    NOT NULL,
      phone     TEXT    NOT NULL,
      createdAt TEXT    NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS order_items (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      orderId     INTEGER NOT NULL REFERENCES orders(id),
      productId   INTEGER NOT NULL REFERENCES products(id),
      quantity    INTEGER NOT NULL CHECK (quantity > 0),
      price       REAL    NOT NULL CHECK (price >= 0)
    );
  `);
}

module.exports = { runMigrations };
