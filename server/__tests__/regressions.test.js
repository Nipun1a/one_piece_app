'use strict';
process.env.DATABASE_FILE = ':memory:';
process.env.JWT_SECRET = 'regression-secret';
const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../index');
const db = require('../db/database');
let token;
beforeAll(async () => {
  const res = await request(app).post('/api/auth/register').send({ name: 'Nami', email: 'nami@test.dev', password: 'navigation123' });
  token = res.body.token;
});
test('session endpoint returns the server user without password', async () => {
  const res = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${token}`);
  expect(res.status).toBe(200);
  expect(res.body.email).toBe('nami@test.dev');
  expect(res.body.password).toBeUndefined();
});
test.each(['Basic', 'Token'])('rejects %s authorization scheme', async (scheme) => {
  const res = await request(app).get('/api/auth/me').set('Authorization', `${scheme} ${token}`);
  expect(res.status).toBe(401);
});
test.each([{}, { userId: '1' }, { userId: -1 }])('rejects invalid signed claims %j', async claims => {
  const invalid = jwt.sign(claims, process.env.JWT_SECRET);
  expect((await request(app).get('/api/orders').set('Authorization', `Bearer ${invalid}`)).status).toBe(401);
});
test('rejects expired sessions', async () => {
  const expired = jwt.sign({ userId: 1 }, process.env.JWT_SECRET, { expiresIn: -1 });
  expect((await request(app).get('/api/auth/me').set('Authorization', `Bearer ${expired}`)).status).toBe(401);
});
test.each([0, -2, 1.5, '2', null])('rejects invalid quantity %j without changing stock', async quantity => {
  const before = db.prepare('SELECT stock FROM products WHERE id = 1').get().stock;
  const res = await request(app).post('/api/orders').set('Authorization', `Bearer ${token}`).send({ items: [{ productId: 1, quantity }], address: 'East Blue', phone: '1234567890' });
  expect(res.status).toBe(400);
  expect(db.prepare('SELECT stock FROM products WHERE id = 1').get().stock).toBe(before);
});
test('duplicate product rows cannot oversell stock', async () => {
  const stock = db.prepare('SELECT stock FROM products WHERE id = 1').get().stock;
  const res = await request(app).post('/api/orders').set('Authorization', `Bearer ${token}`).send({ items: [{ productId: 1, quantity: stock }, { productId: 1, quantity: 1 }], address: 'East Blue', phone: '1234567890' });
  expect(res.status).toBe(409);
  expect(db.prepare('SELECT stock FROM products WHERE id = 1').get().stock).toBe(stock);
});
test('malformed JSON is a client error', async () => {
  expect((await request(app).post('/api/auth/login').set('Content-Type', 'application/json').send('{')).status).toBe(400);
});
