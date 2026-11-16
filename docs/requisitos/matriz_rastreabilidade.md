# Matriz de Rastreabilidade — Requisito → Banco → Teste

Esta matriz estabelece a ligação entre regras do domínio, mecanismos do PostgreSQL e evidências de teste. O código de teste abaixo representa a seção/caso na suíte `tests/testes_transacionais.sql`; “lacuna” significa que a regra existe no DDL, mas ainda não tem cenário explícito na suíte atual.

| ID | Requisito / regra | Objeto de implementação | Evidência de teste atual | Situação |
|---|---|---|---|---|
| RN-01 | A movimentação deve ter funcionário existente e ativo. | FK `movimentacao_estoque.id_funcionario`; trigger `trg_mov_funcionario_ativo`. | Caso 4.2: tenta inserir movimentação de funcionário inativo. | Coberto |
| RN-02 | Funcionário com movimentação em rascunho não pode ser inativado. | `trg_funcionario_inativacao`. | Não há caso explícito na suíte atual. | Implementado; teste pendente |
| RN-03 | Produto e tipo de local devem ser compatíveis. | `compatibilidade_armazenamento`; trigger `trg_estoque_compatibilidade_capacidade`. | Caso 4.3: mussarela em estante seca. | Coberto |
| RN-04 | A faixa operacional do local deve respeitar a faixa permitida pelo produto. | `produto.temperatura_min_c/max_c`; `local_armazenamento.temperatura_min_c/max_c`; trigger de estoque. | Não há caso explícito na suíte atual. | Implementado; teste pendente |
| RN-05 | A ocupação do local, convertida para kg, não pode superar `capacidade_kg`. | `peso_equivalente_kg`; `capacidade_kg`; `fn_validar_estoque_local_capacidade` com lock `FOR UPDATE`. | Caso 4.4: entrada adicional excede capacidade. | Coberto em execução sequencial |
| RN-06 | Lote deve ter validade quando o produto está configurado para controlar validade. | `trg_lote_validade`; `fn_validar_lote`. | Não há inserção explícita de lote com validade nula na suíte atual. | Implementado; teste pendente |
| RN-07 | Consumo de lote vencido deve ser bloqueado; descarte deve ser registrado como `PERDA`. | `trg_item_validar_regras`. | Caso 4.5: consumo de vencido rejeitado; `PERDA` aceito. | Coberto |
| RN-08 | Saldo de estoque não pode ficar negativo. | `ck_estoque_quantidade`; procedures com locks e validação de saldo. | Caso 4.7: tentativa de atualizar quantidade para -1. | Coberto |
| RN-09 | Retirada deve consumir lotes válidos em ordem de validade e recebimento. | `sp_retirar_estoque`; `FOR UPDATE OF e`. | Caso 4.6: verifica consumo do lote com validade mais próxima. | PVPS coberto; PEPS por política configurável pendente |
| RN-10 | Transferência deve usar mesmo lote, origem e destino válidos. | `sp_transferir_lote`; trigger de item e trigger de estoque. | Não há teste dedicado de transferência na suíte atual. | Implementado; teste pendente |
| RN-11 | Itens de movimentação confirmada/estornada são imutáveis. | `trg_item_proteger_confirmado`. | Não há caso explícito de UPDATE/DELETE após confirmação. | Implementado; teste pendente |
| RN-12 | Correção de movimentação confirmada deve preservar original e criar estorno inverso. | `sp_estornar_movimentacao`; UK `id_movimentacao_referenciada`. | Caso 4.8: estorno e tentativa de segundo estorno. | Parcialmente coberto; inversão detalhada e saldo insuficiente pendentes |
| RN-13 | Produto com saldo baixo deve aparecer na consulta de reposição. | `vw_alerta_reposicao`. | Consulta final da suíte; não há asserts para os três estados. | Parcialmente coberto |
| RN-14 | Leituras de temperatura devem registrar local, funcionário, valor e data. | `registro_temperatura`. | Sem teste de inserção/consulta explícito na suíte atual. | Estrutura implementada; teste pendente |

## Regras de interpretação

- “Implementado” não significa “testado”: a matriz diferencia objeto existente de evidência executada.
- A suíte atual é transacional, começa com `BEGIN` e termina com `ROLLBACK`; os casos de teste usam dados fictícios.
- `FOR UPDATE` foi conferido no código, mas não representa por si só um teste de concorrência com múltiplas sessões.
- `produto.politica_saida` admite `PEPS` e `PVPS`, porém `sp_retirar_estoque` atualmente ordena por data de validade primeiro e recebimento depois; a seleção independente por configuração de política é uma evolução pendente.
- A view `vw_alerta_reposicao` tem ramo `NORMAL` no `CASE`, mas o filtro `HAVING` limita as linhas às que estão no ponto de reposição ou abaixo. A matriz considera isso como cobertura parcial.
- A regra de validade é acionada por `controla_validade = TRUE`; o cadastro deve habilitar esse controle para todos os perecíveis cuja validade deve ser obrigatória.

## Referência

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. Cap. 4 — Engenharia de requisitos; cap. 8 — Teste de software. A rastreabilidade liga requisito a projeto, implementação e teste, permitindo avaliar o impacto de mudanças.
