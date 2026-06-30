import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createUser, signToken } from '../lib/auth';
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
  if (password.length < 6) {
    res.status(400).json({ error: 'password must be at least 6 characters' });
    return;
  }

  try {
    const user = await createUser(email, password);
    const token = signToken({ id: user._id.toString(), email: user.email });
    res.status(201).json({
      data: {
        token,
        user: serializeUser(user),
      },
    });
  } catch (err) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Signup failed' });
  }
}
