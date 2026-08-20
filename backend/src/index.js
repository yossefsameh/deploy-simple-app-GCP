'use strict';

const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 8080;

// Database connection pool (optional – app works without DB)
let pool;
if (process.env.DB_HOST) {
  pool = new Pool({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432', 10),
    database: process.env.DB_NAME || 'appdb',
    user: process.env.DB_USER || 'appuser',
    password: process.env.DB_PASSWORD,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });
}

app.use(express.json());

// CORS – allow the frontend origin
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', process.env.FRONTEND_ORIGIN || '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Hello endpoint
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from the backend API!' });
});

// DB info endpoint
app.get('/api/db-status', async (req, res) => {
  if (!pool) {
    return res.json({ connected: false, reason: 'DB_HOST not configured' });
  }
  try {
    const result = await pool.query('SELECT NOW() AS now');
    res.json({ connected: true, serverTime: result.rows[0].now });
  } catch (err) {
    res.status(500).json({ connected: false, error: err.message });
  }
});

const server = app.listen(PORT, () => {
  console.log(`Backend API listening on port ${PORT}`);
});

module.exports = { app, server };
