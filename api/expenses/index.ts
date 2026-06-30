import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from '../lib/handler';
import { handleExpensesCreate, handleExpensesList } from '../lib/router';

export default createApiHandler(async (req: VercelRequest, res: VercelResponse) => {
  if (req.method === 'GET') return handleExpensesList(req, res);
  if (req.method === 'POST') return handleExpensesCreate(req, res);
  res.setHeader('Allow', 'GET, POST');
  res.status(405).json({ error: 'Method not allowed' });
});
