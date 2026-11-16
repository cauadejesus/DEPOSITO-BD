# Plano de Gerenciamento do Projeto — Controle de Estoque de Depósito de Pizzaria

- **Instituição:** Centro Universitário de Brasília — CEUB
- **Disciplina:** Engenharia de Software — Projeto Integrador, Ciclo 2 (2026/2)
- **Modalidade:** Opção B — Projeto pessoal
- **Responsável principal:** aluno/autor do repositório (preencher identificação no documento final da disciplina)
- **Orientação/aceite acadêmico:** professor da disciplina
- **Linha de base:** 26/10/2026 a 23/11/2026
- **Versão do plano:** 1.0 — 16/11/2026

## 1. Propósito e alinhamento acadêmico

Este plano organiza o trabalho necessário para entregar um banco PostgreSQL documentado, testável e recuperável para o controle de estoque de um depósito de pizzaria. O documento segue a organização solicitada no Projeto Integrador do CEUB e conecta atividades, evidências, responsáveis, riscos, qualidade, configuração e encerramento.

O método de avaliação do CEUB ressalta que o MVP é uma etapa, não o trabalho inteiro: devem ser demonstrados o caminho do problema até o sistema, as decisões fundamentadas e as evidências de cada etapa. O critério 6 — Gerenciamento do Projeto Integrador — representa 20% da avaliação (8 dos 40 pontos do Projeto Integrador). A documentação e o repositório são organizados para apoiar especialmente os critérios de jornada, processo/requisitos, projeto, implementação/versionamento, qualidade/testes, gerenciamento e sustentação/encerramento.

O Mapa Mental de Gerenciamento de Projetos é usado como referência de organização nos temas: fundamentos e valor, ciclo de vida, planejamento, riscos, pessoas e equipe, qualidade, configuração e mudanças, abordagens e ferramentas. As cinco etapas abaixo são a estrutura de gestão adotada para este projeto, não uma atribuição literal de fases de Sommerville.

## 2. TAP — Termo de Abertura do Projeto

| Campo | Definição |
|---|---|
| Nome | Sistema de Controle de Estoque para Depósito de Pizzaria |
| Justificativa | Organizar produtos, lotes, fornecedores, locais e movimentações; reduzir inconsistências de saldo e riscos de armazenagem incompatível ou consumo de lote vencido. |
| Problema | O controle de ingredientes requer rastrear validade, lote, capacidade física, temperatura e movimentações; controles manuais ou dispersos dificultam consistência e auditoria. |
| Objetivo geral | Entregar até 23/11/2026 um banco relacional PostgreSQL 14+ documentado, com regras de negócio, modelos conceitual/lógico, SQL, testes e roteiro de sustentação. |
| Objetivos específicos | Modelar o domínio; normalizar o modelo lógico; implementar DDL, constraints, triggers, procedures e view; demonstrar cenários de teste; publicar documentação e release. |
| Patrocinador/autoridade de aceite | Professor/orientador da disciplina, conforme validação acadêmica. |
| Responsável pela execução | Aluno/autor do projeto. |
| Usuários interessados | Estoquista, responsável pelo depósito e gestor da pizzaria como perfis de usuário de referência; a validação com usuário real deve ser registrada se ocorrer. |
| Escopo incluído | Regras de negócio, DER conceitual, DER lógico, dicionário, schema PostgreSQL, movimentações, testes, documentação, versionamento e handover. |
| Escopo opcional | Protótipo Java/JDBC de console, condicionado a banco e documentação aprovados e reserva de correção livre em 19/11. |
| Fora do escopo | Interface gráfica, aplicação web completa, integração fiscal/ERP, compras automatizadas, múltiplas filiais, sensores IoT em tempo real e implantação produtiva sem homologação. |
| Premissas | PostgreSQL 14+ disponível; desenvolvimento individual; dados de teste fictícios; ferramentas gratuitas ou acadêmicas; cerca de 3–4 horas diárias previstas no cronograma original. |
| Restrições | Prazo final 23/11/2026; entregas obrigatórias têm prioridade sobre Java; não usar dados pessoais reais em testes ou versionamento. |
| Critério de sucesso | DDL executável em banco vazio, testes sem falha inesperada, regras críticas demonstráveis, documentação rastreável e aceite/entrega registrados. |

