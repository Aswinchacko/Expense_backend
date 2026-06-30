import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticateWithGoogle, signToken } from '../lib/auth';
import { serializeUser } from '../lib/serialize';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { id_token } = req.body ?? {};
  if (!id_token) {
    res.status(400).json({ error: 'id_token required' });
    return;
  }

  try {
    const user = await authenticateWithGoogle(id_token);
    const token = signToken({ id: user._id.toString(), email: user.email });
    res.status(200).json({ data: { token, user: serializeUser(user) } });
  } catch (err) {
    console.error(err);
    res.status(401).json({ error: err instanceof Error ? err.message : 'Google auth failed' });
  }
}
