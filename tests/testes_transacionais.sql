-- 4. SCRIPT DE TESTE
-- Execute em banco de desenvolvimento. O bloco cria dados de teste e demonstra
-- cenários positivos e negativos. Cada teste negativo captura a exceção esperada.

BEGIN;

INSERT INTO funcionario
(nome,cpf,cargo,data_admissao,data_desligamento,ativo)
VALUES
('Ana Estoquista','11111111111','Estoquista',CURRENT_DATE - 100,NULL,TRUE),
('Bruno Inativo','22222222222','Auxiliar',CURRENT_DATE - 200,CURRENT_DATE - 1,FALSE);

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
