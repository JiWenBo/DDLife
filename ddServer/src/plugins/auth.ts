import { FastifyReply, FastifyRequest } from 'fastify';

export type AuthenticatedRequest = FastifyRequest & {
  user: { id: string };
};

export async function authGuard(request: FastifyRequest, reply: FastifyReply) {
  const raw = request.headers.authorization;
  if (!raw?.startsWith('Bearer ')) {
    reply.code(401).send({ message: 'Unauthorized' });
    return;
  }
  const token = raw.replace('Bearer ', '').trim();
  const userId = token || 'demo-user';
  (request as AuthenticatedRequest).user = { id: userId };
}
