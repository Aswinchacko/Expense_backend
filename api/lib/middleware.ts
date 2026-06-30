import type { VercelRequest, VercelResponse } from '@vercel/node';
import { verifyToken, AuthUser } from './auth';

export type AuthedRequest = VercelRequest & { user: AuthUser; token: string };

export function getBearerToken(req: VercelRequest): string | null {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;
  return header.slice(7);
}

export async function withAuth(
  req: VercelRequest,
  res: VercelResponse,
  handler: (req: AuthedRequest, res: VercelResponse) => Promise<void>
): Promise<void> {
  const token = getBearerToken(req);
  if (!token) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const user = verifyToken(token);
  if (!user) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const authedReq = req as AuthedRequest;
  authedReq.user = user;
  authedReq.token = token;

  try {
    await handler(authedReq, res);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
}
