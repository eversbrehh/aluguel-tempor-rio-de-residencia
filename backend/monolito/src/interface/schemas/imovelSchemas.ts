import { z } from 'zod';

export const criarImovelSchema = z.object({
  titulo: z.string().min(2),
  endereco: z.string().min(5),
  descricao: z.string().optional(),
  valorAluguel: z.number().nonnegative().optional(),
});

export const associarComodatarioSchema = z.object({
  comodatarioEmail: z.string().email(),
  dataInicio: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato YYYY-MM-DD'),
  dataFim: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato YYYY-MM-DD')
    .optional(),
});

export type CriarImovelDTO = z.infer<typeof criarImovelSchema>;
export type AssociarComodatarioDTO = z.infer<typeof associarComodatarioSchema>;

export const encerrarAssociacaoSchema = z.object({
  dataFim: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato YYYY-MM-DD')
    .optional(),
});

export type EncerrarAssociacaoDTO = z.infer<typeof encerrarAssociacaoSchema>;
