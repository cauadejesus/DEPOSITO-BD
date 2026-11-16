# Suíte de Testes SQL

## Objetivo

Demonstrar, em banco PostgreSQL 14+, regras de negócio implementadas por constraints, triggers e procedures. O arquivo `testes_transacionais.sql` cria registros fictícios, executa cenários positivos e negativos e fecha com `ROLLBACK` para não persistir os dados de demonstração.

## Pré-condições

1. O DDL foi instalado sem erros no banco de desenvolvimento.
2. O usuário conectado pode inserir e atualizar dados de teste.
3. O banco não contém os mesmos CPFs/SKUs/códigos utilizados pelo script de teste, pois há constraints de unicidade.
4. A suíte deve ser executada em banco de desenvolvimento, nunca em produção.

## Execução

```bash
psql -h localhost -p 5432 -U postgres -d controle_estoque_pizzaria \
  -v ON_ERROR_STOP=1 -W -f tests/testes_transacionais.sql
```

## Casos contemplados

| Seção no SQL | Cenário | Resultado esperado |
|---|---|---|
| 4.1 | Entradas iniciais de dois lotes válidos | Sucesso |
| 4.2 | Funcionário inativo tenta registrar movimentação | Bloqueio |
| 4.3 | Lote refrigerado tenta ocupar local seco incompatível | Bloqueio |
| 4.4 | Nova entrada ultrapassa capacidade do local | Bloqueio |
| 4.5 | Consumo de lote vencido e descarte por PERDA | Consumo bloqueado; PERDA permitida |
| 4.6 | Retirada de 10 kg de mussarela em dois lotes | PVPS retira primeiro o lote com validade mais próxima |
| 4.7 | Atualização direta tenta saldo negativo | Bloqueio por CHECK |
| 4.8 | Estorno de entrada e repetição do estorno | Primeiro estorno permitido; segundo bloqueado |

## Como interpretar o resultado

As mensagens `NOTICE` com prefixo `OK:` indicam que o script alcançou o resultado esperado naquele caso. Se ocorrer erro fora dos blocos que capturam exceções esperadas, `psql` interromperá a execução por causa de `ON_ERROR_STOP=1`. O `ROLLBACK` final desfaz os registros de teste.

## Lacunas conhecidas

Ainda devem ser adicionados casos para: inativação de funcionário com rascunho; lote com validade nula quando o produto controla validade; faixa térmica incompatível; imutabilidade de item após confirmação; transferência; estorno com saldo insuficiente; registro de temperatura; e concorrência real com duas sessões simultâneas. Não declarar esses casos como cobertos antes de adicionar e executar os testes.
