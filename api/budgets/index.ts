import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { withAuth } from '../lib/middleware';
import { getCollection, BudgetDoc, ExpenseDoc, CategoryDoc } from '../lib/db';
import { serializeBudget } from '../lib/serialize';

function getPeriodRange(period: string): { from: string; to: string } {
  const now = new Date();
  if (period === 'weekly') {
    const from = new Date(now);
    from.setDate(now.getDate() - 7);
    return { from: from.toISOString().split('T')[0], to: now.toISOString().split('T')[0] };
  }
  const from = new Date(now.getFullYear(), now.getMonth(), 1);
  const to = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  return { from: from.toISOString().split('T')[0], to: to.toISOString().split('T')[0] };
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'GET') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const budgets = await getCollection<BudgetDoc>('budgets');
      const expenses = await getCollection<ExpenseDoc>('expenses');
      const categories = await getCollection<CategoryDoc>('categories');
      const userId = new ObjectId(authedReq.user.id);

      const rows = await budgets.find({ userId }).sort({ createdAt: -1 }).toArray();

      const enriched = await Promise.all(
        rows.map(async (budget) => {
          const { from, to } = getPeriodRange(budget.period);
          const filter: Record<string, unknown> = {
            userId,
            type: 'expense',
            date: { $gte: from, $lte: to },
          };
          if (budget.categoryId) filter.categoryId = budget.categoryId;

          const expenseRows = await expenses.find(filter).toArray();
          const spent = expenseRows.reduce((sum, e) => sum + e.amount, 0);
          const spentPercent = budget.amount > 0 ? Math.round((spent / budget.amount) * 100) : 0;
          const category = budget.categoryId
            ? await categories.findOne({ _id: budget.categoryId })
            : null;

          return serializeBudget(budget, category, spent, spentPercent);
        })
      );

      authedRes.status(200).json({ data: enriched });
    });
  }

  if (req.method === 'POST') {
    return withAuth(req, res, async (authedReq, authedRes) => {
      const budgets = await getCollection<BudgetDoc>('budgets');
      const categories = await getCollection<CategoryDoc>('categories');
      const { category_id, name, amount, period, start_date } = authedReq.body ?? {};

      if (!name || !amount || amount <= 0) {
        authedRes.status(400).json({ error: 'name and positive amount required' });
        return;
      }

      const doc: BudgetDoc = {
        _id: new ObjectId(),
        userId: new ObjectId(authedReq.user.id),
        categoryId: category_id ?? undefined,
        name,
        amount: Number(amount),
        period: period === 'weekly' ? 'weekly' : 'monthly',
        startDate: start_date ?? new Date().toISOString().split('T')[0],
        createdAt: new Date(),
      };

      await budgets.insertOne(doc);
      const category = doc.categoryId
        ? await categories.findOne({ _id: doc.categoryId })
        : null;
      authedRes.status(201).json({ data: serializeBudget(doc, category) });
    });
  }

  res.setHeader('Allow', 'GET, POST');
  res.status(405).json({ error: 'Method not allowed' });
}
