import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from '../lib/handler';
import { handleAnalyticsSummary } from '../lib/router';

export default createApiHandler(async (req: VercelRequest, res: VercelResponse) => {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }
  await handleAnalyticsSummary(req, res);
});
