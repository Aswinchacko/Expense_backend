import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticateUser, signToken } from '../lib/auth';
import { serializeUser } from '../lib/serialize';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { email, password } = req.body ?? {};
  if (!email || !password) {
    res.status(400).json({ error: 'email and password required' });
    return;
  }

  const user = await authenticateUser(email, password);
  if (!user) {
    res.status(401).json({ error: 'Invalid email or password' });
    return;
  }

  const token = signToken({ id: user._id.toString(), email: user.email });
  res.status(200).json({
    data: {
      token,
      user: serializeUser(user),
    },
  });
}
