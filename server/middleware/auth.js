'use strict';

const jwt = require('jsonwebtoken');

/**
 * verifyToken — JWT authentication middleware.
 *
 * Reads the `Authorization: Bearer <token>` header, verifies the token
 * against JWT_SECRET, and attaches `req.user = { id: decoded.userId }`
 * before calling next().
 *
 * Returns 401 JSON if the header is absent, malformed, or the token is
 * invalid / expired.
 */
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = typeof authHeader === 'string'
    ? /^Bearer\s+(\S+)$/i.exec(authHeader)?.[1] : null;

  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    if (!Number.isSafeInteger(decoded.userId) || decoded.userId <= 0) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    req.user = { id: decoded.userId };
    next();
  } catch {
    return res.status(401).json({ error: 'Unauthorized' });
  }
}

module.exports = { verifyToken };
