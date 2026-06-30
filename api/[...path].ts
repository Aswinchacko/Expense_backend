import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createApiHandler } from './lib/handler';
import { routeRequest } from './lib/router';

export default createApiHandler(routeRequest);