### Marcos de autorização e controle

- 26/10: tema, problema e objetivo definidos; TAP elaborado.
- 27–28/10: EAP, cronograma, riscos, ambiente e ferramentas preparados.
- 17/11: marco obrigatório de banco SQL validado.
- 18/11: documentação e evidências consolidadas.
- 19/11: reserva para correções; Java somente sob condição de prontidão.
- 23/11: apresentação, aceite, lições aprendidas e encerramento.

## 3. Escopo, entregáveis e critérios de aceite

| Entregável | Conteúdo mínimo | Critério de aceite |
|---|---|---|
| Regras de negócio e requisitos | Regras identificadas, numeradas, com condição e resultado esperado | Cada requisito crítico está ligado a modelo, objeto SQL e teste ou lacuna registrada. |
| Modelo conceitual | Entidades principais, relacionamentos e cardinalidades | Coerente com o domínio de lote, estoque e movimentação. |
| Modelo lógico | Tabelas, PK, FK, UK, domínios e normalização | Relações N:N resolvidas e dicionário coerente com o DDL. |
| Script PostgreSQL | DDL, constraints, índices, triggers, procedures e view | Executa em banco vazio PostgreSQL 14+ sem erro. |
| Testes SQL | Casos positivos e negativos dentro de transação | Cenários previstos executados, exceções esperadas identificadas e rollback final. |
| Documentação técnica | README, diagramas, ADRs, matriz de rastreabilidade e plano | Outra pessoa compreende como instalar, executar, testar e retomar o projeto. |
| Release | Tag SemVer e notas de versão | Release publicada após validação, com limitações conhecidas. |
| Java/JDBC opcional | Protótipo de console para cadastro/consulta de produto | Só inicia se o marco SQL, testes e documentação obrigatórios estiverem concluídos. |

## 4. EAP — Estrutura Analítica do Projeto

```text
1. INICIAÇÃO
   1.1 Definir tema, problema e objetivo
   1.2 Elaborar e aprovar Termo de Abertura (TAP)

2. PLANEJAMENTO
   2.1 Montar EAP, datas e dependências
   2.2 Planejar riscos, comunicação e qualidade
   2.3 Preparar SGBD e ferramentas de modelagem

3. EXECUÇÃO
   3.1 Levantar requisitos e regras de negócio
   3.2 Validar regras e fechar escopo
   3.3 Criar modelo conceitual (DER)
   3.4 Revisar e validar modelo conceitual
   3.5 Criar modelo lógico e normalizar
   3.6 Revisar modelo lógico e dicionário
   3.7 Implementar estrutura SQL (DDL)
   3.8 Popular banco e elaborar consultas
   3.9 Testar SQL e regras de negócio
   3.10 Marco: banco SQL validado
   3.11 Consolidar documentação e evidências
   3.12 Reserva para correções
   3.13 Protótipo Java/JDBC (opcional)

4. MONITORAMENTO E CONTROLE (transversal)
   4.1 Acompanhar quadro, prazos e bloqueios
   4.2 Revisar marcos, riscos e mudanças

5. ENCERRAMENTO
   5.1 Apresentar, entregar e obter aceite
   5.2 Registrar lições aprendidas e concluir
```

## 5. Cronograma e dependências

As datas abaixo reproduzem a linha de base do arquivo `Cronograma_Banco_de_Dados(1).xlsx`, adaptando apenas o domínio do tema genérico para o depósito de pizzaria. As datas são marcos de planejamento; o responsável deve atualizar status/avanço no Kanban conforme a evidência realmente produzida.

