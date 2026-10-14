'use strict';

const express = require('express');
const { listProducts, getProduct } = require('../controllers/productController');

const router = express.Router();

// GET /api/products — list all products (optional ?category= and ?search= filters)
router.get('/', listProducts);

// GET /api/products/:id — fetch a single product by id
router.get('/:id', getProduct);

module.exports = router;
