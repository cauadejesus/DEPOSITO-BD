/*
===============================================================================
CONTROLE DE ESTOQUE - DEPOSITO DE PIZZARIA
SGBD: PostgreSQL 14+
Script completo: DDL, constraints, triggers, procedures e testes.
Executar em um banco de testes vazio, com usuario autorizado a criar objetos.
===============================================================================
*/

BEGIN;

-- 1. TABELAS E CONSTRAINTS
-- Funcionário ativo é representado por ativo BOOLEAN, conforme requisito.
CREATE TABLE funcionario (
    id_funcionario BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    email VARCHAR(150) UNIQUE,
    telefone VARCHAR(20),
    cargo VARCHAR(60) NOT NULL,
    data_admissao DATE NOT NULL,
    data_desligamento DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_funcionario_datas CHECK (
        (ativo = TRUE AND data_desligamento IS NULL)
        OR (ativo = FALSE AND data_desligamento IS NOT NULL)
    ),
    CONSTRAINT ck_funcionario_desligamento CHECK (
        data_desligamento IS NULL OR data_desligamento >= data_admissao
    )
);

CREATE TABLE categoria_produto (
    id_categoria BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome VARCHAR(60) NOT NULL UNIQUE,
    descricao VARCHAR(200)
);

CREATE TABLE classe_armazenamento (
    id_classe BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    descricao VARCHAR(150)
);

CREATE TABLE tipo_local_armazenamento (
    id_tipo_local BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo VARCHAR(25) NOT NULL UNIQUE,
    descricao VARCHAR(150)
);

-- Associativa que resolve N:N entre classe exigida pelo produto e tipo de local.
CREATE TABLE compatibilidade_armazenamento (
    id_classe BIGINT NOT NULL REFERENCES classe_armazenamento(id_classe)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_tipo_local BIGINT NOT NULL REFERENCES tipo_local_armazenamento(id_tipo_local)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    observacao VARCHAR(200),
    PRIMARY KEY (id_classe, id_tipo_local)
);

CREATE TABLE produto (
    id_produto BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_categoria BIGINT NOT NULL REFERENCES categoria_produto(id_categoria)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_classe BIGINT NOT NULL REFERENCES classe_armazenamento(id_classe)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    sku VARCHAR(30) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    unidade_estoque VARCHAR(8) NOT NULL,
    perecivel BOOLEAN NOT NULL DEFAULT FALSE,
    controla_validade BOOLEAN NOT NULL DEFAULT FALSE,
    temperatura_min_c NUMERIC(5,2) NOT NULL,
    temperatura_max_c NUMERIC(5,2) NOT NULL,
    -- Quantos kg físicos equivalem a uma unidade da unidade_estoque.
    peso_equivalente_kg NUMERIC(12,6) NOT NULL,
    estoque_minimo NUMERIC(14,3) NOT NULL DEFAULT 0,
    ponto_reposicao NUMERIC(14,3) NOT NULL DEFAULT 0,
    quantidade_reposicao NUMERIC(14,3) NOT NULL DEFAULT 0,
    dias_alerta_validade INTEGER NOT NULL DEFAULT 7,
    politica_saida VARCHAR(5) NOT NULL DEFAULT 'PVPS',
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_produto_unidade CHECK
        (unidade_estoque IN ('KG','G','L','ML','UN','PCT')),
    CONSTRAINT ck_produto_temperatura CHECK
        (temperatura_min_c <= temperatura_max_c),
    CONSTRAINT ck_produto_peso CHECK (peso_equivalente_kg > 0),
    CONSTRAINT ck_produto_parametros CHECK (
        estoque_minimo >= 0
        AND ponto_reposicao >= estoque_minimo
        AND quantidade_reposicao >= 0
        AND dias_alerta_validade >= 0
    ),
    CONSTRAINT ck_produto_validade CHECK
        (NOT controla_validade OR perecivel),
    CONSTRAINT ck_produto_politica CHECK
        (politica_saida IN ('PEPS','PVPS'))
);

CREATE TABLE fornecedor (
    id_fornecedor BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    razao_social VARCHAR(120) NOT NULL,
    documento VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    email VARCHAR(150),
    nome_contato VARCHAR(100),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_fornecedor_documento CHECK (length(documento) IN (11,14))
);

CREATE TABLE local_armazenamento (
    id_local BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_local BIGINT NOT NULL
        REFERENCES tipo_local_armazenamento(id_tipo_local)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nome VARCHAR(80) NOT NULL,
    temperatura_min_c NUMERIC(5,2) NOT NULL,
    temperatura_max_c NUMERIC(5,2) NOT NULL,
    capacidade_kg NUMERIC(14,3) NOT NULL,
    status_operacional VARCHAR(15) NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT ck_local_temperatura CHECK
        (temperatura_min_c <= temperatura_max_c),
    CONSTRAINT ck_local_capacidade CHECK (capacidade_kg > 0),
    CONSTRAINT ck_local_status CHECK
        (status_operacional IN ('ATIVO','INTERDITADO','INATIVO'))
);

CREATE TABLE lote (
    id_lote BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_fornecedor BIGINT NOT NULL REFERENCES fornecedor(id_fornecedor)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    codigo_lote VARCHAR(50) NOT NULL,
    data_fabricacao DATE,
    data_validade DATE,
    recebido_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(12) NOT NULL DEFAULT 'LIBERADO',
    CONSTRAINT uq_lote_produto_codigo UNIQUE (id_produto, codigo_lote),
    CONSTRAINT ck_lote_datas CHECK (
        data_validade IS NULL OR data_fabricacao IS NULL
        OR data_validade >= data_fabricacao
    ),
    CONSTRAINT ck_lote_status CHECK
        (status IN ('LIBERADO','BLOQUEADO','DESCARTADO'))
);

-- Um saldo por combinação lote/local. A quantidade é expressa na unidade do produto.
CREATE TABLE estoque (
    id_estoque BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lote BIGINT NOT NULL REFERENCES lote(id_lote)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_local BIGINT NOT NULL REFERENCES local_armazenamento(id_local)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    quantidade_atual NUMERIC(14,3) NOT NULL DEFAULT 0,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_estoque_lote_local UNIQUE (id_lote,id_local),
    CONSTRAINT ck_estoque_quantidade CHECK (quantidade_atual >= 0)
);

