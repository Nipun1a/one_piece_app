'use strict';

const jwt = require('jsonwebtoken');
const { verifyToken } = require('../middleware/auth');

const SECRET = 'test-secret';

// Helper to build a mock req/res/next set
function buildMocks({ authHeader } = {}) {
  const req = {
    headers: authHeader ? { authorization: authHeader } : {},
  };
  const res = {
    statusCode: null,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
  const next = jest.fn();
  return { req, res, next };
}

describe('verifyToken middleware', () => {
  beforeEach(() => {
    process.env.JWT_SECRET = SECRET;
  });

  afterEach(() => {
    delete process.env.JWT_SECRET;
  });

  test('returns 401 when Authorization header is absent', () => {
    const { req, res, next } = buildMocks();
    verifyToken(req, res, next);

    expect(res.statusCode).toBe(401);
    expect(res.body).toEqual({ error: 'Unauthorized' });
    expect(next).not.toHaveBeenCalled();
  });

  test('returns 401 when Authorization header has no Bearer token', () => {
    const { req, res, next } = buildMocks({ authHeader: 'Bearer' });
    verifyToken(req, res, next);

    expect(res.statusCode).toBe(401);
    expect(res.body).toEqual({ error: 'Unauthorized' });
    expect(next).not.toHaveBeenCalled();
  });

  test('returns 401 when token is invalid / tampered', () => {
    const { req, res, next } = buildMocks({ authHeader: 'Bearer invalid.token.here' });
    verifyToken(req, res, next);

    expect(res.statusCode).toBe(401);
    expect(res.body).toEqual({ error: 'Unauthorized' });
    expect(next).not.toHaveBeenCalled();
  });

  test('returns 401 when token is signed with a different secret', () => {
    const token = jwt.sign({ userId: 42 }, 'wrong-secret');
    const { req, res, next } = buildMocks({ authHeader: `Bearer ${token}` });
    verifyToken(req, res, next);

    expect(res.statusCode).toBe(401);
    expect(res.body).toEqual({ error: 'Unauthorized' });
    expect(next).not.toHaveBeenCalled();
  });

  test('returns 401 when token is expired', () => {
    const token = jwt.sign({ userId: 42 }, SECRET, { expiresIn: '0s' });
    const { req, res, next } = buildMocks({ authHeader: `Bearer ${token}` });
    verifyToken(req, res, next);

    expect(res.statusCode).toBe(401);
    expect(res.body).toEqual({ error: 'Unauthorized' });
    expect(next).not.toHaveBeenCalled();
  });

  test('attaches req.user and calls next() for a valid token', () => {
    const token = jwt.sign({ userId: 7 }, SECRET);
    const { req, res, next } = buildMocks({ authHeader: `Bearer ${token}` });
    verifyToken(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(req.user).toEqual({ id: 7 });
    expect(res.statusCode).toBeNull(); // no response sent
  });

  test('req.user.id matches the userId embedded in the token', () => {
    const userId = 123;
    const token = jwt.sign({ userId }, SECRET);
    const { req, res, next } = buildMocks({ authHeader: `Bearer ${token}` });
    verifyToken(req, res, next);

    expect(req.user).toEqual({ id: userId });
    expect(next).toHaveBeenCalledTimes(1);
  });
});