| ID | Atividade | Etapa | Início | Término | Predecessora | Entregável/critério |
|---|---|---|---|---|---|---|
| 1.1 | Definir tema, problema e objetivo | Iniciação | 26/10 | 26/10 | — | Tema e escopo inicial definidos |
| 1.2 | Elaborar e aprovar TAP | Iniciação | 26/10 | 26/10 | 1.1 | TAP com justificativa, objetivos e aceite |
| 2.1 | Montar EAP, datas e dependências | Planejamento | 27/10 | 27/10 | 1.2 | Plano e cronograma aprovados |
| 2.2 | Planejar riscos, comunicação e qualidade | Planejamento | 27/10 | 27/10 | 2.1 | Riscos e critérios de pronto definidos |
| 2.3 | Preparar SGBD e ferramentas | Planejamento | 28/10 | 28/10 | 2.2 | Ambiente e conexão testados |
| 3.1 | Levantar requisitos e regras de negócio | Execução | 29/10 | 30/10 | 2.3 | Regras RN01…RNn identificadas |
| 3.2 | Validar regras e fechar escopo | Execução | 03/11 | 03/11 | 3.1 | Requisitos revisados |
| 3.3 | Criar modelo conceitual | Execução | 04/11 | 05/11 | 3.2 | Entidades, atributos e cardinalidades |
| 3.4 | Revisar modelo conceitual | Execução | 06/11 | 06/11 | 3.3 | DER coerente com regras |
| 3.5 | Criar modelo lógico e normalizar | Execução | 09/11 | 10/11 | 3.4 | PK/FK e normalização até 3FN |
| 3.6 | Revisar modelo lógico e dicionário | Execução | 11/11 | 11/11 | 3.5 | Dicionário e rastreabilidade atualizados |
| 3.7 | Implementar DDL | Execução | 12/11 | 13/11 | 3.6 | CREATE TABLE, chaves e restrições |
| 3.8 | Popular banco e elaborar consultas | Execução | 16/11 | 16/11 | 3.7 | INSERT, SELECT, JOIN e consultas |
| 3.9 | Testar SQL e regras de negócio | Execução | 17/11 | 17/11 | 3.8 | Testes válidos/inválidos e correções |
| 3.10 | Marco: banco SQL validado | Execução | 17/11 | 17/11 | 3.9 | Sem erro crítico aberto |
| 3.11 | Consolidar documentação e evidências | Execução | 18/11 | 18/11 | 3.10 | Relatório, diagramas, scripts e README |
| 3.12 | Reserva para correções | Execução | 19/11 | 19/11 | 3.11 | Pendências críticas resolvidas |
| 3.13 | Protótipo Java/JDBC (opcional) | Execução | 19/11 | 19/11 | 3.10, 3.11 e reserva livre | Console de cadastro/consulta, se autorizado pelo critério de prontidão |
| 4.1 | Acompanhar quadro e bloqueios | Monitoramento | 26/10 | 23/11 | Paralelo | Atualização diária de status |
| 4.2 | Revisar marcos, riscos e mudanças | Monitoramento | 30/10 | 19/11 | Paralelo | Revisões em 30/10, 06/11, 11/11 e 17/11 |
| 5.1 | Apresentar, entregar e obter aceite | Encerramento | 23/11 | 23/11 | 3.11 e 3.12 (e 3.13 se realizado) | Demonstração e aceite registrados |
| 5.2 | Registrar lições e concluir | Encerramento | 23/11 | 23/11 | 5.1 | Lições e arquivos entregues |

### Caminho de dependência principal

A sequência de dependências obrigatórias é: **1.1 → 1.2 → 2.1 → 2.2 → 2.3 → 3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6 → 3.7 → 3.8 → 3.9 → 3.10 → 3.11 → 3.12 → 5.1 → 5.2**. A atividade 3.13 (Java) não integra o caminho obrigatório e não deve consumir a reserva destinada a correções. Essa sequência é o caminho de dependência planejado no cronograma; deve ser recalculada em ferramenta de gestão se as durações ou predecessoras forem alteradas.

### Prioridade da janela final (16–23/11/2026)

- **16/11:** concluir consultas e dados de demonstração (3.8).
- **17/11:** executar suíte, corrigir falhas e decidir aceite do banco SQL (3.9–3.10).
- **18/11:** consolidar README, diagramas, ADRs e evidências (3.11).
- **19/11:** usar a janela prioritariamente para correções (3.12); Java é descartado se existir qualquer bloqueio ou pendência obrigatória.
- **23/11:** apresentação, aceite, lições e encerramento (5.1–5.2).

