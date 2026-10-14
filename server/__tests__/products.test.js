'use strict';

// Use an in-memory SQLite database so tests are isolated and fast.
// This MUST be set before requiring the app so database.js picks it up.
process.env.DATABASE_FILE = ':memory:';
process.env.JWT_SECRET = 'test-products-secret';

const request = require('supertest');

// Require the app after setting the env variables above
const app = require('../index');

// ──────────────────────────────────────────────────────────────────────────────
// Helper: shape assertion for a single product object
// ──────────────────────────────────────────────────────────────────────────────
function expectProductShape(product) {
  expect(product).toEqual(
    expect.objectContaining({
      id: expect.any(Number),
      name: expect.any(String),
      description: expect.any(String),
      price: expect.any(Number),
      category: expect.any(String),
      imageUrl: expect.any(String),
      stock: expect.any(Number),
      rating: expect.any(Number),
    })
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Test suite
// ──────────────────────────────────────────────────────────────────────────────
describe('GET /api/products', () => {
  // ── 1. List all products ──────────────────────────────────────────────────
  test('returns 200 with an array of products that have the correct shape', async () => {
    const res = await request(app).get('/api/products');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    // Seed inserts 15 products
    expect(res.body.length).toBeGreaterThanOrEqual(12);
    res.body.forEach(expectProductShape);
  });

  // ── 2. Filter by category — Figures ──────────────────────────────────────
  test('returns 200 with only Figures products when ?category=Figures', async () => {
    const res = await request(app).get('/api/products?category=Figures');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    res.body.forEach(p => {
      expect(p.category).toBe('Figures');
    });
  });

  // ── 3. Filter by category — Apparel ──────────────────────────────────────
  test('returns 200 with only Apparel products when ?category=Apparel', async () => {
    const res = await request(app).get('/api/products?category=Apparel');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    res.body.forEach(p => {
      expect(p.category).toBe('Apparel');
    });
  });

  // ── 4. Filter by category — Posters ──────────────────────────────────────
  test('returns 200 with only Posters products when ?category=Posters', async () => {
    const res = await request(app).get('/api/products?category=Posters');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    res.body.forEach(p => {
      expect(p.category).toBe('Posters');
    });
  });

  // ── 5. Filter by category — Keychains ────────────────────────────────────
  test('returns 200 with only Keychains products when ?category=Keychains', async () => {
    const res = await request(app).get('/api/products?category=Keychains');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    res.body.forEach(p => {
      expect(p.category).toBe('Keychains');
    });
  });

  // ── 6. Filter by category — Accessories ──────────────────────────────────
  test('returns 200 with only Accessories products when ?category=Accessories', async () => {
    const res = await request(app).get('/api/products?category=Accessories');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    res.body.forEach(p => {
      expect(p.category).toBe('Accessories');
    });
  });

  // ── 7. Case-insensitive search — known seed term ──────────────────────────
  test('returns 200 with matching products for case-insensitive search ?search=luffy', async () => {
    const res = await request(app).get('/api/products?search=luffy');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    // Every returned product must contain "luffy" (case-insensitive) in name or description
    res.body.forEach(p => {
      const haystack = `${p.name} ${p.description}`.toLowerCase();
      expect(haystack).toContain('luffy');
    });
  });

  test('returns 200 with matching products for uppercase search ?search=LUFFY', async () => {
    const res = await request(app).get('/api/products?search=LUFFY');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    res.body.forEach(p => {
      const haystack = `${p.name} ${p.description}`.toLowerCase();
      expect(haystack).toContain('luffy');
    });
  });

  // ── 8. Search with no matches ─────────────────────────────────────────────
  test('returns 200 with empty array when search has no matches', async () => {
    const res = await request(app).get('/api/products?search=zzznomatch999');

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body).toHaveLength(0);
  });

  // ── 9. Invalid category → 400 ─────────────────────────────────────────────
  test('returns 400 with error message for an invalid category', async () => {
    const res = await request(app).get('/api/products?category=Invalid');

    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Invalid category' });
  });

  test('returns 400 for other unrecognised category values', async () => {
    const res = await request(app).get('/api/products?category=Weapons');

    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Invalid category' });
  });
});

// ──────────────────────────────────────────────────────────────────────────────
describe('GET /api/products/:id', () => {
  // ── 10. Fetch by id ──────────────────────────────────────────────────────
  test('returns 200 with a full product object for a known id', async () => {
    // Seed data starts at id=1
    const res = await request(app).get('/api/products/1');

    expect(res.status).toBe(200);
    expectProductShape(res.body);
    expect(res.body.id).toBe(1);
  });

  test('returned product has all expected fields with correct types', async () => {
    const res = await request(app).get('/api/products/1');

    expect(res.status).toBe(200);
    const p = res.body;
    expect(typeof p.id).toBe('number');
    expect(typeof p.name).toBe('string');
    expect(typeof p.description).toBe('string');
    expect(typeof p.price).toBe('number');
    expect(typeof p.category).toBe('string');
    expect(typeof p.imageUrl).toBe('string');
    expect(typeof p.stock).toBe('number');
    expect(typeof p.rating).toBe('number');
  });

  // ── 11. Fetch unknown id → 404 ────────────────────────────────────────────
  test('returns 404 with error message for an unknown product id', async () => {
    const res = await request(app).get('/api/products/99999');

    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: 'Product not found' });
  });

  test('returns 404 for another non-existent product id', async () => {
    const res = await request(app).get('/api/products/1000000');

    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: 'Product not found' });
  });
});
