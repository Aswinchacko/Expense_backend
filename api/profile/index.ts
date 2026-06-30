import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { withAuth } from '../lib/middleware';
import { getUserById } from '../lib/auth';
import { serializeUser } from '../lib/serialize';
import { getCollection, UserDoc } from '../lib/db';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'GET') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const user = await getUserById(authedReq.user.id);
      if (!user) {
        authedRes.status(404).json({ error: 'User not found' });
        return;
      }
      authedRes.status(200).json({ data: serializeUser(user) });
    });
  }

  if (req.method === 'PATCH') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const users = await getCollection<UserDoc>('users');
      const { display_name, currency, avatar_url } = authedReq.body ?? {};

      const updates: Record<string, unknown> = {};
      if (display_name !== undefined) updates.displayName = display_name;
      if (currency !== undefined) updates.currency = currency;
      if (avatar_url !== undefined) updates.avatarUrl = avatar_url;

      const result = await users.findOneAndUpdate(
        { _id: new ObjectId(authedReq.user.id) },
        { $set: updates },
        { returnDocument: 'after' }
      );

      if (!result) {
        authedRes.status(404).json({ error: 'User not found' });
        return;
      }
      authedRes.status(200).json({ data: serializeUser(result) });
    });
  }

  res.setHeader('Allow', 'GET, PATCH');
  res.status(405).json({ error: 'Method not allowed' });
}
