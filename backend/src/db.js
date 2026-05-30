const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

pool.on('connect', () => {
  console.log('PostgreSQL Database connected successfully');
});

pool.on('error', (err) => {
  console.error('Unexpected database connection error:', err);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
