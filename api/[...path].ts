import type { VercelRequest, VercelResponse } from '@vercel/node';
import { routeRequest } from './lib/router';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    await routeRequest(req, res);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
}