As durações de monitoramento são janelas de acompanhamento, não dedicação exclusiva diária. A reserva e o Java opcional ocupam a mesma janela e não devem ser somados como capacidade simultânea.

## 6. Abordagem de desenvolvimento — híbrida, iterativa e incremental

A abordagem combina um plano de referência com entregas pequenas verificáveis. O cronograma define marcos, dependências e critérios de aceite; o Kanban visualiza o fluxo de trabalho e permite reordenar correções sem perder a linha de base.

### Fundamentação

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. **Capítulo 2 — Processos de software** apresenta modelos e atividades de processo, permitindo selecionar uma abordagem coerente com o tipo de projeto. **Capítulo 3 — Desenvolvimento ágil** trata de desenvolvimento incremental, colaboração e resposta a mudanças. A combinação adotada aproveita o planejamento necessário para as entregas acadêmicas e ciclos curtos para validar regras, modelos, SQL e testes.

### Iterações previstas

| Iteração | Período / foco | Entregas observáveis | Critério de passagem |
|---|---|---|---|
| I1 — Jornada e planejamento | 26/10–11/11: problema, regras, requisitos, modelos e plano | TAP, EAP, requisitos, regras, DER conceitual/lógico e dicionário | Professor/autor revisa os modelos; regras essenciais estão rastreadas. |
| I2 — Construção e qualidade | 12/11–17/11: DDL, consultas, procedures, triggers e testes | Script PostgreSQL, dados fictícios, view e suíte transacional | Banco criado em ambiente limpo; testes executam sem falha inesperada. |
| I3 — Entrega e sustentação | 18/11–23/11: documentação, correções, release, handover | README, diagramas, ADRs, rastreabilidade, tag/release, lições | Terceiro consegue retomar; aceite e limitações conhecidos registrados. |

### Rotina Kanban

- Colunas: `A fazer`, `Em andamento`, `Em revisão`, `Concluído` e `Bloqueado`.
- Limite sugerido para execução individual: no máximo 2 cartões em andamento e 1 em revisão.
- Um cartão só passa a `Concluído` depois de conferir seu entregável/critério de aceite.
- Bloqueio deve registrar causa, responsável pela remoção e próxima ação.
- Revisão diária de 10–15 minutos; atualização da porcentagem baseada em evidência, não em estimativa subjetiva.

## 7. Matriz de papéis e responsabilidades — RACI

Legenda: **R** = executa; **A** = responde pelo resultado/decisão final; **C** = consultado; **I** = informado. A configuração abaixo assume projeto pessoal individual. O papel de usuário de referência pode ser exercido por pessoa consultada ou por cenário simulado; não pressupõe entrevista que ainda não tenha ocorrido.

| Atividade | Aluno/autor | Professor/orientador | Revisor/pares (se houver) | Usuário de referência do depósito |
|---|---:|---:|---:|---:|
| Definir problema e TAP | R/A | C | I | C |
| Levantar e priorizar requisitos | R/A | C | C | C |
| Validar regras de negócio | R/A | C | C | C |
| Construir modelos e dicionário | R/A | C | C | C |
| Implementar DDL, triggers e procedures | R/A | I | C | I |
| Preparar e executar testes | R/A | I | C | C |
| Gerenciar riscos e mudanças | R/A | C | C | I |
| Aprovar academicamente marcos e entrega | R | A | I | I |
| Publicar release e handover técnico | R/A | I | C | I |

## 8. Acordo de equipe e comunicação

Como a proposta é individual, o aluno acumula execução e responsabilidade final sobre os artefatos técnicos. O professor orienta e valida os marcos acadêmicos. Se houver colaboradores/revisores, a divisão deve ser registrada no GitHub e na tabela RACI, sem transferir a responsabilidade de o autor explicar qualquer parte do projeto na defesa.

Acordos operacionais:

