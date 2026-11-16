# ADR-003 — Compatibilidade física N:N entre classe de produto e tipo de local

- **Status:** Aceita
- **Data:** 16/11/2026
- **Decisores:** responsável pelo projeto (autor); validação acadêmica pelo professor/orientador
- **Escopo:** `classe_armazenamento`, `tipo_local_armazenamento`, `compatibilidade_armazenamento`, `produto`, `local_armazenamento` e `estoque`

## 1. Contexto e problema

Produtos de pizzaria possuem requisitos físicos distintos: alguns exigem refrigeração, outros podem permanecer em local seco. Um local pode ser compatível com várias classes, e uma classe pode ser armazenada em diferentes tipos de local, desde que as condições térmicas e de capacidade sejam atendidas.

Uma FK direta entre produto e local fixaria um produto a um único espaço, dificultando transferências e crescimento do depósito. Uma associação rígida também não representa corretamente a compatibilidade entre a classe de armazenamento e os tipos de local disponíveis.

## 2. Decisão tomada

Modelar compatibilidade como relação N:N por meio de `compatibilidade_armazenamento`, cuja chave primária é composta por (`id_classe`, `id_tipo_local`). O produto referencia sua classe; o local referencia seu tipo. A trigger de estoque verifica o par permitido antes de aceitar a posição de saldo.

Complementar a compatibilidade lógica com:

- faixa `temperatura_min_c`/`temperatura_max_c` no produto;
- faixa operacional no local;
- `peso_equivalente_kg` no produto para converter a unidade de estoque em kg;
- `capacidade_kg` no local;
- lock `FOR UPDATE` na linha do local enquanto a trigger calcula a ocupação e valida a nova quantidade.

A regra térmica implementada exige que a faixa operacional inteira do local esteja contida na faixa permitida pelo produto. A capacidade é calculada somando `quantidade_atual * peso_equivalente_kg` de todos os saldos do local.

## 3. Alternativas analisadas

### A. Relacionamento direto produto → local

**Motivo do descarte:** acopla o cadastro do produto a um espaço específico, dificulta armazenar o mesmo produto em locais diferentes e não representa de forma reutilizável a compatibilidade entre classes e tipos de local.

### B. Campo textual ou lista de tipos compatíveis dentro de produto

**Motivo do descarte:** compromete integridade referencial, dificulta consultas, atualização e validação de pares permitidos, além de gerar duplicação e dependência de convenções textuais.

### C. Permitir qualquer classe em qualquer local e validar apenas na interface

**Motivo do descarte:** deixa o banco sujeito a registros inconsistentes via scripts, integrações ou clientes distintos. Também não resolve disputa concorrente de capacidade.

## 4. Justificativa teórica

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. **Capítulo 5 — Modelagem**. O capítulo trata da representação de entidades, relações e estrutura do domínio. Aplicado ao modelo relacional, a tabela associativa resolve explicitamente a relação N:N sem listas multivaloradas nem dependência de um vínculo estático produto/local.

SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. **Capítulo 6 — Projeto de arquitetura**. A decisão combina estrutura de dados com validações operacionais que influenciam confiabilidade e capacidade de evolução do sistema.

A conversão para kg e a política de lock são escolhas técnicas específicas do domínio e do PostgreSQL. A teoria de modelagem fundamenta a representação; a validação quantitativa e concorrente é derivada dos requisitos físicos definidos para o depósito.

## 5. Consequências positivas

- Compatibilidades podem ser cadastradas e alteradas sem mudar a estrutura de `produto` ou `local_armazenamento`.
- Um produto pode ter saldos em vários locais compatíveis.
- A mesma regra classe/tipo é reaproveitada por vários produtos e locais.
- A validação térmica deixa explícita a relação entre faixa exigida e faixa oferecida.
- A capacidade considera unidades diferentes por meio da conversão para kg.
- O lock da linha do local reduz condições de corrida no cálculo de ocupação.

## 6. Riscos e consequências negativas

- O cadastro inicial da tabela de compatibilidade precisa refletir corretamente a operação real.
- `peso_equivalente_kg` pode ser configurado incorretamente e distorcer a capacidade calculada.
- Uma única faixa mínima/máxima pode não representar operações com sensores, zonas ou variação temporal complexa.
- Lockar o local pode serializar movimentações independentes dentro do mesmo espaço e reduzir vazão.
- Atualizações de saldo em vários locais podem adquirir locks em ordens distintas e gerar deadlocks.
- A regra térmica atual é deliberadamente conservadora; deve ser validada com responsável operacional antes de produção.

## 7. Como verificar na prática

1. Inserir uma classe e um tipo de local sem par em `compatibilidade_armazenamento`; tentar criar saldo de lote dessa classe nesse local e verificar bloqueio.
2. Inserir o par permitido e repetir a inclusão, confirmando o aceite quando temperatura e capacidade também estiverem adequadas.
3. Tentar gravar local cuja faixa operacional extrapole a faixa do produto e confirmar bloqueio.
4. Preencher o local até próximo da capacidade e tentar excedê-la; confirmar rejeição.
5. Executar duas sessões inserindo/transferindo saldos para o mesmo local e verificar serialização do lock e ausência de capacidade excedida.
6. Revisar unidades e `peso_equivalente_kg` com dados de referência do inventário físico.

A suíte atual cobre incompatibilidade e excedente de capacidade em cenário sequencial. Temperatura e concorrência real precisam de testes explícitos adicionais.

## 8. Referências

- SOMMERVILLE, Ian. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018. Cap. 5 — Modelagem; cap. 6 — Projeto de arquitetura.
- PRESSMAN, Roger S.; MAXIM, Bruce R. *Engenharia de software: uma abordagem profissional*. 9. ed. Porto Alegre: AMGH, 2021.
