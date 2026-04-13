import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import OpenAI from 'openai';
import { env } from '../env';
import { authGuard } from '../plugins/auth';

const chatSchema = z.object({
  message: z.string().min(1),
  model: z.string().optional(),
});

export async function aiRoutes(app: FastifyInstance) {
  app.post('/v1/ai/chat', { preHandler: authGuard }, async (request, reply) => {
    const payload = chatSchema.parse(request.body);
    if (!env.openAiApiKey) {
      reply.code(400);
      return { message: 'OPENAI_API_KEY is missing' };
    }
    const client = new OpenAI({ apiKey: env.openAiApiKey });
    const completion = await client.responses.create({
      model: payload.model ?? 'gpt-4o-mini',
      input: payload.message,
    });
    return {
      output: completion.output_text,
      model: completion.model,
      usage: completion.usage,
    };
  });
}
