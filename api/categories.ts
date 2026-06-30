import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from './lib/handler';
import { handleCategories } from './lib/router';

export default createApiHandler(async (req: VercelRequest, res: VercelResponse) => {
  await handleCategories(req, res);
});
