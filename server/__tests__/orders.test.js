'use strict';

// Use an in-memory SQLite database so tests are isolated and fast.
// These MUST be set before requiring the app so database.js picks them up.
process.env.DATABASE_FILE = ':memory:';
process.env.JWT_SECRET = 'test-orders-secret';

const request = require('supertest');

// Require the app after setting the env variables above
const app = require('../index');

// ──────────────────────────────────────────────────────────────────────────────
// Shared test state — populated in beforeAll
// ──────────────────────────────────────────────────────────────────────────────
let token;       // JWT for the primary test user
let userId;      // primary user's id
let productId;   // id of a seeded product with stock > 0
let productStock; // original stock of that product

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

/** Register a new user and return { token, user }. */
async function registerUser(name, email, password = 'SecurePass1') {
  const res = await request(app)
    .post('/api/auth/register')
    .send({ name, email, password });
  return res.body; // { token, user }
}

/** Login and return { token, user }. */
async function loginUser(email, password = 'SecurePass1') {
  const res = await request(app)
    .post('/api/auth/login')
    .send({ email, password });
  return res.body;
}

/** POST /api/orders with an authenticated request. */
async function placeOrder(jwt, body) {
  return request(app)
    .post('/api/orders')
    .set('Authorization', `Bearer ${jwt}`)
    .send(body);
}

/** GET /api/orders with an authenticated request. */
async function listOrders(jwt) {
  return request(app)
    .get('/api/orders')
    .set('Authorization', `Bearer ${jwt}`);
}

// ──────────────────────────────────────────────────────────────────────────────
// Setup — runs once before all tests in this file
// ──────────────────────────────────────────────────────────────────────────────
beforeAll(async () => {
  // Register the primary test user
  const reg = await registerUser('Monkey D. Luffy', 'luffy@grandline.test');
  token = reg.token;
  userId = reg.user.id;

  // Find a real product with stock > 0 from the seed data
  const productsRes = await request(app).get('/api/products');
  const available = productsRes.body.filter(p => p.stock > 0);
  expect(available.length).toBeGreaterThan(0);

  const product = available[0];
  productId = product.id;
  productStock = product.stock;
});

// ──────────────────────────────────────────────────────────────────────────────
// Test suite
// ──────────────────────────────────────────────────────────────────────────────

describe('POST /api/orders', () => {
  // ── 1. Happy path ──────────────────────────────────────────────────────────
  test('201 — places an order and returns the full Order shape', async () => {
    const res = await placeOrder(token, {
      items: [{ productId, quantity: 1 }],
      address: '123 Grand Line',
      phone: '5551234567',
    });

    expect(res.status).toBe(201);

    const order = res.body;
    // Top-level shape
    expect(order).toEqual(
      expect.objectContaining({
        id: expect.any(Number),
        userId: expect.any(Number),
        total: expect.any(Number),
        status: expect.any(String),
        address: '123 Grand Line',
        phone: '5551234567',
        createdAt: expect.any(String),
      })
    );
    // Items array
    expect(Array.isArray(order.items)).toBe(true);
    expect(order.items).toHaveLength(1);
    expect(order.items[0]).toEqual(
      expect.objectContaining({
        productId: expect.any(Number),
        productName: expect.any(String),
        quantity: expect.any(Number),
        price: expect.any(Number),
      })
    );
    expect(order.userId).toBe(userId);
    expect(order.items[0].productId).toBe(productId);
    expect(order.items[0].quantity).toBe(1);
    expect(order.total).toBeGreaterThan(0);
  });

  // ── 2. Insufficient stock ──────────────────────────────────────────────────
  test('409 — returns error and leaves stock unchanged when quantity > stock', async () => {
    // Fetch current stock for this product
    const productRes = await request(app).get(`/api/products/${productId}`);
    const currentStock = productRes.body.stock;

    // Request more than the available stock
    const overQuantity = currentStock + 1000;
    const res = await placeOrder(token, {
      items: [{ productId, quantity: overQuantity }],
      address: '123 Grand Line',
      phone: '5551234567',
    });

    expect(res.status).toBe(409);
    expect(res.body).toHaveProperty('error');
    expect(res.body.error).toMatch(/Insufficient stock/i);

    // Verify stock has not changed
    const afterRes = await request(app).get(`/api/products/${productId}`);
    expect(afterRes.body.stock).toBe(currentStock);
  });

  // ── 3. Product not found ───────────────────────────────────────────────────
  test('404 — returns error when productId does not exist', async () => {
    const res = await placeOrder(token, {
      items: [{ productId: 999999, quantity: 1 }],
      address: '123 Grand Line',
      phone: '5551234567',
    });

    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: 'Product 999999 not found' });
  });

  // ── 4. Empty items array ───────────────────────────────────────────────────
  test('400 — returns error when items array is empty', async () => {
    const res = await placeOrder(token, {
      items: [],
      address: '123 Grand Line',
      phone: '5551234567',
    });

    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Order must contain at least one item' });
  });

  // ── 5. No JWT ──────────────────────────────────────────────────────────────
  test('401 — returns 401 when Authorization header is absent', async () => {
    const res = await request(app)
      .post('/api/orders')
      .send({
        items: [{ productId, quantity: 1 }],
        address: '123 Grand Line',
        phone: '5551234567',
      });

    expect(res.status).toBe(401);
  });

  // ── 6. Invalid JWT ─────────────────────────────────────────────────────────
  test('401 — returns 401 when JWT is invalid', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', 'Bearer badtoken')
      .send({
        items: [{ productId, quantity: 1 }],
        address: '123 Grand Line',
        phone: '5551234567',
      });

    expect(res.status).toBe(401);
  });
});