CREATE TABLE movimentacao_estoque (
    id_movimentacao BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_funcionario BIGINT NOT NULL REFERENCES funcionario(id_funcionario)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    tipo VARCHAR(20) NOT NULL,
    status VARCHAR(12) NOT NULL DEFAULT 'RASCUNHO',
    data_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo VARCHAR(300) NOT NULL,
    documento_ref VARCHAR(80),
    id_movimentacao_referenciada BIGINT UNIQUE
        REFERENCES movimentacao_estoque(id_movimentacao)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    confirmada_em TIMESTAMPTZ,
    CONSTRAINT ck_mov_tipo CHECK (tipo IN (
        'ENTRADA','CONSUMO','PERDA','TRANSFERENCIA',
        'AJUSTE_ENTRADA','AJUSTE_SAIDA','ESTORNO'
    )),
    CONSTRAINT ck_mov_status CHECK
        (status IN ('RASCUNHO','CONFIRMADA','ESTORNADA')),
    CONSTRAINT ck_mov_referencia_estorno CHECK (
        (tipo = 'ESTORNO' AND id_movimentacao_referenciada IS NOT NULL)
        OR (tipo <> 'ESTORNO' AND id_movimentacao_referenciada IS NULL)
    )
);

CREATE TABLE item_movimentacao (
    id_item_movimentacao BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_movimentacao BIGINT NOT NULL
        REFERENCES movimentacao_estoque(id_movimentacao)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    numero_item INTEGER NOT NULL,
    id_estoque_origem BIGINT REFERENCES estoque(id_estoque)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_estoque_destino BIGINT REFERENCES estoque(id_estoque)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    quantidade NUMERIC(14,3) NOT NULL,
    CONSTRAINT uq_item_mov_numero UNIQUE (id_movimentacao,numero_item),
    CONSTRAINT ck_item_quantidade CHECK (quantidade > 0),
    CONSTRAINT ck_item_origem_destino CHECK (
        id_estoque_origem IS NOT NULL OR id_estoque_destino IS NOT NULL
    ),
    CONSTRAINT ck_item_estoques_diferentes CHECK (
        id_estoque_origem IS NULL OR id_estoque_destino IS NULL
        OR id_estoque_origem <> id_estoque_destino
    )
);

CREATE TABLE registro_temperatura (
    id_registro BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_local BIGINT NOT NULL REFERENCES local_armazenamento(id_local)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    id_funcionario BIGINT NOT NULL REFERENCES funcionario(id_funcionario)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    temperatura_observada NUMERIC(5,2) NOT NULL,
    registrada_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacao VARCHAR(300),
    acao_tomada VARCHAR(300)
);

CREATE INDEX idx_lote_produto_validade
    ON lote(id_produto,data_validade,recebido_em);
CREATE INDEX idx_estoque_local ON estoque(id_local);
CREATE INDEX idx_mov_funcionario_data
    ON movimentacao_estoque(id_funcionario,data_hora);
CREATE INDEX idx_item_origem ON item_movimentacao(id_estoque_origem);
CREATE INDEX idx_item_destino ON item_movimentacao(id_estoque_destino);
CREATE INDEX idx_temperatura_local_data
    ON registro_temperatura(id_local,registrada_em);

-- 2. TRIGGERS

-- 2.1 Funcionário ativo em INSERT ou UPDATE de movimentação.
CREATE OR REPLACE FUNCTION fn_validar_funcionario_ativo()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_ativo BOOLEAN;
BEGIN
    SELECT ativo INTO v_ativo
    FROM funcionario
    WHERE id_funcionario = NEW.id_funcionario
    FOR KEY SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Funcionário % não encontrado.', NEW.id_funcionario
            USING ERRCODE = 'foreign_key_violation';
    END IF;

    IF v_ativo IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION
            'Movimentação bloqueada: funcionário % está inativo.',
            NEW.id_funcionario
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_mov_funcionario_ativo
BEFORE INSERT OR UPDATE
ON movimentacao_estoque
FOR EACH ROW EXECUTE FUNCTION fn_validar_funcionario_ativo();

-- Também impede mudar status para inativo enquanto houver operação em andamento
-- vinculada ao funcionário. Histórico confirmado pode continuar associado a ele.
CREATE OR REPLACE FUNCTION fn_proteger_funcionario_em_movimentacao()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.ativo = TRUE AND NEW.ativo = FALSE
       AND EXISTS (
           SELECT 1 FROM movimentacao_estoque m
           WHERE m.id_funcionario = OLD.id_funcionario
             AND m.status = 'RASCUNHO'
       ) THEN
        RAISE EXCEPTION
            'Não é possível inativar o funcionário: há movimentação em rascunho.';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_funcionario_inativacao
BEFORE UPDATE OF ativo ON funcionario
FOR EACH ROW EXECUTE FUNCTION fn_proteger_funcionario_em_movimentacao();

-- 2.2 Validação de validade obrigatória no lote.
CREATE OR REPLACE FUNCTION fn_validar_lote()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_controla_validade BOOLEAN;
BEGIN
    SELECT controla_validade INTO v_controla_validade
    FROM produto WHERE id_produto = NEW.id_produto;

    IF v_controla_validade AND NEW.data_validade IS NULL THEN
        RAISE EXCEPTION
            'Lote do produto % exige data de validade.',
            NEW.id_produto USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_lote_validade
BEFORE INSERT OR UPDATE OF id_produto,data_validade
ON lote
FOR EACH ROW EXECUTE FUNCTION fn_validar_lote();

-- 2.3 Compatibilidade e capacidade.
-- O lock FOR UPDATE na linha do LOCAL serializa todas as alterações de saldo
-- daquele local. Assim, duas transações não conseguem consumir a mesma
-- "capacidade livre" ao mesmo tempo (evita write skew/race condition).
CREATE OR REPLACE FUNCTION fn_validar_estoque_local_capacidade()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_id_produto BIGINT;
    v_id_classe BIGINT;
    v_tipo_local BIGINT;
    v_temp_prod_min NUMERIC(5,2);
    v_temp_prod_max NUMERIC(5,2);
    v_temp_local_min NUMERIC(5,2);
    v_temp_local_max NUMERIC(5,2);
    v_capacidade NUMERIC(14,3);
    v_peso_unitario NUMERIC(12,6);
    v_status_local VARCHAR(15);
    v_ocupado_kg NUMERIC(18,6);
    v_novo_peso_kg NUMERIC(18,6);
