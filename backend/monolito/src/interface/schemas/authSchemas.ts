import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Senha deve ter ao menos 8 caracteres'),
  nome: z.string().min(2),
  tipo: z.enum(['proprietario', 'comodatario']),
  telefone: z.string().optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export type RegisterDTO = z.infer<typeof registerSchema>;
export type LoginDTO = z.infer<typeof loginSchema>;
