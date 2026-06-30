import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { withAuth } from '../lib/middleware';
import { getCollection, ExpenseDoc, CategoryDoc } from '../lib/db';
import { ensureSeedCategories } from '../lib/serialize';
import type { AnalyticsSummary } from '../lib/types';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  return withAuth(req, res, async (authedReq, authedRes) => {
    await ensureSeedCategories();
    const expenses = await getCollection<ExpenseDoc>('expenses');
    const categories = await getCollection<CategoryDoc>('categories');
    const userId = new ObjectId(authedReq.user.id);
    const { from, to, days = '30' } = authedReq.query;

    const now = new Date();
    const defaultFrom = from
      ? String(from)
      : new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
    const defaultTo = to ? String(to) : now.toISOString().split('T')[0];

    const rows = await expenses
      .find({
        userId,
        date: { $gte: defaultFrom, $lte: defaultTo },
      })
      .toArray();

    const catRows = await categories.find().toArray();
    const catMap = new Map(catRows.map((c) => [c._id, c]));

    let income_total = 0;
    let expense_total = 0;
    const categoryMap = new Map<string, { name: string; icon: string; total: number }>();

    for (const row of rows) {
      const amt = row.amount;
      if (row.type === 'income') {
        income_total += amt;
      } else {
        expense_total += amt;
        const category = catMap.get(row.categoryId);
        const key = row.categoryId;
        const existing = categoryMap.get(key) ?? {
          name: category?.name ?? 'Other',
          icon: category?.icon ?? '📦',
          total: 0,
        };
        existing.total += amt;
        categoryMap.set(key, existing);
      }
    }

    const by_category = Array.from(categoryMap.entries()).map(([category_id, v]) => ({
      category_id,
      name: v.name,
      icon: v.icon,
      total: v.total,
      percent: expense_total > 0 ? Math.round((v.total / expense_total) * 100) : 0,
    }));
    by_category.sort((a, b) => b.total - a.total);

    const trendDays = Math.min(90, Math.max(7, parseInt(String(days), 10)));
    const trendStart = new Date(now);
    trendStart.setDate(now.getDate() - trendDays);
    const trendStartStr = trendStart.toISOString().split('T')[0];

    const trendRows = await expenses
      .find({
        userId,
        type: 'expense',
        date: { $gte: trendStartStr, $lte: defaultTo },
      })
      .toArray();

    const dailyMap = new Map<string, number>();
    for (const row of trendRows) {
      dailyMap.set(row.date, (dailyMap.get(row.date) ?? 0) + row.amount);
    }

    const trend: { date: string; amount: number }[] = [];
    for (let i = trendDays; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(now.getDate() - i);
      const key = d.toISOString().split('T')[0];
      trend.push({ date: key, amount: dailyMap.get(key) ?? 0 });
    }

    const summary: AnalyticsSummary = {
      balance: income_total - expense_total,
      income_total,
      expense_total,
      by_category,
      trend,
    };

    authedRes.status(200).json({ data: summary });
  });
}