BEGIN
    SELECT l.id_produto, p.id_classe,
           p.temperatura_min_c, p.temperatura_max_c, p.peso_equivalente_kg
      INTO v_id_produto, v_id_classe,
           v_temp_prod_min, v_temp_prod_max, v_peso_unitario
    FROM lote l
    JOIN produto p ON p.id_produto = l.id_produto
    WHERE l.id_lote = NEW.id_lote;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lote % não encontrado.', NEW.id_lote;
    END IF;

    -- Lock exclusivo da linha do local: todas as entradas/alterações no mesmo
    -- local passam uma de cada vez por esta validação.
    SELECT la.id_tipo_local, la.temperatura_min_c, la.temperatura_max_c,
           la.capacidade_kg, la.status_operacional
      INTO v_tipo_local, v_temp_local_min, v_temp_local_max,
           v_capacidade, v_status_local
    FROM local_armazenamento la
    WHERE la.id_local = NEW.id_local
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Local de armazenamento % não encontrado.', NEW.id_local;
    END IF;

    IF v_status_local <> 'ATIVO'
       AND NEW.quantidade_atual > 0
       AND (
           TG_OP = 'INSERT'
           OR NEW.quantidade_atual > OLD.quantidade_atual
           OR NEW.id_local <> OLD.id_local
       ) THEN
        RAISE EXCEPTION
            'Local % não está ativo; entrada ou transferência para este local bloqueada.',
            NEW.id_local;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM compatibilidade_armazenamento c
        WHERE c.id_classe = v_id_classe
          AND c.id_tipo_local = v_tipo_local
    ) THEN
        RAISE EXCEPTION
            'Armazenamento incompatível: produto % não pode ser guardado no local %.',
            v_id_produto, NEW.id_local;
    END IF;

    -- A faixa operacional inteira do local deve estar dentro da faixa
    -- permitida pelo produto. Ajuste a regra se a operação usar outro critério.
    IF v_temp_local_min < v_temp_prod_min
       OR v_temp_local_max > v_temp_prod_max THEN
        RAISE EXCEPTION
            'Temperatura do local % não atende à faixa permitida pelo produto %.',
            NEW.id_local, v_id_produto;
    END IF;

    SELECT COALESCE(SUM(e.quantidade_atual * p.peso_equivalente_kg),0)
      INTO v_ocupado_kg
    FROM estoque e
    JOIN lote l ON l.id_lote = e.id_lote
    JOIN produto p ON p.id_produto = l.id_produto
    WHERE e.id_local = NEW.id_local
      AND (TG_OP = 'INSERT' OR e.id_estoque <> NEW.id_estoque);

    v_novo_peso_kg := NEW.quantidade_atual * v_peso_unitario;

    IF v_ocupado_kg + v_novo_peso_kg > v_capacidade THEN
        RAISE EXCEPTION
            'Capacidade excedida no local %: ocupado %.3f kg + entrada %.3f kg > capacidade %.3f kg.',
            NEW.id_local, v_ocupado_kg, v_novo_peso_kg, v_capacidade
            USING ERRCODE = 'check_violation';
    END IF;

    NEW.atualizado_em := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_estoque_compatibilidade_capacidade
BEFORE INSERT OR UPDATE OF id_lote,id_local,quantidade_atual
ON estoque
FOR EACH ROW EXECUTE FUNCTION fn_validar_estoque_local_capacidade();

-- 2.4 Itens: valida tipo da operação, lotes vencidos e origem/destino.
CREATE OR REPLACE FUNCTION fn_validar_item_movimentacao()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_tipo VARCHAR(20);
    v_id_lote_origem BIGINT;
    v_id_lote_destino BIGINT;
    v_validade DATE;
    v_status_lote VARCHAR(12);
    v_prod_origem BIGINT;
    v_prod_destino BIGINT;
BEGIN
    SELECT tipo INTO v_tipo
    FROM movimentacao_estoque
    WHERE id_movimentacao = NEW.id_movimentacao
    FOR KEY SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Movimentação % não encontrada.', NEW.id_movimentacao;
    END IF;

    IF NEW.id_estoque_origem IS NOT NULL THEN
        SELECT e.id_lote, l.data_validade, l.status, l.id_produto
          INTO v_id_lote_origem, v_validade, v_status_lote, v_prod_origem
        FROM estoque e JOIN lote l ON l.id_lote = e.id_lote
        WHERE e.id_estoque = NEW.id_estoque_origem
        FOR KEY SHARE OF e, l;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Estoque de origem não encontrado.';
        END IF;
    END IF;

    IF NEW.id_estoque_destino IS NOT NULL THEN
        SELECT e.id_lote, l.id_produto
          INTO v_id_lote_destino, v_prod_destino
        FROM estoque e JOIN lote l ON l.id_lote = e.id_lote
        WHERE e.id_estoque = NEW.id_estoque_destino
        FOR KEY SHARE OF e, l;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Estoque de destino não encontrado.';
        END IF;
    END IF;

    IF v_tipo = 'TRANSFERENCIA' THEN
        IF NEW.id_estoque_origem IS NULL OR NEW.id_estoque_destino IS NULL
           OR v_id_lote_origem <> v_id_lote_destino THEN
            RAISE EXCEPTION
                'Transferência exige origem e destino do mesmo lote.';
        END IF;
    ELSIF v_tipo IN ('CONSUMO','PERDA','AJUSTE_SAIDA') THEN
        IF NEW.id_estoque_origem IS NULL OR NEW.id_estoque_destino IS NOT NULL THEN
            RAISE EXCEPTION 'Operação % exige somente estoque de origem.', v_tipo;
        END IF;
    ELSIF v_tipo IN ('ENTRADA','AJUSTE_ENTRADA') THEN
        IF NEW.id_estoque_destino IS NULL OR NEW.id_estoque_origem IS NOT NULL THEN
            RAISE EXCEPTION 'Operação % exige somente estoque de destino.', v_tipo;
        END IF;
    END IF;

    IF v_tipo = 'CONSUMO' THEN
        IF v_validade IS NOT NULL AND v_validade < CURRENT_DATE THEN
            RAISE EXCEPTION
                'Consumo bloqueado: lote % venceu em %; registre PERDA para descarte.',
                v_id_lote_origem, v_validade;
        END IF;
        IF v_status_lote <> 'LIBERADO' THEN
            RAISE EXCEPTION
                'Consumo bloqueado: lote % não está LIBERADO.', v_id_lote_origem;
        END IF;
    END IF;

    IF v_tipo = 'TRANSFERENCIA' AND v_status_lote <> 'LIBERADO' THEN
        RAISE EXCEPTION 'Transferência bloqueada: lote não está LIBERADO.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_item_validar_regras