1. Atualizar o Kanban e o cronograma diariamente em dias de trabalho.
2. Registrar decisões estruturais nos ADRs antes de alterar o desenho.
3. Toda mudança deve indicar motivo, impacto, decisão, teste e arquivo afetado.
4. Commits devem ser pequenos, identificáveis e ligados a uma entrega/issue quando aplicável.
5. Se o prazo apertar, retirar primeiro o protótipo Java opcional, nunca os artefatos obrigatórios ou testes de regra crítica.
6. Riscos altos devem ser comunicados ao professor e tratados antes do próximo marco.

Canais: GitHub Issues para defeitos/mudanças; GitHub Projects ou planilha Kanban para fluxo; reunião/consulta com professor nas revisões de 30/10, 06/11, 11/11 e 17/11; README para instruções estáveis.

## 9. Matriz de riscos

Escala qualitativa: probabilidade e impacto `Baixa`, `Média`, `Alta`. A prioridade resulta da combinação qualitativa; risco alto exige resposta e verificação antes da release.

| ID | Risco / causa | Prob. | Impacto | Estratégia de resposta | Responsável | Indicador de monitoramento |
|---|---|---|---|---|---|---|
| R01 | Deadlock em transferências concorrentes por locks de origem/destino em ordem diferente | Média | Alto | **Mitigar:** padronizar ordem de lock por ID, manter transações curtas, tratar `40P01` com retry controlado e testar duas sessões. | Aluno/autor | Erros SQLSTATE `40P01`, tempo de espera e falhas em teste concorrente. |
| R02 | Divergência entre inventário físico e saldo do banco por entrada/saída não registrada | Alta | Alto | **Prevenir/Mitigar:** inventário cíclico, dupla conferência em ajustes, motivo/documento obrigatório e conciliação por lote/local. | Responsável do depósito (perfil operacional) e aluno no MVP | Diferença absoluta entre contagem física e `quantidade_atual`; quantidade de ajustes. |
| R03 | Falha de implantação por ambiente, permissões ou ordem de execução | Média | Alto | **Mitigar:** testar em banco vazio, fixar PostgreSQL 14+, `ON_ERROR_STOP`, backup prévio e roteiro de restauração. | Aluno/autor | Execuções limpas bem-sucedidas; erros de implantação; último backup válido. |
| R04 | Compatibilidade de classe/local ou faixa térmica cadastrada incorretamente | Média | Alto | **Prevenir:** revisar matriz de compatibilidade e faixas com regra de negócio antes de cadastrar produtos/locais. | Aluno + usuário de referência | Tentativas bloqueadas, inconsistências de temperatura e pendências de cadastro. |
| R05 | Conversão `peso_equivalente_kg` errada, fazendo capacidade parecer livre ou excedida | Média | Alto | **Mitigar:** validar unidade e fator com exemplos pesados/medidos; documentar unidade padrão por produto. | Aluno/autor | Diferença entre peso calculado e peso físico de amostra. |
| R06 | Lote vencido permanecer disponível por configuração incorreta de `controla_validade` | Média | Alto | **Prevenir:** definir obrigatoriamente o indicador para perecíveis sujeitos à validade; revisar cadastro e teste de validade nula. | Aluno/autor | Perecíveis sem controle de validade; lotes sem data quando exigida. |
| R07 | A procedure não alternar PEPS/PVPS conforme `politica_saida` | Alta | Médio | **Mitigar:** registrar a limitação; implementar branch específico por política e testes antes de afirmar suporte completo. | Aluno/autor | Testes separados de PEPS e PVPS por produto; revisão do código da procedure. |
| R08 | Imutabilidade e proteção de inativação não possuírem teste explícito | Média | Médio | **Mitigar:** adicionar casos negativos transacionais e ligá-los aos requisitos na matriz de rastreabilidade. | Aluno/autor | Percentual de requisitos críticos com teste associado; casos ausentes. |
| R09 | Perda de scripts/documentos ou alteração sem trilha | Baixa | Alto | **Prevenir:** commits regulares, push remoto, tags e backup fora do repo. | Aluno/autor | Último push, último backup e tag da release. |
| R10 | Escopo opcional consumir a reserva e atrasar entrega obrigatória | Média | Alto | **Prevenir:** Java só começa se marco SQL e docs obrigatórias estiverem aceitos; abandonar imediatamente se surgir bloqueio. | Aluno/autor | Pendências abertas em 17/11 e status do pacote obrigatório em 18/11. |

