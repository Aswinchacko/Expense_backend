import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from '../lib/handler';
import { handleGoogleAuth } from '../lib/router';

export default createApiHandler(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  await handleGoogleAuth(req, res);
});
