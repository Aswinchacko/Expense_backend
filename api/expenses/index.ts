import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { withAuth } from '../lib/middleware';
import { getCollection, ExpenseDoc, CategoryDoc } from '../lib/db';
import { ensureSeedCategories, serializeExpense } from '../lib/serialize';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'GET') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      await ensureSeedCategories();
      const expenses = await getCollection<ExpenseDoc>('expenses');
      const categories = await getCollection<CategoryDoc>('categories');
      const userId = new ObjectId(authedReq.user.id);

      const { from, to, category, search, type, page = '1', limit = '50' } = authedReq.query;

      const filter: Record<string, unknown> = { userId };
      if (from || to) {
        const dateFilter: Record<string, string> = {};
        if (from) dateFilter.$gte = String(from);
        if (to) dateFilter.$lte = String(to);
        filter.date = dateFilter;
      }
      if (category) filter.categoryId = String(category);
      if (type) filter.type = String(type);
      if (search) {
        filter.$or = [
          { note: { $regex: String(search), $options: 'i' } },
          { merchant: { $regex: String(search), $options: 'i' } },
        ];
      }

      const pageNum = Math.max(1, parseInt(String(page), 10));
      const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10)));
      const skip = (pageNum - 1) * limitNum;

      const rows = await expenses
        .find(filter)
        .sort({ date: -1, createdAt: -1 })
        .skip(skip)
        .limit(limitNum)
        .toArray();

      const catIds = [...new Set(rows.map((r) => r.categoryId))];
      const cats = await categories.find({ _id: { $in: catIds } }).toArray();
      const catMap = new Map(cats.map((c) => [c._id, c]));

      authedRes.status(200).json({
        data: rows.map((r) => serializeExpense(r, catMap.get(r.categoryId))),
        page: pageNum,
        limit: limitNum,
      });
    });
  }

  if (req.method === 'POST') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      await ensureSeedCategories();
      const expenses = await getCollection<ExpenseDoc>('expenses');
      const categories = await getCollection<CategoryDoc>('categories');
      const body = authedReq.body ?? {};
      const { category_id, amount, currency, type, note, merchant, date, payment_method, receipt_url } = body;

      if (!category_id || !amount || amount <= 0) {
        authedRes.status(400).json({ error: 'category_id and positive amount required' });
        return;
      }

      const doc: ExpenseDoc = {
        _id: new ObjectId(),
        userId: new ObjectId(authedReq.user.id),
        categoryId: category_id,
        amount: Number(amount),
        currency: currency ?? 'USD',
        type: type === 'income' ? 'income' : 'expense',
        note: note ?? undefined,
        merchant: merchant ?? undefined,
        date: date ?? new Date().toISOString().split('T')[0],
        paymentMethod: payment_method ?? undefined,
        receiptUrl: receipt_url ?? undefined,
        createdAt: new Date(),
      };

      await expenses.insertOne(doc);
      const category = await categories.findOne({ _id: category_id });
      authedRes.status(201).json({ data: serializeExpense(doc, category) });
    });
  }

  res.setHeader('Allow', 'GET, POST');
  res.status(405).json({ error: 'Method not allowed' });
}
