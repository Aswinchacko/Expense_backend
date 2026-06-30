import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticateWithGoogle, signToken } from '../lib/auth';
import { createApiHandler } from '../lib/handler';
import { serializeUser } from '../lib/serialize';

export default createApiHandler(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  let body: Record<string, unknown> | undefined;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    res.status(400).json({ error: 'Invalid JSON body' });
    return;
  }
  const id_token = body?.id_token;
  if (typeof id_token !== 'string' || !id_token) {
    res.status(400).json({ error: 'id_token required' });
    return;
  }

  try {
    const user = await authenticateWithGoogle(id_token);
    const token = signToken({ id: user._id.toString(), email: user.email });
    res.status(200).json({ data: { token, user: serializeUser(user) } });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Google auth failed';
    const status = message.startsWith('Missing env:') ? 500 : 401;
    res.status(status).json({ error: message });
  }
});
