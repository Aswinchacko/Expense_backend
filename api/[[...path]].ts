import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from './lib/handler';
import { routeRequest } from './lib/router';

function pathSegments(req: VercelRequest): string[] {
  const raw = req.query.path;
  if (raw == null) return [];
  const segments = Array.isArray(raw) ? raw : [raw];
  return segments.flatMap((segment) => segment.split('/').filter(Boolean));
}

async function handler(req: VercelRequest, res: VercelResponse) {
  if (pathSegments(req).length === 0 && req.method === 'GET') {
    res.status(200).json({ ok: true, service: 'folio-api' });
    return;
  }
  await routeRequest(req, res);
}

export default createApiHandler(handler);
