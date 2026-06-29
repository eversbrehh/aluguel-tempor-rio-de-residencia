import { z } from 'zod';

export const eventEnvelopeSchema = z.object({
  eventId: z.string().uuid(),
  eventType: z.string().min(1),
  occurredAt: z.string(),
  source: z.string().min(1),
  version: z.number().int().positive(),
  payload: z.record(z.unknown()),
});

export type EventEnvelope = z.infer<typeof eventEnvelopeSchema>;
