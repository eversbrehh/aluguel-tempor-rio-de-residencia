# MS Tarefa (esqueleto)

Microsserviço responsável pelas **tarefas de manutenção** entre proprietário e comodatário.

> **Status:** esqueleto. Implementação completa prevista para a **Sprint 3**.

Sua fila (`tarefas.eventos`) já é declarada e _bindada_ pelo monolito aos eventos:
- `associacao.criada`
- `associacao.encerrada`

Assim, ao iniciar o consumidor nesta sprint futura, os eventos historicamente enviados ficarão disponíveis (até o limite de retenção da fila).
