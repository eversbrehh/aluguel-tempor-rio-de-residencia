import { buildApp } from './app';
import { env } from '@config/env';

const app = buildApp();

app.listen(env.PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`🚀 Monolito LAMD rodando em http://localhost:${env.PORT}${env.API_PREFIX}`);
});
