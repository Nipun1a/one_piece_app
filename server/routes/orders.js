'use strict';

const express = require('express');
const { placeOrder, listOrders } = require('../controllers/orderController');
const { verifyToken } = require('../middleware/auth');

const router = express.Router();

// POST /api/orders — place a new order (authenticated)
router.post('/', verifyToken, placeOrder);

// GET /api/orders — list orders for the authenticated user
router.get('/', verifyToken, listOrders);

module.exports = router;
