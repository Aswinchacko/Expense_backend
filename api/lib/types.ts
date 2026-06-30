export type TransactionType = 'expense' | 'income';

export interface Profile {
  id: string;
  display_name: string | null;
  currency: string;
  avatar_url: string | null;
  created_at: string;
}

export interface Category {
  id: string;
  user_id: string | null;
  name: string;
  icon: string;
  created_at: string;
}

export interface Expense {
  id: string;
  user_id: string;
  category_id: string;
  amount: number;
  currency: string;
  type: TransactionType;
  note: string | null;
  merchant: string | null;
  date: string;
  payment_method: string | null;
  receipt_url: string | null;
  created_at: string;
  category?: Category;
}

export interface Budget {
  id: string;
  user_id: string;
  category_id: string | null;
  name: string;
  amount: number;
  period: 'monthly' | 'weekly';
  start_date: string;
  created_at: string;
  spent?: number;
  spent_percent?: number;
  category?: Category;
}

export interface AnalyticsSummary {
  balance: number;
  income_total: number;
  expense_total: number;
  by_category: { category_id: string; name: string; icon: string; total: number; percent: number }[];
  trend: { date: string; amount: number }[];
}
