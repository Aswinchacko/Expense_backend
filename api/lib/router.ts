import { randomUUID } from 'crypto';
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ObjectId } from 'mongodb';
import { createUser, authenticateUser, signToken, getUserById } from './auth';
import { getCollection, ExpenseDoc, CategoryDoc, BudgetDoc, UserDoc } from './db';
import {
  ensureSeedCategories,
  serializeCategory,
  serializeUser,
  serializeExpense,
  serializeBudget,
} from './serialize';
import { withAuth } from './middleware';
import type { AnalyticsSummary } from './types';

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

function parsePath(req: VercelRequest): string[] {
  const raw = req.query.path;
  if (!raw) return [];
  return Array.isArray(raw) ? raw : [raw];
}

async function handleSignup(req: VercelRequest, res: VercelResponse) {
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
    res.status(201).json({ data: { token, user: serializeUser(user) } });
  } catch (err) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Signup failed' });
  }
}

async function handleLogin(req: VercelRequest, res: VercelResponse) {
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
  res.status(200).json({ data: { token, user: serializeUser(user) } });
}

async function handleExpensesList(req: VercelRequest, res: VercelResponse) {
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

async function handleExpensesCreate(req: VercelRequest, res: VercelResponse) {
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

async function handleExpenseById(req: VercelRequest, res: VercelResponse, id: string) {
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
      await expenses.deleteOne({ _id: new ObjectId(id), userId: new ObjectId(authedReq.user.id) });
      authedRes.status(204).end();
    });
  }
  res.setHeader('Allow', 'PATCH, DELETE');
  res.status(405).json({ error: 'Method not allowed' });
}

async function handleCategories(req: VercelRequest, res: VercelResponse) {
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

async function handleBudgetsList(req: VercelRequest, res: VercelResponse) {
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

async function handleBudgetsCreate(req: VercelRequest, res: VercelResponse) {
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
    const category = doc.categoryId ? await categories.findOne({ _id: doc.categoryId }) : null;
    authedRes.status(201).json({ data: serializeBudget(doc, category) });
  });
}

async function handleBudgetById(req: VercelRequest, res: VercelResponse, id: string) {
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
      await budgets.deleteOne({ _id: new ObjectId(id), userId: new ObjectId(authedReq.user.id) });
      authedRes.status(204).end();
    });
  }
  res.setHeader('Allow', 'PATCH, DELETE');
  res.status(405).json({ error: 'Method not allowed' });
}

async function handleProfile(req: VercelRequest, res: VercelResponse) {
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

async function handleAnalyticsSummary(req: VercelRequest, res: VercelResponse) {
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
      .find({ userId, date: { $gte: defaultFrom, $lte: defaultTo } })
      .toArray();

    const catRows = await categories.find().toArray();
    const catMap = new Map(catRows.map((c) => [c._id, c]));

    let income_total = 0;
    let expense_total = 0;
    const categoryMap = new Map<string, { name: string; icon: string; total: number }>();

    for (const row of rows) {
      if (row.type === 'income') {
        income_total += row.amount;
      } else {
        expense_total += row.amount;
        const category = catMap.get(row.categoryId);
        const existing = categoryMap.get(row.categoryId) ?? {
          name: category?.name ?? 'Other',
          icon: category?.icon ?? '📦',
          total: 0,
        };
        existing.total += row.amount;
        categoryMap.set(row.categoryId, existing);
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
      .find({ userId, type: 'expense', date: { $gte: trendStartStr, $lte: defaultTo } })
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

async function handleReceiptUpload(req: VercelRequest, res: VercelResponse) {
  return withAuth(req, res, async (authedReq, authedRes) => {
    const { filename } = authedReq.body ?? {};
    if (!filename) {
      authedRes.status(400).json({ error: 'filename required' });
      return;
    }
    authedRes.status(200).json({
      data: {
        path: `${authedReq.user.id}/${Date.now()}-${filename}`,
        message: 'Store receipt_url on the expense record directly',
      },
    });
  });
}

export async function routeRequest(req: VercelRequest, res: VercelResponse): Promise<void> {
  const path = parsePath(req);
  const method = req.method ?? 'GET';
  const route = path.join('/');

  if (route === 'auth/signup' && method === 'POST') return handleSignup(req, res);
  if (route === 'auth/login' && method === 'POST') return handleLogin(req, res);

  if (route === 'expenses' && method === 'GET') return handleExpensesList(req, res);
  if (route === 'expenses' && method === 'POST') return handleExpensesCreate(req, res);
  if (path[0] === 'expenses' && path.length === 2) return handleExpenseById(req, res, path[1]);

  if (route === 'categories') return handleCategories(req, res);

  if (route === 'budgets' && method === 'GET') return handleBudgetsList(req, res);
  if (route === 'budgets' && method === 'POST') return handleBudgetsCreate(req, res);
  if (path[0] === 'budgets' && path.length === 2) return handleBudgetById(req, res, path[1]);

  if (route === 'profile') return handleProfile(req, res);

  if (route === 'analytics/summary' && method === 'GET') return handleAnalyticsSummary(req, res);

  if (route === 'receipts/upload' && method === 'POST') return handleReceiptUpload(req, res);

  res.status(404).json({ error: `Not found: /api/${route}` });
}
