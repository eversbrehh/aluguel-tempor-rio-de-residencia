import { EventEnvelope } from '@domain/EventEnvelope';

export interface IEventHandler {
  readonly eventType: string;
  handle(event: EventEnvelope): Promise<void>;
}
