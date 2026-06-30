import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from '../lib/handler';
import { handleExpenseById } from '../lib/router';

export default createApiHandler(async (req: VercelRequest, res: VercelResponse) => {
  const id = req.query.id;
  if (!id || Array.isArray(id)) {
    res.status(400).json({ error: 'id required' });
    return;
  }
  await handleExpenseById(req, res, id);
});
