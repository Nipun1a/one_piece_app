'use strict';

// Set env vars BEFORE requiring the app so database.js picks up :memory:
process.env.DATABASE_FILE = ':memory:';
process.env.JWT_SECRET = 'test-auth-secret';

const request = require('supertest');
const app = require('../index');

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------
describe('POST /api/auth/register', () => {
  test('happy path — returns 201 with token and user shape', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Luffy', email: 'luffy@test.com', password: 'gomugomu99' });

    expect(res.status).toBe(201);
    expect(typeof res.body.token).toBe('string');
    expect(res.body.token.length).toBeGreaterThan(0);
    expect(res.body.user).toMatchObject({
      name: 'Luffy',
      email: 'luffy@test.com',
    });
    expect(typeof res.body.user.id).toBe('number');
  });

  test('duplicate email — returns 409 with correct error message', async () => {
    const payload = { name: 'Luffy', email: 'duplicate@test.com', password: 'gomugomu99' };

    // First registration should succeed
    await request(app).post('/api/auth/register').send(payload);

    // Second registration with the same email should fail
    const res = await request(app).post('/api/auth/register').send(payload);

    expect(res.status).toBe(409);
    expect(res.body).toEqual({ error: 'Email already registered' });
  });

  test('missing name field — returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: 'zoro@test.com', password: 'sanjigiri1' });

    expect(res.status).toBe(400);
  });

  test('missing email field — returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Zoro', password: 'sanjigiri1' });

    expect(res.status).toBe(400);
  });

  test('missing password field — returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Zoro', email: 'zoro@test.com' });

    expect(res.status).toBe(400);
  });

  test('malformed email — returns 400 with "Invalid email address"', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Nami', email: 'notanemail', password: 'oranges123' });

    expect(res.status).toBe(400);
    expect(res.body).toEqual({ error: 'Invalid email address' });
  });
});

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------
describe('POST /api/auth/login', () => {
  // Register a shared user before running login tests
  beforeAll(async () => {
    await request(app)
      .post('/api/auth/register')
      .send({ name: 'Sanji', email: 'sanji@test.com', password: 'vinsmoke99' });
  });

  test('happy path — returns 200 with token and user shape', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'sanji@test.com', password: 'vinsmoke99' });

    expect(res.status).toBe(200);
    expect(typeof res.body.token).toBe('string');
    expect(res.body.token.length).toBeGreaterThan(0);
    expect(res.body.user).toMatchObject({
      name: 'Sanji',
      email: 'sanji@test.com',
    });
    expect(typeof res.body.user.id).toBe('number');
  });

  test('wrong password — returns 401 with "Invalid credentials"', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'sanji@test.com', password: 'wrongpassword' });

    expect(res.status).toBe(401);
    expect(res.body).toEqual({ error: 'Invalid credentials' });
  });

  test('unknown email — returns 401 with "Invalid credentials"', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'ghost@test.com', password: 'doesnotmatter' });

    expect(res.status).toBe(401);
    expect(res.body).toEqual({ error: 'Invalid credentials' });
  });

  test('missing email — returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ password: 'vinsmoke99' });

    expect(res.status).toBe(400);
  });

  test('missing password — returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'sanji@test.com' });

    expect(res.status).toBe(400);
  });
});
