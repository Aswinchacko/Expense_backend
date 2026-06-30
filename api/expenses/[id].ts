import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { withAuth } from '../lib/middleware';
import { getCollection, ExpenseDoc, CategoryDoc } from '../lib/db';
import { serializeExpense } from '../lib/serialize';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const id = req.query.id as string;
  if (!id) {
    res.status(400).json({ error: 'id required' });
    return;
  }

  if (req.method === 'PATCH') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const expenses = await getCollection<ExpenseDoc>('expenses');
      const categories = await getCollection<CategoryDoc>('categories');
      const body = authedReq.body ?? {};

      const updates: Record<string, unknown> = {};
      if (body.category_id !== undefined) updates.categoryId = body.category_id;
      if (body.amount !== undefined) updates.amount = Number(body.amount);
      if (body.currency !== undefined) updates.currency = body.currency;
      if (body.type !== undefined) updates.type = body.type;
      if (body.note !== undefined) updates.note = body.note;
      if (body.merchant !== undefined) updates.merchant = body.merchant;
      if (body.date !== undefined) updates.date = body.date;
      if (body.payment_method !== undefined) updates.paymentMethod = body.payment_method;
      if (body.receipt_url !== undefined) updates.receiptUrl = body.receipt_url;

      const result = await expenses.findOneAndUpdate(
        { _id: new ObjectId(id), userId: new ObjectId(authedReq.user.id) },
        { $set: updates },
        { returnDocument: 'after' }
      );

      if (!result) {
        authedRes.status(404).json({ error: 'Not found' });
        return;
      }

      const category = await categories.findOne({ _id: result.categoryId });
      authedRes.status(200).json({ data: serializeExpense(result, category) });
    });
  }

  if (req.method === 'DELETE') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const expenses = await getCollection<ExpenseDoc>('expenses');
      await expenses.deleteOne({
        _id: new ObjectId(id),
        userId: new ObjectId(authedReq.user.id),
      });
      authedRes.status(204).end();
    });
  }

  res.setHeader('Allow', 'PATCH, DELETE');
  res.status(405).json({ error: 'Method not allowed' });
}
