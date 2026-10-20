'use strict';

const db = require('../db/database');

/**
 * POST /api/orders
 *
 * Requires JWT (verifyToken middleware applied at route level).
 *
 * Body: { items: [{ productId, quantity }], address, phone }
 *
 * Validates:
 *   - items is a non-empty array                          → 400
 *   - address is present and non-empty                   → 400
 *   - phone is present and non-empty                     → 400
 *   - each productId exists in products table            → 404
 *   - stock >= requested quantity for each product       → 409
 *
 * On success:
 *   - Runs a single SQLite transaction: deduct stock, insert order, insert order_items
 *   - Returns 201 with the full Order object including items
 */
function placeOrder(req, res, next) {
  try {
    const userId = req.user.id;
    const { items, address, phone } = req.body || {};
    if (!db.prepare('SELECT id FROM users WHERE id = ?').get(userId)) {
      return res.status(401).json({ error: 'Session is no longer valid' });
    }

    // --- Validate items ---
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Order must contain at least one item' });
    }

    // --- Validate address and phone ---
    if (!address || typeof address !== 'string' || address.trim() === '') {
      return res.status(400).json({ error: 'Address is required' });
    }
    if (!phone || typeof phone !== 'string' || phone.trim() === '') {
      return res.status(400).json({ error: 'Phone is required' });
    }

    const trimmedAddress = address.trim();
    const trimmedPhone = phone.trim();

    // --- Pre-flight: verify all products exist and have sufficient stock ---
    // Collect resolved product data before touching the DB with writes
    const resolvedItems = [];
    const quantities = new Map();
    for (const item of items) {
      if (!item || !Number.isSafeInteger(item.productId) || item.productId <= 0 ||
          !Number.isSafeInteger(item.quantity) || item.quantity <= 0) {
        return res.status(400).json({ error: 'Product IDs and quantities must be positive integers' });
      }
      const quantity = (quantities.get(item.productId) || 0) + item.quantity;
      if (!Number.isSafeInteger(quantity)) return res.status(400).json({ error: 'Quantity is too large' });
      quantities.set(item.productId, quantity);
    }

    for (const [productId, quantity] of quantities) {

      const product = db
        .prepare('SELECT id, name, price, stock FROM products WHERE id = ?')
        .get(productId);

      if (!product) {
        return res.status(404).json({ error: `Product ${productId} not found` });
      }

      if (product.stock < quantity) {
        return res.status(409).json({ error: `Insufficient stock for product ${product.name}` });
      }

      resolvedItems.push({ productId: product.id, productName: product.name, price: product.price, quantity });
    }

    // --- Compute total server-side from resolved prices ---
    const total = resolvedItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
    // Round to 2 decimal places to avoid floating-point drift
    const roundedTotal = Math.round(total * 100) / 100;

    // --- Atomic transaction: deduct stock + insert order + insert order_items ---
    const insertOrderTransaction = db.transaction(() => {
      const deductStock = db.prepare('UPDATE products SET stock = stock - ? WHERE id = ?');
      const insertOrder = db.prepare(
        'INSERT INTO orders (userId, total, status, address, phone) VALUES (?, ?, ?, ?, ?)'
      );
      const insertOrderItem = db.prepare(
        'INSERT INTO order_items (orderId, productId, quantity, price) VALUES (?, ?, ?, ?)'
      );

      // Deduct stock for each item
      for (const item of resolvedItems) {
        deductStock.run(item.quantity, item.productId);
      }

      // Insert the order row
      const orderResult = insertOrder.run(userId, roundedTotal, 'confirmed', trimmedAddress, trimmedPhone);
      const orderId = orderResult.lastInsertRowid;

      // Insert order_items rows
      for (const item of resolvedItems) {
        insertOrderItem.run(orderId, item.productId, item.quantity, item.price);
      }

      return orderId;
    });

    const orderId = insertOrderTransaction();

    // --- Fetch the created order row to get server-generated createdAt ---
    const order = db
      .prepare('SELECT id, userId, total, status, address, phone, createdAt FROM orders WHERE id = ?')
      .get(orderId);

    // --- Build the response shape ---
    return res.status(201).json({
      id: order.id,
      userId: order.userId,
      total: order.total,
      status: order.status,
      address: order.address,
      phone: order.phone,
      createdAt: order.createdAt,
      items: resolvedItems.map(item => ({
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        price: item.price,
      })),
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /api/orders
 *
 * Requires JWT (verifyToken middleware applied at route level).
 *
 * Returns 200 with all orders (and their items) for the authenticated user,
 * ordered by createdAt DESC.
 */
function listOrders(req, res, next) {
  try {
    const userId = req.user.id;
    if (!db.prepare('SELECT id FROM users WHERE id = ?').get(userId)) {
      return res.status(401).json({ error: 'Session is no longer valid' });
    }

    // Fetch all orders for this user, newest first
    const orders = db
      .prepare(
        'SELECT id, userId, total, status, address, phone, createdAt FROM orders WHERE userId = ? ORDER BY createdAt DESC'
      )
      .all(userId);

    // Fetch items for each order
    const getOrderItems = db.prepare(
      `SELECT oi.productId, p.name AS productName, oi.quantity, oi.price
       FROM order_items oi
       JOIN products p ON p.id = oi.productId
       WHERE oi.orderId = ?`
    );

    const result = orders.map(order => ({
      id: order.id,
      userId: order.userId,
      total: order.total,
      status: order.status,
      address: order.address,
      phone: order.phone,
      createdAt: order.createdAt,
      items: getOrderItems.all(order.id),
    }));

    return res.status(200).json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { placeOrder, listOrders };