## 10. Plano de qualidade e indicadores

A qualidade é construída durante o processo, não apenas no encerramento. A revisão técnica ocorre nos marcos do cronograma e inclui schema, regras, testes, diagramas e instruções de execução.

### Critérios de pronto

- DDL executa em banco vazio PostgreSQL 14+ sem erro.
- Constraints de identidade, relacionamento, unicidade e saldo estão presentes.
- Triggers e procedures correspondem às regras rastreadas.
- Suíte transacional executa e finaliza com `ROLLBACK`.
- Casos conhecidos ainda sem teste explícito estão registrados como lacuna, sem serem declarados cobertos.
- README foi validado por execução real em ambiente limpo por alguém diferente do autor, sempre que possível.
- Diagramas e ADRs refletem a versão do DDL publicada.

### Indicadores

| Indicador | Como medir | Meta da entrega |
|---|---|---|
| Requisitos críticos rastreados | Requisitos críticos com ligação a objeto SQL e teste / total crítico | 100% ligados; lacunas marcadas explicitamente |
| Suíte transacional | Execuções sem falha inesperada | Uma execução limpa antes da release |
| Defeitos críticos abertos | Issues críticas não resolvidas | 0 na release acadêmica |
| Reprodutibilidade | Execução em banco vazio seguindo README | 1 execução bem-sucedida por terceiro |
| Riscos altos sem resposta | Riscos altos sem ação/responsável | 0 sem plano de resposta |
| Documentação atualizada | Arquivos conferidos com DDL e tag | 100% dos artefatos exigidos |

Não declarar cobertura percentual automatizada enquanto não houver ferramenta de cobertura e medição reproduzível.

## 11. Plano de configuração e mudanças

### Itens sob configuração

- Scripts SQL, incluindo schema, rotinas e suite.
- Diagramas Mermaid e modelo lógico editável, se incluído no repositório.
- Regras de negócio, dicionário e matriz de rastreabilidade.
- README, ADRs, cronograma e plano de gestão.
- `.env.example`, `.gitignore` e definição de release.

### Baselines

- **BL-01 — Requisitos/modelos:** versão aprovada das regras, modelo conceitual, lógico e dicionário.
- **BL-02 — Banco SQL:** DDL, triggers, procedures, view e testes executados no marco 17/11.
- **BL-03 — Entrega:** README, diagramas, ADRs, plano de gestão e matriz de rastreabilidade em 18–23/11.
- **BL-REL — Release v1.0.0:** conteúdo marcado por tag Git e notas de versão após os critérios de aceite.

### Fluxo de mudança

1. Registrar issue com descrição, motivo, prioridade e evidência.
2. Identificar requisito, tabela/relacionamento, objeto PL/pgSQL, teste, diagrama e documento afetados.
3. Avaliar impacto em prazo, qualidade, dados existentes e compatibilidade.
4. Decidir aceitar, adiar ou rejeitar; registrar decisão estrutural em ADR quando pertinente.
5. Implementar em branch e commit com mensagem convencional.
6. Executar suíte completa e testes de regressão relevantes.
7. Atualizar matriz de rastreabilidade, diagramas e README.
8. Integrar em `main` após revisão e registrar a nova baseline/tag quando aplicável.

Não editar manualmente o banco de produção sem mudança versionada e backup. Mudanças futuras devem ser entregues como migrations incrementais ordenadas, evitando reexecutar o DDL inicial sobre base já instalada.

## 12. Handover, sustentação e retomada por terceiros

### Roteiro de retomada

