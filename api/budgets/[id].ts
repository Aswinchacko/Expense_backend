import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { withAuth } from '../lib/middleware';
import { getCollection, BudgetDoc, CategoryDoc } from '../lib/db';
import { serializeBudget } from '../lib/serialize';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const id = req.query.id as string;
  if (!id) {
    res.status(400).json({ error: 'id required' });
    return;
  }

  if (req.method === 'PATCH') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const budgets = await getCollection<BudgetDoc>('budgets');
      const categories = await getCollection<CategoryDoc>('categories');
      const body = authedReq.body ?? {};

      const updates: Record<string, unknown> = {};
      if (body.category_id !== undefined) updates.categoryId = body.category_id;
      if (body.name !== undefined) updates.name = body.name;
      if (body.amount !== undefined) updates.amount = Number(body.amount);
      if (body.period !== undefined) updates.period = body.period;
      if (body.start_date !== undefined) updates.startDate = body.start_date;

      const result = await budgets.findOneAndUpdate(
        { _id: new ObjectId(id), userId: new ObjectId(authedReq.user.id) },
        { $set: updates },
        { returnDocument: 'after' }
      );

      if (!result) {
        authedRes.status(404).json({ error: 'Not found' });
        return;
      }

      const category = result.categoryId
        ? await categories.findOne({ _id: result.categoryId })
        : null;
      authedRes.status(200).json({ data: serializeBudget(result, category) });
    });
  }

  if (req.method === 'DELETE') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const budgets = await getCollection<BudgetDoc>('budgets');
      await budgets.deleteOne({
        _id: new ObjectId(id),
        userId: new ObjectId(authedReq.user.id),
      });
      authedRes.status(204).end();
    });
  }

  res.setHeader('Allow', 'PATCH, DELETE');
  res.status(405).json({ error: 'Method not allowed' });
}
