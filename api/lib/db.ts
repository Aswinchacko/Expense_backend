import { MongoClient, Db, Collection, Document, ObjectId } from 'mongodb';

let client: MongoClient | null = null;
let db: Db | null = null;
function getUri(): string {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Missing env: MONGODB_URI');
  return uri;
}

export async function getDb(): Promise<Db> {
  if (db) return db;
  client = new MongoClient(getUri());
  await client.connect();
  db = client.db();
  return db;
}

export async function getCollection<T extends Document = Document>(name: string): Promise<Collection<T>> {
  const database = await getDb();
  return database.collection<T>(name);
}

export { ObjectId };

export interface UserDoc {
  _id: ObjectId;
  email: string;
  passwordHash: string;
  displayName?: string;
  currency: string;
  avatarUrl?: string;
  createdAt: Date;
}

export interface CategoryDoc {
  _id: string;
  userId: string | null;
  name: string;
  icon: string;
  createdAt: Date;
}

export interface ExpenseDoc {
  _id: ObjectId;
  userId: ObjectId;
  categoryId: string;
  amount: number;
  currency: string;
  type: 'expense' | 'income';
  note?: string;
  merchant?: string;
  date: string;
  paymentMethod?: string;
  receiptUrl?: string;
  createdAt: Date;
}

export interface BudgetDoc {
  _id: ObjectId;
  userId: ObjectId;
  categoryId?: string;
  name: string;
  amount: number;
  period: 'monthly' | 'weekly';
  startDate: string;
  createdAt: Date;
}