1. Clonar o GitHub e conferir tag/release pretendida.
2. Ler este plano e o README; identificar limitações abertas e issues.
3. Conferir PostgreSQL 14+ e preparar `.env` a partir de `.env.example`.
4. Criar banco vazio de desenvolvimento e executar o DDL na ordem descrita.
5. Executar `tests/testes_transacionais.sql` e guardar logs de execução.
6. Abrir diagramas e ADRs para compreender as decisões de dados, concorrência e auditoria.
7. Consultar a matriz de rastreabilidade antes de modificar requisito ou regra crítica.
8. Criar branch, issue e migration para qualquer evolução; nunca alterar o histórico confirmado para corrigir operação.
9. Fazer backup antes de aplicar mudança em ambiente com dados.
10. Atualizar README, riscos, ADRs e versão/release ao concluir.

### Rotina de sustentação

- Verificar logs de erro de procedures e transações abortadas.
- Acompanhar espaço, conexões, backups e resultado da view de reposição.
- Realizar conciliação física periódica por lote/local.
- Verificar registros de temperatura e tratar desvios operacionais.
- Monitorar deadlocks e waits; padronizar ordem dos locks nas transferências.
- Revisar versões do PostgreSQL e compatibilidade antes de atualização.
- Preservar estornos e movimentações históricas.

### Encerramento e aceite

Em 23/11/2026, apresentar problema, processo, decisões, arquitetura, demonstração do banco/testes, limitações conhecidas e roteiro de recuperação. O formato definido pelo método de avaliação prevê apresentação de 15 a 20 minutos, com perguntas individuais. Registrar aceite do professor/orientador, link da release, evidências de execução, pendências transferidas e lições aprendidas. O critério de encerramento é outra pessoa conseguir entender e retomar o sistema com o repositório e a documentação, sem depender de explicação oral do autor.

## 13. Mapeamento dos artefatos A01–A12

O método de avaliação pede um plano simplificado completo (A01 a A12). Como o modelo detalhado desses formulários não está reproduzido integralmente no material disponibilizado, a tabela abaixo é um **mapeamento operacional do projeto** — não uma alegação de que os nomes abaixo sejam títulos oficiais de formulários CEUB.

| Código | Artefato operacional neste projeto | Onde está documentado |
|---|---|---|
| A01 | Termo de Abertura (TAP) | Seção 2 deste plano |
| A02 | Objetivos, escopo e critérios de aceite | Seções 2 e 3 |
| A03 | EAP | Seção 4 |
| A04 | Cronograma e marcos | Seção 5 e arquivo XLSX do cronograma |
| A05 | Dependências e caminho principal | Seção 5 |
| A06 | Papéis e RACI | Seção 7 |
| A07 | Comunicação e acordo de trabalho | Seção 8 |
| A08 | Matriz de riscos | Seção 9 |
| A09 | Plano de qualidade e indicadores | Seção 10 |
| A10 | Configuração, baseline e mudanças | Seção 11 |
| A11 | Monitoramento/Kanban e status | Seções 5, 6 e 10 |
| A12 | Encerramento, release e handover | Seção 12 e README |

## 14. Fundamentação e referências

- SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. Cap. 2 — Processos de software; cap. 3 — Desenvolvimento ágil; cap. 4 — Engenharia de requisitos; cap. 6 — Projeto de arquitetura; cap. 9 — Evolução de software; cap. 22 — Gerenciamento de projetos; cap. 23 — Planejamento de projeto; cap. 25 — Gerenciamento de configuração.
- PRESSMAN, Roger S.; MAXIM, Bruce R. *Engenharia de software: uma abordagem profissional*. 9. ed. Porto Alegre: AMGH, 2021.
- CEUB. *Projeto Integrador — Ciclo 2 (out.–nov.–dez. 2026): Método de Avaliação*. Engenharia de Software, Ciência da Computação, Turma B, 2026/2.
- CEUB. *Caderno de Dinâmicas e Modelos de Entrega*. Aula 8, v. 2.0, especialmente fichas 3, 4, 6, 8 e 9, 2026.
- CEUB. *Mapa Mental — Gerenciamento de Projetos*. Aula 10, 2026.
- `Cronograma_Banco_de_Dados(1).xlsx`, abas Cronograma, Kanban e Plano. Datas e dependências reproduzidas na linha de base do projeto.
