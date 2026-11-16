# ADR-002 — Estorno contábil inverso e imutabilidade de movimentações confirmadas

- **Status:** Aceita
- **Data:** 16/11/2026
- **Decisores:** responsável pelo projeto (autor); validação acadêmica pelo professor/orientador
- **Escopo:** `movimentacao_estoque`, `item_movimentacao`, `sp_estornar_movimentacao` e `trg_item_proteger_confirmado`

## 1. Contexto e problema

Depois de uma movimentação confirmada, a alteração direta dos itens ou a exclusão do registro pode apagar a evidência de quem movimentou, quando, por qual motivo, de qual posição saiu e para onde foi a quantidade. Isso prejudica auditoria, investigação de divergência e reconstrução do saldo. O depósito também precisa corrigir erros operacionais sem reescrever silenciosamente o passado.

## 2. Decisão tomada

Adotar estorno contábil inverso, sem exclusão física do histórico:

- `trg_item_proteger_confirmado` bloqueia `INSERT`, `UPDATE` e `DELETE` de itens vinculados a movimentações `CONFIRMADA` ou `ESTORNADA`;
- `sp_estornar_movimentacao` bloqueia a movimentação original, verifica seu estado e se já existe estorno, cria um cabeçalho do tipo `ESTORNO`, gera itens com origem/destino invertidos e aplica o efeito inverso nos saldos;
- a movimentação original permanece no banco e passa ao estado `ESTORNADA`; o novo estorno é confirmado e referencia a original por `id_movimentacao_referenciada`;
- saldo insuficiente para reverter uma entrada ou transferência faz o estorno falhar, em vez de produzir saldo negativo.

O estorno implementado é integral. Não há estorno parcial nesta versão.

## 3. Alternativas analisadas

### A. Exclusão física (`DELETE`) da operação incorreta

**Motivo do descarte:** elimina o registro operacional e enfraquece a trilha histórica. Também pode ser impedida pelas FKs e pelo próprio princípio de não apagar evidência confirmada.

### B. Edição direta (`UPDATE`) da movimentação e de seus itens

**Motivo do descarte:** modifica retrospectivamente o fato registrado, torna mais difícil explicar a diferença entre saldo original e saldo corrigido e abre espaço para alterações sem registro explícito do motivo corretivo.

### C. Permitir correção por ajuste manual sem referência ao evento original

**Motivo do descarte:** um ajuste pode corrigir o saldo, mas perde a ligação semântica com a operação que causou o erro. O estorno cria vínculo explícito com o movimento original.

## 4. Justificativa teórica

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. **Capítulo 6 — Projeto de arquitetura**. A decisão é estrutural porque define como o sistema preserva estados, histórico e responsabilidades ao longo do ciclo de vida do dado. A preservação do histórico favorece atributos de qualidade relacionados à confiabilidade e à manutenibilidade.

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. **Capítulo 9 — Evolução de software** e **capítulo 25 — Gerenciamento de configuração**. Esses capítulos sustentam a necessidade de manter a capacidade de compreender mudanças ao longo do tempo e preservar versões/estados rastreáveis. A aplicação ao registro financeiro-operacional é uma analogia arquitetural: uma correção deve ser observável e rastreável, não uma substituição silenciosa do estado anterior.

A obra não é citada como prescrição literal de “estorno contábil”; a escolha de estorno é uma decisão de domínio para garantir histórico e reconciliação.

## 5. Consequências positivas

- O registro original continua disponível para auditoria.
- Cada correção cria evento e motivo identificáveis.
- É possível localizar qual movimentação foi estornada.
- A imutabilidade reduz alterações acidentais ou retroativas em operações concluídas.
- O saldo é recomposto pelo procedimento inverso, sujeito às validações e constraints existentes.
- Um segundo estorno da mesma operação é bloqueado.

## 6. Riscos e consequências negativas

- O volume de registros aumenta porque correções adicionam eventos em vez de apagar linhas.
- O estorno integral pode não ser possível quando uma quantidade de uma entrada original já foi consumida.
- A rotina precisa tratar deadlocks e concorrência ao bloquear cabeçalho e posições de estoque.
- O usuário precisa entender a diferença entre rascunho, confirmação e estorno.
- A auditoria completa depende também de restringir alterações diretas ao cabeçalho de movimentação; a trigger de imutabilidade apresentada protege itens, mas não substitui uma política completa de privilégios e trilha de alterações do cabeçalho.

## 7. Como verificar na prática

1. Registrar uma entrada por `sp_registrar_entrada` e guardar o ID retornado.
2. Consultar `movimentacao_estoque`, `item_movimentacao` e `estoque` antes do estorno.
3. Executar `sp_estornar_movimentacao` para o ID confirmado.
4. Verificar que o cabeçalho original permaneceu e passou a `ESTORNADA`, que o novo registro é `ESTORNO` e referencia o original, e que os itens refletem o movimento inverso.
5. Tentar estornar novamente o ID original e confirmar a rejeição.
6. Tentar alterar ou excluir item de movimentação confirmada e confirmar a exceção.
7. Criar cenário em que o saldo de destino não seja suficiente e verificar que o estorno falha sem deixar operação parcial confirmada.

A suíte atual executa o estorno de uma entrada e testa a rejeição do segundo estorno. Os testes explícitos de imutabilidade e de saldo insuficiente devem ser adicionados para fechar a cobertura da decisão.

## 8. Referências

- SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. Cap. 6 — Projeto de arquitetura; cap. 9 — Evolução de software; cap. 25 — Gerenciamento de configuração.
- PRESSMAN, Roger S.; MAXIM, Bruce R. *Engenharia de software: uma abordagem profissional*. 9. ed. Porto Alegre: AMGH, 2021.
