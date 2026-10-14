'use strict';

require('dotenv').config();
const Database = require('better-sqlite3');

const dbFile = process.env.DATABASE_FILE || './grand_line.db';

// Singleton — open once and reuse across all modules
const db = new Database(dbFile);

// Enable WAL mode for better concurrent read performance
db.pragma('journal_mode = WAL');

module.exports = db;
