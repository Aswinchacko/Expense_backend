import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from './lib/handler';
import { handleProfile } from './lib/router';

export default createApiHandler(async (req: VercelRequest, res: VercelResponse) => {
  await handleProfile(req, res);
});
