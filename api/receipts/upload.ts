import type { VercelRequest, VercelResponse } from '@vercel/node';
import { withAuth } from '../lib/middleware';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  return withAuth(req, res, async (authedReq, authedRes) => {
    const { filename } = authedReq.body ?? {};
    if (!filename) {
      authedRes.status(400).json({ error: 'filename required' });
      return;
    }

    // Receipt binary storage deferred — pass receipt_url directly on expense for now
    authedRes.status(200).json({
      data: {
        path: `${authedReq.user.id}/${Date.now()}-${filename}`,
        message: 'Store receipt_url on the expense record directly',
      },
    });
  });
}