// ──────────────────────────────────────────────────────────────────────────────

describe('GET /api/orders', () => {
  // ── 7. List orders ─────────────────────────────────────────────────────────
  test('200 — returns array of orders including a recently placed one', async () => {
    // Register a fresh user so this test is independent of earlier order counts
    const { token: freshToken, user: freshUser } = await registerUser(
      'Roronoa Zoro',
      'zoro@grandline.test'
    );

    // Place an order
    const placed = await placeOrder(freshToken, {
      items: [{ productId, quantity: 1 }],
      address: '456 East Blue',
      phone: '5559876543',
    });
    expect(placed.status).toBe(201);
    const placedOrderId = placed.body.id;

    // List orders
    const listRes = await listOrders(freshToken);

    expect(listRes.status).toBe(200);
    expect(Array.isArray(listRes.body)).toBe(true);
    expect(listRes.body.length).toBeGreaterThanOrEqual(1);

    // The placed order must appear in the list
    const found = listRes.body.find(o => o.id === placedOrderId);
    expect(found).toBeDefined();
    expect(found.userId).toBe(freshUser.id);
    expect(Array.isArray(found.items)).toBe(true);
  });

  // ── 8. Auth isolation ─────────────────────────────────────────────────────
  test('200 — each user only sees their own orders', async () => {
    // Register two independent users
    const { token: tokenA, user: userA } = await registerUser(
      'Nami Orange',
      'nami@grandline.test'
    );
    const { token: tokenB, user: userB } = await registerUser(
      'Usopp Brave',
      'usopp@grandline.test'
    );

    // Each user places at least one order
    const orderA = await placeOrder(tokenA, {
      items: [{ productId, quantity: 1 }],
      address: '1 Cocoyasi Village',
      phone: '1112223333',
    });
    expect(orderA.status).toBe(201);

    const orderB = await placeOrder(tokenB, {
      items: [{ productId, quantity: 1 }],
      address: '2 Syrup Village',
      phone: '4445556666',
    });
    expect(orderB.status).toBe(201);

    const orderAId = orderA.body.id;
    const orderBId = orderB.body.id;

    // Fetch userA's order list
    const listA = await listOrders(tokenA);
    expect(listA.status).toBe(200);

    const listAIds = listA.body.map(o => o.id);
    expect(listAIds).toContain(orderAId);
    expect(listAIds).not.toContain(orderBId);

    // Every order in A's list must belong to userA
    listA.body.forEach(o => {
      expect(o.userId).toBe(userA.id);
    });

    // Fetch userB's order list
    const listB = await listOrders(tokenB);
    expect(listB.status).toBe(200);

    const listBIds = listB.body.map(o => o.id);
    expect(listBIds).toContain(orderBId);
    expect(listBIds).not.toContain(orderAId);

    // Every order in B's list must belong to userB
    listB.body.forEach(o => {
      expect(o.userId).toBe(userB.id);
    });
  });
});