BEFORE INSERT OR UPDATE ON item_movimentacao
FOR EACH ROW EXECUTE FUNCTION fn_validar_item_movimentacao();

-- 2.5 Impede alteração/exclusão de itens depois de a movimentação ser confirmada.
CREATE OR REPLACE FUNCTION fn_proteger_item_confirmado()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_id_mov BIGINT;
    v_status VARCHAR(12);
BEGIN
    v_id_mov := CASE WHEN TG_OP = 'DELETE'
                     THEN OLD.id_movimentacao ELSE NEW.id_movimentacao END;

    SELECT status INTO v_status
    FROM movimentacao_estoque
    WHERE id_movimentacao = v_id_mov;

    IF v_status IN ('CONFIRMADA','ESTORNADA') THEN
        RAISE EXCEPTION
            'Itens de movimentação confirmada/estornada são imutáveis; use estorno ou ajuste.';
    END IF;

    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_item_proteger_confirmado
BEFORE INSERT OR UPDATE OR DELETE ON item_movimentacao
FOR EACH ROW EXECUTE FUNCTION fn_proteger_item_confirmado();

-- 3. STORED PROCEDURES

-- 3.1 Entrada de lote: cria movimento, encontra/cria saldo e soma quantidade.
CREATE OR REPLACE PROCEDURE sp_registrar_entrada(
    IN p_id_lote BIGINT,
    IN p_id_local BIGINT,
    IN p_quantidade NUMERIC(14,3),
    IN p_id_funcionario BIGINT,
    IN p_motivo VARCHAR(300)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_mov BIGINT;
    v_id_estoque BIGINT;
BEGIN
    IF p_quantidade IS NULL OR p_quantidade <= 0 THEN
        RAISE EXCEPTION 'Quantidade de entrada deve ser maior que zero.';
    END IF;

    PERFORM 1 FROM funcionario
    WHERE id_funcionario = p_id_funcionario AND ativo = TRUE
    FOR KEY SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Funcionário inexistente ou inativo.'; END IF;

    INSERT INTO movimentacao_estoque
        (id_funcionario,tipo,status,motivo)
    VALUES (p_id_funcionario,'ENTRADA','RASCUNHO',p_motivo)
    RETURNING id_movimentacao INTO v_id_mov;

    -- O lock da linha local é adquirido pelo trigger de estoque e serializa
    -- as entradas concorrentes para o mesmo espaço físico.
    INSERT INTO estoque(id_lote,id_local,quantidade_atual)
    VALUES (p_id_lote,p_id_local,0)
    ON CONFLICT (id_lote,id_local) DO NOTHING;

    SELECT id_estoque INTO v_id_estoque
    FROM estoque
    WHERE id_lote = p_id_lote AND id_local = p_id_local
    FOR UPDATE;

    UPDATE estoque
       SET quantidade_atual = quantidade_atual + p_quantidade
     WHERE id_estoque = v_id_estoque;

    INSERT INTO item_movimentacao
        (id_movimentacao,numero_item,id_estoque_destino,quantidade)
    VALUES (v_id_mov,1,v_id_estoque,p_quantidade);

    UPDATE movimentacao_estoque
       SET status = 'CONFIRMADA', confirmada_em = CURRENT_TIMESTAMP
     WHERE id_movimentacao = v_id_mov;
END;
$$;

-- 3.2 Transferência entre locais do mesmo lote.
CREATE OR REPLACE PROCEDURE sp_transferir_lote(
    IN p_id_estoque_origem BIGINT,
    IN p_id_local_destino BIGINT,
    IN p_quantidade NUMERIC(14,3),
    IN p_id_funcionario BIGINT,
    IN p_motivo VARCHAR(300)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_lote BIGINT;
    v_id_local_origem BIGINT;
    v_id_estoque_destino BIGINT;
    v_id_mov BIGINT;
    v_saldo NUMERIC(14,3);
BEGIN
    IF p_quantidade IS NULL OR p_quantidade <= 0 THEN
        RAISE EXCEPTION 'Quantidade de transferência deve ser maior que zero.';
    END IF;

    PERFORM 1 FROM funcionario
    WHERE id_funcionario = p_id_funcionario AND ativo = TRUE
    FOR KEY SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Funcionário inexistente ou inativo.'; END IF;

    SELECT id_lote,id_local,quantidade_atual
      INTO v_id_lote,v_id_local_origem,v_saldo
    FROM estoque
    WHERE id_estoque = p_id_estoque_origem
    FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'Estoque de origem não encontrado.'; END IF;
    IF v_id_local_origem = p_id_local_destino THEN
        RAISE EXCEPTION 'Origem e destino não podem ser o mesmo local.';
    END IF;
    IF v_saldo < p_quantidade THEN
        RAISE EXCEPTION 'Saldo insuficiente para transferência.';
    END IF;

    INSERT INTO estoque(id_lote,id_local,quantidade_atual)
    VALUES (v_id_lote,p_id_local_destino,0)
    ON CONFLICT (id_lote,id_local) DO NOTHING;

    SELECT id_estoque INTO v_id_estoque_destino
    FROM estoque
    WHERE id_lote = v_id_lote AND id_local = p_id_local_destino
    FOR UPDATE;

    INSERT INTO movimentacao_estoque
        (id_funcionario,tipo,status,motivo)
    VALUES (p_id_funcionario,'TRANSFERENCIA','RASCUNHO',p_motivo)
    RETURNING id_movimentacao INTO v_id_mov;

    -- Ordem dos locks: origem e destino são bloqueados antes dos saldos.
    -- Em sistemas com muitas transferências, padronize a ordem dos IDs de estoque
    -- para reduzir risco de deadlock.
    UPDATE estoque SET quantidade_atual = quantidade_atual - p_quantidade
    WHERE id_estoque = p_id_estoque_origem;

    UPDATE estoque SET quantidade_atual = quantidade_atual + p_quantidade
    WHERE id_estoque = v_id_estoque_destino;

    INSERT INTO item_movimentacao
        (id_movimentacao,numero_item,id_estoque_origem,id_estoque_destino,quantidade)
    VALUES (v_id_mov,1,p_id_estoque_origem,v_id_estoque_destino,p_quantidade);

    UPDATE movimentacao_estoque
       SET status = 'CONFIRMADA', confirmada_em = CURRENT_TIMESTAMP
     WHERE id_movimentacao = v_id_mov;
END;
$$;

-- 3.3 Retirada automática PVPS/PEPS.
-- Para validade controlada: menor data_validade primeiro (PVPS).
-- Empate ou produto sem validade: recebido_em mais antigo primeiro (PEPS).
-- FOR UPDATE bloqueia os saldos selecionados; outra baixa concorrente aguarda
-- e, ao prosseguir, reavalia o saldo já atualizado, evitando saldo negativo.
CREATE OR REPLACE PROCEDURE sp_retirar_estoque(
    IN p_id_produto BIGINT,
    IN p_quantidade_desejada NUMERIC(14,3),
    IN p_id_funcionario BIGINT,
    IN p_motivo VARCHAR(300),
    OUT p_id_movimentacao BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    r RECORD;
    v_restante NUMERIC(14,3);
    v_retirar NUMERIC(14,3);
    v_numero INTEGER := 0;
BEGIN
    IF p_quantidade_desejada IS NULL OR p_quantidade_desejada <= 0 THEN
        RAISE EXCEPTION 'Quantidade desejada deve ser maior que zero.';
    END IF;

    PERFORM 1 FROM funcionario
    WHERE id_funcionario = p_id_funcionario AND ativo = TRUE
    FOR KEY SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Funcionário inexistente ou inativo.'; END IF;

    PERFORM 1 FROM produto WHERE id_produto = p_id_produto AND ativo = TRUE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Produto inexistente ou inativo.'; END IF;

    v_restante := p_quantidade_desejada;

    INSERT INTO movimentacao_estoque
        (id_funcionario,tipo,status,motivo)
    VALUES (p_id_funcionario,'CONSUMO','RASCUNHO',p_motivo)
    RETURNING id_movimentacao INTO p_id_movimentacao;

    FOR r IN
        SELECT e.id_estoque,e.quantidade_atual,l.id_lote,
               l.data_validade,l.recebido_em
        FROM estoque e
        JOIN lote l ON l.id_lote = e.id_lote
        JOIN local_armazenamento la ON la.id_local = e.id_local
        WHERE l.id_produto = p_id_produto
          AND l.status = 'LIBERADO'
          AND (l.data_validade IS NULL OR l.data_validade >= CURRENT_DATE)
          AND e.quantidade_atual > 0
          AND la.status_operacional = 'ATIVO'
        ORDER BY l.data_validade ASC NULLS LAST,
                 l.recebido_em ASC,
                 e.id_estoque ASC
        FOR UPDATE OF e
    LOOP
        EXIT WHEN v_restante <= 0;

        v_retirar := LEAST(r.quantidade_atual,v_restante);

        UPDATE estoque
           SET quantidade_atual = quantidade_atual - v_retirar
         WHERE id_estoque = r.id_estoque;

        v_numero := v_numero + 1;
        INSERT INTO item_movimentacao
            (id_movimentacao,numero_item,id_estoque_origem,quantidade)
        VALUES
            (p_id_movimentacao,v_numero,r.id_estoque,v_retirar);

        v_restante := v_restante - v_retirar;
    END LOOP;

    IF v_restante > 0 THEN
        RAISE EXCEPTION
            'Estoque insuficiente ou indisponível para produto %. Solicitado: %, faltante: %.',
            p_id_produto,p_quantidade_desejada,v_restante;
    END IF;

    UPDATE movimentacao_estoque
       SET status = 'CONFIRMADA', confirmada_em = CURRENT_TIMESTAMP
     WHERE id_movimentacao = p_id_movimentacao;
END;
$$;

-- 3.4 Estorno integral de movimentação confirmada.
-- Não apaga o registro original: cria MOVIMENTACAO tipo ESTORNO e itens inversos.
-- Se a operação original foi entrada, o estorno retira do saldo de destino.
-- Se foi consumo/perda, o estorno devolve ao saldo de origem.
-- Se foi transferência, devolve ao local de origem e retira do destino.
CREATE OR REPLACE PROCEDURE sp_estornar_movimentacao(
    IN p_id_movimentacao BIGINT,
    IN p_id_funcionario BIGINT,
    IN p_motivo VARCHAR(300),
    OUT p_id_estorno BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_original movimentacao_estoque%ROWTYPE;
    r RECORD;
    v_numero INTEGER := 0;
    v_saldo NUMERIC(14,3);
BEGIN
    PERFORM 1 FROM funcionario
    WHERE id_funcionario = p_id_funcionario AND ativo = TRUE
    FOR KEY SHARE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Funcionário inexistente ou inativo.'; END IF;

    SELECT * INTO v_original
    FROM movimentacao_estoque
    WHERE id_movimentacao = p_id_movimentacao
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Movimentação % não encontrada.',p_id_movimentacao;
    END IF;
    IF v_original.status <> 'CONFIRMADA' THEN
        RAISE EXCEPTION 'Somente movimentação CONFIRMADA pode ser estornada.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM movimentacao_estoque
        WHERE id_movimentacao_referenciada = p_id_movimentacao
    ) THEN
        RAISE EXCEPTION 'Movimentação % já possui estorno.',p_id_movimentacao;
    END IF;

    INSERT INTO movimentacao_estoque
        (id_funcionario,tipo,status,motivo,id_movimentacao_referenciada)
    VALUES
        (p_id_funcionario,'ESTORNO','RASCUNHO',p_motivo,p_id_movimentacao)
    RETURNING id_movimentacao INTO p_id_estorno;

    FOR r IN
        SELECT id_item_movimentacao,id_estoque_origem,
               id_estoque_destino,quantidade
        FROM item_movimentacao
        WHERE id_movimentacao = p_id_movimentacao
        ORDER BY id_item_movimentacao
    LOOP
        v_numero := v_numero + 1;

        -- Inverte o efeito no saldo: o destino original vira origem do estorno,
        -- e a origem original vira destino do estorno.
        IF r.id_estoque_destino IS NOT NULL THEN
            SELECT quantidade_atual INTO v_saldo
            FROM estoque WHERE id_estoque = r.id_estoque_destino
            FOR UPDATE;

            IF NOT FOUND OR v_saldo < r.quantidade THEN
                RAISE EXCEPTION
                    'Estorno impossível: saldo insuficiente no estoque % para reverter entrada/transferência.',
                    r.id_estoque_destino;
            END IF;

            UPDATE estoque
               SET quantidade_atual = quantidade_atual - r.quantidade
             WHERE id_estoque = r.id_estoque_destino;
        END IF;

        IF r.id_estoque_origem IS NOT NULL THEN
            -- Ao estornar consumo/perda, repõe o saldo no estoque original.
            -- A trigger de capacidade também protege a reposição.
            UPDATE estoque
               SET quantidade_atual = quantidade_atual + r.quantidade
             WHERE id_estoque = r.id_estoque_origem;
        END IF;

        INSERT INTO item_movimentacao
            (id_movimentacao,numero_item,id_estoque_origem,
             id_estoque_destino,quantidade)
        VALUES
            (p_id_estorno,v_numero,r.id_estoque_destino,
             r.id_estoque_origem,r.quantidade);
    END LOOP;

    UPDATE movimentacao_estoque
       SET status = 'ESTORNADA'
     WHERE id_movimentacao = p_id_movimentacao;

    UPDATE movimentacao_estoque
       SET status = 'CONFIRMADA', confirmada_em = CURRENT_TIMESTAMP
     WHERE id_movimentacao = p_id_estorno;
END;
$$;

-- 3.5 Alerta de reposição (saldo disponível, não vencido e em local ativo).
CREATE OR REPLACE VIEW vw_alerta_reposicao AS
SELECT p.id_produto,p.sku,p.nome,
       COALESCE(SUM(e.quantidade_atual),0) AS quantidade_disponivel,
       p.estoque_minimo,p.ponto_reposicao,p.quantidade_reposicao,
       CASE
         WHEN COALESCE(SUM(e.quantidade_atual),0) <= p.estoque_minimo
           THEN 'CRITICO'
         WHEN COALESCE(SUM(e.quantidade_atual),0) <= p.ponto_reposicao
           THEN 'REPOR'
         ELSE 'NORMAL'
       END AS situacao
FROM produto p
LEFT JOIN lote l ON l.id_produto = p.id_produto
LEFT JOIN estoque e ON e.id_lote = l.id_lote
LEFT JOIN local_armazenamento la ON la.id_local = e.id_local
WHERE p.ativo = TRUE
  AND (l.id_lote IS NULL OR (
       l.status = 'LIBERADO'
       AND (l.data_validade IS NULL OR l.data_validade >= CURRENT_DATE)
       AND la.status_operacional = 'ATIVO'))
GROUP BY p.id_produto,p.sku,p.nome,p.estoque_minimo,
         p.ponto_reposicao,p.quantidade_reposicao
HAVING COALESCE(SUM(e.quantidade_atual),0) <= p.ponto_reposicao;

COMMIT;

-- 4. SCRIPT DE TESTE
-- Execute em banco de desenvolvimento. O bloco cria dados de teste e demonstra
-- cenários positivos e negativos. Cada teste negativo captura a exceção esperada.

BEGIN;

INSERT INTO funcionario
(nome,cpf,cargo,data_admissao,ativo)
VALUES
('Ana Estoquista','11111111111','Estoquista',CURRENT_DATE - 100,TRUE),
('Bruno Inativo','22222222222','Auxiliar',CURRENT_DATE - 200,FALSE);

INSERT INTO categoria_produto(nome) VALUES ('Queijos'),('Massas');
INSERT INTO classe_armazenamento(codigo,descricao)
VALUES ('REFRIGERADO','Conservação refrigerada'),
       ('SECO','Armazenamento seco');
INSERT INTO tipo_local_armazenamento(codigo,descricao)
VALUES ('GELADEIRA','Geladeira comercial'),
       ('ESTANTE_SECA','Estante de produtos secos');

INSERT INTO compatibilidade_armazenamento(id_classe,id_tipo_local)
SELECT c.id_classe,t.id_tipo_local
FROM classe_armazenamento c CROSS JOIN tipo_local_armazenamento t
WHERE (c.codigo='REFRIGERADO' AND t.codigo='GELADEIRA')
   OR (c.codigo='SECO' AND t.codigo='ESTANTE_SECA');

INSERT INTO produto
(id_categoria,id_classe,sku,nome,unidade_estoque,perecivel,
 controla_validade,temperatura_min_c,temperatura_max_c,
 peso_equivalente_kg,estoque_minimo,ponto_reposicao,
 quantidade_reposicao,dias_alerta_validade,politica_saida)
SELECT ca.id_categoria,cl.id_classe,'MUS-001','Mussarela','KG',TRUE,
       TRUE,2,8,1,5,10,20,7,'PVPS'
FROM categoria_produto ca,classe_armazenamento cl
WHERE ca.nome='Queijos' AND cl.codigo='REFRIGERADO';

INSERT INTO produto
(id_categoria,id_classe,sku,nome,unidade_estoque,perecivel,
 controla_validade,temperatura_min_c,temperatura_max_c,
 peso_equivalente_kg,estoque_minimo,ponto_reposicao,
 quantidade_reposicao,dias_alerta_validade,politica_saida)
SELECT ca.id_categoria,cl.id_classe,'FAR-001','Farinha','KG',FALSE,
       FALSE,10,30,1,10,20,50,7,'PEPS'
FROM categoria_produto ca,classe_armazenamento cl
WHERE ca.nome='Massas' AND cl.codigo='SECO';

INSERT INTO fornecedor(razao_social,documento)
VALUES ('Fornecedor Teste','12345678000199');

INSERT INTO local_armazenamento
(id_tipo_local,codigo,nome,temperatura_min_c,temperatura_max_c,
 capacidade_kg,status_operacional)
SELECT id_tipo_local,'GEL-01','Geladeira 01',2,5,100,'ATIVO'
FROM tipo_local_armazenamento WHERE codigo='GELADEIRA';

INSERT INTO local_armazenamento
(id_tipo_local,codigo,nome,temperatura_min_c,temperatura_max_c,
 capacidade_kg,status_operacional)
SELECT id_tipo_local,'EST-01','Estante 01',10,25,50,'ATIVO'
FROM tipo_local_armazenamento WHERE codigo='ESTANTE_SECA';

-- Lotes: dois válidos para PVPS e um vencido para testar bloqueio.
INSERT INTO lote(id_produto,id_fornecedor,codigo_lote,data_fabricacao,data_validade)
SELECT p.id_produto,f.id_fornecedor,'MUS-A',CURRENT_DATE-20,CURRENT_DATE+2
FROM produto p CROSS JOIN fornecedor f WHERE p.sku='MUS-001';

INSERT INTO lote(id_produto,id_fornecedor,codigo_lote,data_fabricacao,data_validade)
SELECT p.id_produto,f.id_fornecedor,'MUS-B',CURRENT_DATE-10,CURRENT_DATE+20
FROM produto p CROSS JOIN fornecedor f WHERE p.sku='MUS-001';

INSERT INTO lote(id_produto,id_fornecedor,codigo_lote,data_fabricacao,data_validade)
SELECT p.id_produto,f.id_fornecedor,'MUS-VENCIDO',CURRENT_DATE-40,CURRENT_DATE-1
FROM produto p CROSS JOIN fornecedor f WHERE p.sku='MUS-001';

INSERT INTO lote(id_produto,id_fornecedor,codigo_lote)
SELECT p.id_produto,f.id_fornecedor,'FAR-A'
FROM produto p CROSS JOIN fornecedor f WHERE p.sku='FAR-001';

-- 4.1 SUCESSO: entrada de 8 kg de cada lote válido de mussarela.
CALL sp_registrar_entrada(
    (SELECT id_lote FROM lote WHERE codigo_lote='MUS-A'),
    (SELECT id_local FROM local_armazenamento WHERE codigo='GEL-01'),
    8, (SELECT id_funcionario FROM funcionario WHERE cpf='11111111111'),
    'Recebimento de mussarela - teste'
);
CALL sp_registrar_entrada(
    (SELECT id_lote FROM lote WHERE codigo_lote='MUS-B'),
    (SELECT id_local FROM local_armazenamento WHERE codigo='GEL-01'),
    8, (SELECT id_funcionario FROM funcionario WHERE cpf='11111111111'),
    'Recebimento de mussarela - teste'
);

-- 4.2 ERRO: funcionário inativo não pode criar movimentação.
DO $$
BEGIN
    BEGIN
        INSERT INTO movimentacao_estoque(id_funcionario,tipo,motivo)
        SELECT id_funcionario,'ENTRADA','Teste funcionário inativo'
        FROM funcionario WHERE cpf='22222222222';
        RAISE EXCEPTION 'FALHA NO TESTE: deveria bloquear funcionário inativo.';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: funcionário inativo bloqueado: %',SQLERRM;
    END;
END $$;

-- 4.3 ERRO: mussarela refrigerada não pode entrar em estante seca.
DO $$
DECLARE v_lote BIGINT; v_local BIGINT;
BEGIN
    SELECT id_lote INTO v_lote FROM lote WHERE codigo_lote='MUS-A';
    SELECT id_local INTO v_local FROM local_armazenamento WHERE codigo='EST-01';
    BEGIN
        INSERT INTO estoque(id_lote,id_local,quantidade_atual)
        VALUES (v_lote,v_local,1);
        RAISE EXCEPTION 'FALHA NO TESTE: deveria bloquear local incompatível.';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'FALHA NO TESTE:%' THEN RAISE; END IF;
        RAISE NOTICE 'OK: incompatibilidade bloqueada: %',SQLERRM;
    END;
END $$;

-- 4.4 ERRO: exceder capacidade (reduz capacidade abaixo do saldo existente).
DO $$
DECLARE v_local BIGINT;
BEGIN
    SELECT id_local INTO v_local FROM local_armazenamento WHERE codigo='GEL-01';
    UPDATE local_armazenamento SET capacidade_kg=10 WHERE id_local=v_local;
    BEGIN
        -- A alteração de capacidade em si não recalcula saldos; esta nova entrada
        -- será barrada pela trigger ao ultrapassar os 10 kg.
        CALL sp_registrar_entrada(
            (SELECT id_lote FROM lote WHERE codigo_lote='MUS-B'),
            v_local,5,
            (SELECT id_funcionario FROM funcionario WHERE cpf='11111111111'),
            'Teste de capacidade excedida'
        );
        RAISE EXCEPTION 'FALHA NO TESTE: deveria bloquear capacidade excedida.';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'FALHA NO TESTE:%' THEN RAISE; END IF;
        RAISE NOTICE 'OK: capacidade excedida bloqueada: %',SQLERRM;
    END;
    UPDATE local_armazenamento SET capacidade_kg=100 WHERE id_local=v_local;
END $$;

-- 4.5 ERRO: lote vencido não pode ser consumido; PERDA é permitida.
DO $$
DECLARE v_lote BIGINT; v_local BIGINT; v_estoque BIGINT; v_mov BIGINT;
BEGIN
    SELECT id_lote INTO v_lote FROM lote WHERE codigo_lote='MUS-VENCIDO';
    SELECT id_local INTO v_local FROM local_armazenamento WHERE codigo='GEL-01';
    -- Para testar o bloqueio por validade, cria-se saldo vencido diretamente
    -- apenas no ambiente de teste; a rotina normal deve receber e avaliar lotes.
    INSERT INTO estoque(id_lote,id_local,quantidade_atual)
    VALUES(v_lote,v_local,2) RETURNING id_estoque INTO v_estoque;

    INSERT INTO movimentacao_estoque
        (id_funcionario,tipo,status,motivo,confirmada_em)
    VALUES
        ((SELECT id_funcionario FROM funcionario WHERE cpf='11111111111'),
         'CONSUMO','RASCUNHO','Teste lote vencido',CURRENT_TIMESTAMP)
    RETURNING id_movimentacao INTO v_mov;

    BEGIN
        INSERT INTO item_movimentacao
            (id_movimentacao,numero_item,id_estoque_origem,quantidade)
        VALUES(v_mov,1,v_estoque,1);
        RAISE EXCEPTION 'FALHA NO TESTE: deveria bloquear consumo de vencido.';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'FALHA NO TESTE:%' THEN RAISE; END IF;
        RAISE NOTICE 'OK: consumo de lote vencido bloqueado: %',SQLERRM;
    END;

    -- A mesma baixa é permitida como PERDA (descarte), não como consumo.
    UPDATE movimentacao_estoque SET tipo='PERDA',motivo='Descarte de lote vencido'
    WHERE id_movimentacao=v_mov;
    INSERT INTO item_movimentacao
        (id_movimentacao,numero_item,id_estoque_origem,quantidade)
    VALUES(v_mov,1,v_estoque,1);
    UPDATE estoque SET quantidade_atual=quantidade_atual-1
    WHERE id_estoque=v_estoque;
    UPDATE movimentacao_estoque
       SET status='CONFIRMADA',confirmada_em=CURRENT_TIMESTAMP
     WHERE id_movimentacao=v_mov;
    RAISE NOTICE 'OK: descarte/perda de lote vencido permitido.';
END $$;

-- 4.6 SUCESSO: PVPS retira primeiro MUS-A, cuja validade é mais próxima.
DO $$
DECLARE v_mov BIGINT; v_a BIGINT; v_b BIGINT; v_func BIGINT; v_prod BIGINT;
BEGIN
    SELECT id_estoque INTO v_a
    FROM estoque e JOIN lote l ON l.id_lote=e.id_lote
    WHERE l.codigo_lote='MUS-A';
    SELECT id_estoque INTO v_b
    FROM estoque e JOIN lote l ON l.id_lote=e.id_lote
    WHERE l.codigo_lote='MUS-B';
    SELECT id_funcionario INTO v_func FROM funcionario WHERE cpf='11111111111';
    SELECT id_produto INTO v_prod FROM produto WHERE sku='MUS-001';

    CALL sp_retirar_estoque(v_prod,10,v_func,'Consumo de produção - teste',v_mov);

    IF (SELECT quantidade_atual FROM estoque WHERE id_estoque=v_a) <> 0 THEN
        RAISE EXCEPTION 'FALHA: PVPS deveria consumir primeiro todo MUS-A.';
    END IF;
    IF (SELECT quantidade_atual FROM estoque WHERE id_estoque=v_b) <> 6 THEN
        RAISE EXCEPTION 'FALHA: PVPS deveria retirar 2 kg de MUS-B.';
    END IF;
    RAISE NOTICE 'OK: PVPS executado; movimentação %.',v_mov;
END $$;

-- 4.7 ERRO: CHECK impede saldo negativo.
DO $$
DECLARE v_estoque BIGINT;
BEGIN
    SELECT e.id_estoque INTO v_estoque
    FROM estoque e JOIN lote l ON l.id_lote=e.id_lote
    WHERE l.codigo_lote='MUS-B';
    BEGIN
        UPDATE estoque SET quantidade_atual=-1 WHERE id_estoque=v_estoque;
        RAISE EXCEPTION 'FALHA NO TESTE: CHECK deveria impedir saldo negativo.';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'OK: saldo negativo bloqueado: %',SQLERRM;
    END;
END $$;

-- 4.8 SUCESSO + ERRO: estorna uma entrada confirmada; segundo estorno é barrado.
DO $$
DECLARE v_entrada BIGINT; v_estorno BIGINT; v_func BIGINT;
BEGIN
    SELECT id_funcionario INTO v_func FROM funcionario WHERE cpf='11111111111';

    -- Entrada nova para teste isolado de estorno.
    CALL sp_registrar_entrada(
        (SELECT id_lote FROM lote WHERE codigo_lote='MUS-B'),
        (SELECT id_local FROM local_armazenamento WHERE codigo='GEL-01'),
        1,v_func,'Entrada específica para teste de estorno'
    );

    SELECT id_movimentacao INTO v_entrada
    FROM movimentacao_estoque
    WHERE motivo='Entrada específica para teste de estorno'
    ORDER BY id_movimentacao DESC LIMIT 1;

    CALL sp_estornar_movimentacao(
        v_entrada,v_func,'Correção da entrada de teste',v_estorno
    );

    IF (SELECT status FROM movimentacao_estoque
        WHERE id_movimentacao=v_entrada) <> 'ESTORNADA' THEN
        RAISE EXCEPTION 'FALHA: movimentação original não foi marcada estornada.';
    END IF;

    RAISE NOTICE 'OK: estorno % criado para movimento original %.',v_estorno,v_entrada;

    BEGIN
        CALL sp_estornar_movimentacao(
            v_entrada,v_func,'Tentativa de segundo estorno',v_estorno
        );
        RAISE EXCEPTION 'FALHA NO TESTE: segundo estorno deveria ser bloqueado.';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'FALHA NO TESTE:%' THEN RAISE; END IF;
        RAISE NOTICE 'OK: segundo estorno bloqueado: %',SQLERRM;
    END;
END $$;

-- Inspecione os resultados antes de confirmar os testes.
SELECT * FROM movimentacao_estoque ORDER BY id_movimentacao;
SELECT * FROM estoque ORDER BY id_estoque;
SELECT * FROM vw_alerta_reposicao ORDER BY nome;

-- Os testes são revertidos para não poluir o banco.
ROLLBACK;

-- FIM
