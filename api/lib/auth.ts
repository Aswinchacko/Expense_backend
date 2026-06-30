import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { ObjectId } from 'mongodb';
import { getCollection, UserDoc } from './db';

export interface AuthUser {
  id: string;
  email: string;
}

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('Missing env: JWT_SECRET');
  return secret;
}

export function signToken(user: AuthUser): string {
  return jwt.sign({ sub: user.id, email: user.email }, getJwtSecret(), { expiresIn: '30d' });
}

export function verifyToken(token: string): AuthUser | null {
  try {
    const payload = jwt.verify(token, getJwtSecret()) as { sub: string; email: string };
    return { id: payload.sub, email: payload.email };
  } catch {
    return null;
  }
}

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export async function createUser(email: string, password: string): Promise<UserDoc> {
  const users = await getCollection<UserDoc>('users');
  const existing = await users.findOne({ email: email.toLowerCase() });
  if (existing) throw new Error('Email already registered');

  const passwordHash = await hashPassword(password);
  const doc: UserDoc = {
    _id: new ObjectId(),
    email: email.toLowerCase(),
    passwordHash,
    displayName: email.split('@')[0],
    currency: 'USD',
    createdAt: new Date(),
  };
  await users.insertOne(doc);
  return doc;
}

export async function authenticateUser(email: string, password: string): Promise<UserDoc | null> {
  const users = await getCollection<UserDoc>('users');
  const user = await users.findOne({ email: email.toLowerCase() });
  if (!user) return null;
  const ok = await verifyPassword(password, user.passwordHash);
  return ok ? user : null;
}

export async function getUserById(id: string): Promise<UserDoc | null> {
  const users = await getCollection<UserDoc>('users');
  try {
    return users.findOne({ _id: new ObjectId(id) });
  } catch {
    return null;
  }
}
