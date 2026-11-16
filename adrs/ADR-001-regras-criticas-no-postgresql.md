# ADR-001 — Centralizar regras críticas de integridade no PostgreSQL

- **Status:** Aceita
- **Data:** 16/11/2026
- **Decisores:** responsável pelo projeto (autor); validação acadêmica pelo professor/orientador
- **Escopo:** schema PostgreSQL 14+, triggers, constraints, stored procedures e locks

## 1. Contexto e problema

O depósito possui regras que não podem depender somente da interface que realiza a operação: movimentação exige funcionário ativo; produto e local precisam ser compatíveis; faixa de temperatura deve atender ao produto; a capacidade física do local não pode ser ultrapassada; lote vencido não pode ser consumido; e saldo não pode ficar negativo. A mesma base pode ser acessada por mais de um cliente SQL ou por uma aplicação futura.

Se cada cliente repetir essas regras, versões diferentes podem validá-las de maneira desigual. Também há risco de duas transações calcularem ao mesmo tempo que existe capacidade/saldo livre e ambas tentarem consumi-lo.

## 2. Decisão tomada

Centralizar as garantias críticas na camada PostgreSQL, utilizando:

- PK, FK, UK, `NOT NULL` e `CHECK` para integridade declarativa;
- triggers para funcionário ativo, proteção contra inativação com rascunho, validade, compatibilidade classe/local, temperatura, capacidade e validação de itens;
- procedures para entrada, transferência, retirada e estorno;
- `SELECT ... FOR UPDATE` em linhas de estoque/local e `FOR KEY SHARE` nas referências que precisam ser protegidas;
- exceções transacionais para impedir confirmação parcial de uma operação inválida.

A aplicação futura deve permanecer responsável pela experiência do usuário, autenticação, autorização de negócio de alto nível e apresentação de mensagens, mas não será a única barreira de integridade. Em produção, o usuário de aplicação deverá ter permissões compatíveis com esse desenho e não poderá contornar livremente as rotinas críticas.

## 3. Alternativas analisadas

### A. Validar exclusivamente na aplicação

**Motivo do descarte:** cada cliente teria de implementar e manter as mesmas regras. Um script administrativo ou uma segunda aplicação poderia gravar dados inválidos sem passar pelas validações da primeira interface. A concorrência também precisaria ser implementada corretamente em todas as aplicações.

### B. Validar em uma camada de serviço intermediária

**Motivo do descarte:** melhora a separação da aplicação, mas não impede que acessos SQL administrativos ou integrações futuras contornem o serviço. Para regras que protegem o próprio saldo relacional, o banco ainda precisa manter constraints e transações.

### C. Centralizar tudo em triggers, sem procedures

**Motivo do descarte:** triggers são adequadas para validar alterações, mas procedimentos explícitos tornam mais claro o contrato de operações compostas, como uma retirada que precisa selecionar saldos, reduzir quantidades, criar itens e confirmar o cabeçalho.

## 4. Justificativa teórica

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. **Capítulo 6 — Projeto de arquitetura**. O capítulo orienta a tratar arquitetura como decisões estruturais que afetam atributos de qualidade e a organização dos componentes. Aplicado ao projeto, colocar as garantias de persistência no SGBD reduz dependência de uma única interface e define um ponto comum de integridade.

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. **Capítulo 7 — Projeto e implementação**. A decisão também aplica o princípio de transformar requisitos em mecanismos concretos de projeto e implementação, selecionando restrições, operações e interfaces de persistência coerentes com o domínio.

A escolha de `FOR UPDATE` é uma decisão técnica específica do PostgreSQL, não uma prescrição literal do livro. A fundamentação acadêmica está na necessidade de uma arquitetura que preserve integridade, consistência e comportamento correto quando componentes operam simultaneamente.

## 5. Consequências positivas

- Regras essenciais permanecem válidas mesmo quando a operação não vem da interface futura.
- Reduz duplicação de validações críticas entre clientes.
- Constraints dão mensagens de falha próximas do dado inválido.
- Procedures tornam operações compostas reproduzíveis e transacionais.
- Locks protegem o saldo e a capacidade contra atualizações concorrentes incompatíveis.
- Os testes SQL podem executar diretamente os contratos do banco.

## 6. Riscos e consequências negativas

- Triggers podem tornar o fluxo menos evidente para quem executa DML diretamente.
- Procedures e funções PL/pgSQL aumentam a responsabilidade de manutenção do schema.
- Locks podem reduzir throughput, gerar espera e produzir deadlocks se a ordem de aquisição não for padronizada.
- Permissões excessivas podem permitir que usuários contornem o desenho; `GRANT`/`REVOKE` precisa ser configurado antes de produção.
- Regras alteradas exigem atualizar DDL, testes, diagrama, matriz de rastreabilidade e documentação.

## 7. Como verificar na prática

1. Executar `sql/controle_estoque_pizzaria_postgresql.sql` em banco PostgreSQL 14+ vazio.
2. Rodar `tests/testes_transacionais.sql` e verificar mensagens `OK` para funcionário inativo, incompatibilidade, capacidade, lote vencido, PVPS, saldo negativo e estorno.
3. Criar testes adicionais para faixa de temperatura, proteção de inativação com rascunho e imutabilidade após confirmação.
4. Abrir duas sessões independentes e tentar retirar simultaneamente o mesmo saldo; verificar que a segunda operação aguarda o lock e não causa saldo negativo.
5. Abrir duas sessões tentando ocupar a mesma capacidade local e demonstrar que o cálculo não permite excedente.
6. Revisar privilégios para garantir que o usuário de aplicação não consiga realizar DML crítico que contorne as procedures.

## 8. Referências

- SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. Cap. 6 — Projeto de arquitetura; cap. 7 — Projeto e implementação.
- PRESSMAN, Roger S.; MAXIM, Bruce R. *Engenharia de software: uma abordagem profissional*. 9. ed. Porto Alegre: AMGH, 2021.
- PostgreSQL Global Development Group. *PostgreSQL Documentation*, capítulos sobre constraints, triggers, PL/pgSQL e explicit locking. Documentação técnica consultada como referência de implementação.
