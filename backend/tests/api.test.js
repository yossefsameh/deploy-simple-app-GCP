'use strict';

const request = require('supertest');
const { app, server } = require('../src/index');

afterAll(() => {
  server.close();
});

describe('GET /health', () => {
  it('returns 200 with status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});

describe('GET /api/hello', () => {
  it('returns a greeting message', async () => {
    const res = await request(app).get('/api/hello');
    expect(res.status).toBe(200);
    expect(res.body.message).toBeDefined();
    expect(typeof res.body.message).toBe('string');
  });
});

describe('GET /api/db-status', () => {
  it('returns not connected when DB_HOST is unset', async () => {
    delete process.env.DB_HOST;
    const res = await request(app).get('/api/db-status');
    expect(res.status).toBe(200);
    expect(res.body.connected).toBe(false);
  });
});
