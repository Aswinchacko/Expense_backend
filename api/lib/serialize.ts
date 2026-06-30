import { getCollection, CategoryDoc } from './db';

const DEFAULT_CATEGORIES: Omit<CategoryDoc, 'createdAt'>[] = [
  { _id: '00000000-0000-0000-0000-000000000001', userId: null, name: 'Food', icon: '🍔' },
  { _id: '00000000-0000-0000-0000-000000000002', userId: null, name: 'Transport', icon: '🚗' },
  { _id: '00000000-0000-0000-0000-000000000003', userId: null, name: 'Shopping', icon: '🛍️' },
  { _id: '00000000-0000-0000-0000-000000000004', userId: null, name: 'Bills', icon: '📄' },
  { _id: '00000000-0000-0000-0000-000000000005', userId: null, name: 'Entertainment', icon: '🎬' },
  { _id: '00000000-0000-0000-0000-000000000006', userId: null, name: 'Health', icon: '💊' },
  { _id: '00000000-0000-0000-0000-000000000007', userId: null, name: 'Travel', icon: '✈️' },
  { _id: '00000000-0000-0000-0000-000000000008', userId: null, name: 'Salary', icon: '💰' },
  { _id: '00000000-0000-0000-0000-000000000009', userId: null, name: 'Other', icon: '📦' },
];

let seeded = false;

export async function ensureSeedCategories(): Promise<void> {
  if (seeded) return;
  const categories = await getCollection<CategoryDoc>('categories');
  const count = await categories.countDocuments({ userId: null });
  if (count === 0) {
    await categories.insertMany(
      DEFAULT_CATEGORIES.map((c) => ({ ...c, createdAt: new Date() }))
    );
  }
  seeded = true;
}

export function serializeCategory(doc: CategoryDoc) {
  return {
    id: doc._id,
    user_id: doc.userId,
    name: doc.name,
    icon: doc.icon,
    created_at: doc.createdAt.toISOString(),
  };
}

export function serializeUser(doc: { _id: { toString(): string }; email: string; displayName?: string; currency: string; avatarUrl?: string; createdAt: Date }) {
  return {
    id: doc._id.toString(),
    email: doc.email,
    display_name: doc.displayName ?? null,
    currency: doc.currency,
    avatar_url: doc.avatarUrl ?? null,
    created_at: doc.createdAt.toISOString(),
  };
}

export function serializeExpense(
  doc: import('./db').ExpenseDoc,
  category?: CategoryDoc | null
) {
  return {
    id: doc._id.toString(),
    user_id: doc.userId.toString(),
    category_id: doc.categoryId,
    amount: doc.amount,
    currency: doc.currency,
    type: doc.type,
    note: doc.note ?? null,
    merchant: doc.merchant ?? null,
    date: doc.date,
    payment_method: doc.paymentMethod ?? null,
    receipt_url: doc.receiptUrl ?? null,
    created_at: doc.createdAt.toISOString(),
    category: category ? serializeCategory(category) : undefined,
  };
}

export function serializeBudget(
  doc: import('./db').BudgetDoc,
  category?: CategoryDoc | null,
  spent = 0,
  spentPercent = 0
) {
  return {
    id: doc._id.toString(),
    user_id: doc.userId.toString(),
    category_id: doc.categoryId ?? null,
    name: doc.name,
    amount: doc.amount,
    period: doc.period,
    start_date: doc.startDate,
    created_at: doc.createdAt.toISOString(),
    spent,
    spent_percent: spentPercent,
    category: category ? serializeCategory(category) : undefined,
  };
}
