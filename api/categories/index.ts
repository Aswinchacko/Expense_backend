import { randomUUID } from 'crypto';
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { withAuth } from '../lib/middleware';
import { getCollection, CategoryDoc } from '../lib/db';
import { ensureSeedCategories, serializeCategory } from '../lib/serialize';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'GET') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      await ensureSeedCategories();
      const categories = await getCollection<CategoryDoc>('categories');
      const rows = await categories
        .find({ $or: [{ userId: null }, { userId: authedReq.user.id }] })
        .sort({ name: 1 })
        .toArray();
      authedRes.status(200).json({ data: rows.map(serializeCategory) });
    });
  }

  if (req.method === 'POST') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const categories = await getCollection<CategoryDoc>('categories');
      const { name, icon } = authedReq.body ?? {};

      if (!name) {
        authedRes.status(400).json({ error: 'name required' });
        return;
      }

      const doc: CategoryDoc = {
        _id: randomUUID(),
        userId: authedReq.user.id,
        name,
        icon: icon ?? '📦',
        createdAt: new Date(),
      };
      await categories.insertOne(doc);
      authedRes.status(201).json({ data: serializeCategory(doc) });
    });
  }

  res.setHeader('Allow', 'GET, POST');
  res.status(405).json({ error: 'Method not allowed' });
}
