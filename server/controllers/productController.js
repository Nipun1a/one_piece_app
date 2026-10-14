'use strict';

const db = require('../db/database');

const VALID_CATEGORIES = ['Figures', 'Apparel', 'Posters', 'Keychains', 'Accessories'];

/**
 * GET /api/products
 * Optional query params: category, search
 *
 * Returns 200 with a JSON array of Product objects.
 * Returns 400 if the `category` param is not in the valid enum.
 */
function listProducts(req, res) {
  const { category, search } = req.query;

  // Validate category if provided
  if (category !== undefined && !VALID_CATEGORIES.includes(category)) {
    return res.status(400).json({ error: 'Invalid category' });
  }

  // Build parameterised query with optional WHERE clauses
  const conditions = [];
  const params = [];

  if (category) {
    conditions.push('category = ?');
    params.push(category);
  }

  if (search) {
    conditions.push('(LOWER(name) LIKE ? OR LOWER(description) LIKE ?)');
    const pattern = `%${search.toLowerCase()}%`;
    params.push(pattern, pattern);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
  const sql = `SELECT id, name, description, price, category, imageUrl, stock, rating FROM products ${whereClause} ORDER BY id`;

  const products = db.prepare(sql).all(...params);
  return res.status(200).json(products);
}

/**
 * GET /api/products/:id
 *
 * Returns 200 with the Product object.
 * Returns 404 if the product does not exist.
 */
function getProduct(req, res) {
  const { id } = req.params;

  const product = db
    .prepare('SELECT id, name, description, price, category, imageUrl, stock, rating FROM products WHERE id = ?')
    .get(id);

  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }

  return res.status(200).json(product);
}

module.exports = { listProducts, getProduct };
