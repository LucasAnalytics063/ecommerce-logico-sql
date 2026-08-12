-- =====================================================================
-- PROJETO: Modelo Lógico de E-commerce
-- Autor: Lucas Beserra Ribeiro
-- Descrição: Esquema lógico completo com DDL, dados de teste e queries
-- Refinamentos aplicados: Cliente PF/PJ, Pagamento N:N, Entrega c/ rastreio
-- =====================================================================

DROP SCHEMA IF EXISTS ecommerce_logico;
CREATE SCHEMA ecommerce_logico DEFAULT CHARACTER SET utf8mb4;
USE ecommerce_logico;

-- =====================================================================
-- PARTE 1 — DDL (Criação das Tabelas)
-- =====================================================================

-- ---------------------------------------------------------------------
-- CLIENTE (superclasse)
-- Refinamento: tipo_cliente garante exclusividade PF/PJ
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    tipo_cliente    ENUM('PF','PJ') NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    telefone        VARCHAR(20),
    data_cadastro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    endereco        VARCHAR(255) NOT NULL,
    cidade          VARCHAR(100) NOT NULL,
    uf              CHAR(2) NOT NULL
) ENGINE=InnoDB;

-- Subtipo Pessoa Física
CREATE TABLE cliente_pf (
    id_cliente      INT PRIMARY KEY,
    nome_completo   VARCHAR(200) NOT NULL,
    cpf             CHAR(11) NOT NULL UNIQUE,
    data_nascimento DATE NOT NULL,
    CONSTRAINT fk_cpf_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Subtipo Pessoa Jurídica
CREATE TABLE cliente_pj (
    id_cliente      INT PRIMARY KEY,
    razao_social    VARCHAR(200) NOT NULL,
    nome_fantasia   VARCHAR(200),
    cnpj            CHAR(14) NOT NULL UNIQUE,
    CONSTRAINT fk_cpj_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Triggers para garantir exclusividade PF/PJ no banco
DELIMITER $$
CREATE TRIGGER trg_valida_tipo_pf
BEFORE INSERT ON cliente_pf FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(2);
    SELECT tipo_cliente INTO v_tipo FROM cliente WHERE id_cliente = NEW.id_cliente;
    IF v_tipo <> 'PF' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não é do tipo PF.';
    END IF;
END$$

CREATE TRIGGER trg_valida_tipo_pj
BEFORE INSERT ON cliente_pj FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(2);
    SELECT tipo_cliente INTO v_tipo FROM cliente WHERE id_cliente = NEW.id_cliente;
    IF v_tipo <> 'PJ' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente não é do tipo PJ.';
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- FORMA DE PAGAMENTO
-- Refinamento: cliente pode ter múltiplas formas (N:N via associativa)
-- ---------------------------------------------------------------------
CREATE TABLE forma_pagamento (
    id_forma_pagamento  INT AUTO_INCREMENT PRIMARY KEY,
    tipo                ENUM('CARTAO_CREDITO','CARTAO_DEBITO','PIX','BOLETO') NOT NULL,
    descricao           VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE cliente_forma_pagamento (
    id_cliente          INT NOT NULL,
    id_forma_pagamento  INT NOT NULL,
    dados_referencia    VARCHAR(255),
    padrao              BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_cliente, id_forma_pagamento),
    CONSTRAINT fk_cfp_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    CONSTRAINT fk_cfp_forma   FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id_forma_pagamento)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- FORNECEDOR
-- ---------------------------------------------------------------------
CREATE TABLE fornecedor (
    id_fornecedor   INT AUTO_INCREMENT PRIMARY KEY,
    razao_social    VARCHAR(200) NOT NULL,
    cnpj            CHAR(14) NOT NULL UNIQUE,
    contato         VARCHAR(150),
    cidade          VARCHAR(100),
    uf              CHAR(2)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- VENDEDOR
-- Um vendedor pode também ser fornecedor (relação investigada nas queries)
-- ---------------------------------------------------------------------
CREATE TABLE vendedor (
    id_vendedor     INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    cpf             CHAR(11) NOT NULL UNIQUE,
    email           VARCHAR(150),
    cnpj_fornecedor CHAR(14) NULL COMMENT 'Preenchido quando o vendedor também é fornecedor',
    taxa_comissao   DECIMAL(5,2) NOT NULL DEFAULT 5.00
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PRODUTO
-- ---------------------------------------------------------------------
CREATE TABLE produto (
    id_produto      INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(200) NOT NULL,
    descricao       TEXT,
    categoria       VARCHAR(100) NOT NULL,
    valor_unitario  DECIMAL(10,2) NOT NULL,
    id_vendedor     INT NOT NULL,
    CONSTRAINT fk_produto_vendedor FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ESTOQUE
-- Relação entre produto e local de armazenamento
-- ---------------------------------------------------------------------
CREATE TABLE estoque (
    id_estoque      INT AUTO_INCREMENT PRIMARY KEY,
    localizacao     VARCHAR(100) NOT NULL COMMENT 'Ex: Galpão A, Prateleira 3'
) ENGINE=InnoDB;

CREATE TABLE produto_estoque (
    id_produto      INT NOT NULL,
    id_estoque      INT NOT NULL,
    quantidade      INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id_produto, id_estoque),
    CONSTRAINT fk_pe_produto  FOREIGN KEY (id_produto)  REFERENCES produto(id_produto),
    CONSTRAINT fk_pe_estoque  FOREIGN KEY (id_estoque)  REFERENCES estoque(id_estoque)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- FORNECIMENTO (produto x fornecedor)
-- ---------------------------------------------------------------------
CREATE TABLE produto_fornecedor (
    id_produto      INT NOT NULL,
    id_fornecedor   INT NOT NULL,
    preco_custo     DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_produto, id_fornecedor),
    CONSTRAINT fk_pf_produto    FOREIGN KEY (id_produto)    REFERENCES produto(id_produto),
    CONSTRAINT fk_pf_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PEDIDO
-- ---------------------------------------------------------------------
CREATE TABLE pedido (
    id_pedido           INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente          INT NOT NULL,
    id_forma_pagamento  INT NOT NULL,
    data_pedido         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_pedido       ENUM('AGUARDANDO_PAGAMENTO','PAGO','CANCELADO','CONCLUIDO')
                        NOT NULL DEFAULT 'AGUARDANDO_PAGAMENTO',
    valor_frete         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    valor_total         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente)         REFERENCES cliente(id_cliente),
    CONSTRAINT fk_pedido_forma   FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento(id_forma_pagamento)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ITEM DO PEDIDO
-- ---------------------------------------------------------------------
CREATE TABLE item_pedido (
    id_pedido       INT NOT NULL,
    id_produto      INT NOT NULL,
    quantidade      INT NOT NULL DEFAULT 1,
    valor_unitario  DECIMAL(10,2) NOT NULL COMMENT 'Valor no momento da compra (histórico)',
    PRIMARY KEY (id_pedido, id_produto),
    CONSTRAINT fk_ip_pedido  FOREIGN KEY (id_pedido)  REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_ip_produto FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ENTREGA
-- Refinamento: possui status e código de rastreio
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
    id_entrega              INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido               INT NOT NULL UNIQUE,
    codigo_rastreio         VARCHAR(50) UNIQUE,
    status_entrega          ENUM('AGUARDANDO_ENVIO','ENVIADO','EM_TRANSITO','ENTREGUE','EXTRAVIADO')
                            NOT NULL DEFAULT 'AGUARDANDO_ENVIO',
    transportadora          VARCHAR(100),
    data_envio              DATETIME,
    data_entrega_prevista   DATE,
    data_entrega_real       DATETIME,
    CONSTRAINT fk_entrega_pedido FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido) ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================================
-- PARTE 2 — DADOS DE TESTE
-- =====================================================================

INSERT INTO cliente (tipo_cliente, email, telefone, endereco, cidade, uf) VALUES
('PF', 'ana.lima@email.com',      '11999990001', 'Rua das Flores, 10',   'São Paulo',            'SP'),
('PF', 'joao.silva@email.com',    '63999990002', 'Av. Central, 55',      'Palmas',               'TO'),
('PJ', 'contato@techstore.com',   '11988880001', 'Av. Paulista, 1000',   'São Paulo',            'SP'),
('PF', 'carlos.souza@email.com',  '63999990003', 'Rua B, 22',            'Paraíso do Tocantins', 'TO'),
('PJ', 'vendas@distribuidora.com','62988880002', 'Setor Comercial, 300', 'Goiânia',              'GO');

INSERT INTO cliente_pf (id_cliente, nome_completo, cpf, data_nascimento) VALUES
(1, 'Ana Lima',      '11122233344', '1992-03-15'),
(2, 'João Silva',    '22233344455', '1988-07-20'),
(4, 'Carlos Souza',  '33344455566', '1995-11-05');

INSERT INTO cliente_pj (id_cliente, razao_social, nome_fantasia, cnpj) VALUES
(3, 'Tech Store LTDA',         'Tech Store',     '11222333000181'),
(5, 'Distribuidora Norte LTDA','Distrib. Norte', '22333444000192');

INSERT INTO forma_pagamento (tipo, descricao) VALUES
('CARTAO_CREDITO', 'Cartão de Crédito'),
('PIX',            'Pix'),
('BOLETO',         'Boleto Bancário'),
('CARTAO_DEBITO',  'Cartão de Débito');

INSERT INTO cliente_forma_pagamento (id_cliente, id_forma_pagamento, dados_referencia, padrao) VALUES
(1, 1, 'Final 1234', TRUE),
(1, 2, 'chave-pix-ana@email.com', FALSE),
(2, 2, 'chave-pix-joao@email.com', TRUE),
(3, 3, NULL, TRUE),
(3, 1, 'Final 9876', FALSE),
(4, 1, 'Final 5432', TRUE),
(5, 3, NULL, TRUE);

INSERT INTO fornecedor (razao_social, cnpj, contato, cidade, uf) VALUES
('Eletrônicos Brasil LTDA',  '33444555000101', 'compras@eletrobrasil.com', 'São Paulo',  'SP'),
('Moda & Cia LTDA',          '44555666000112', 'fornece@modacia.com',      'Rio de Janeiro', 'RJ'),
('Tech Parts Importação',     '55666777000123', 'sales@techparts.com',      'Campinas',   'SP');

-- Vendedor 3 também é fornecedor (mesmo CNPJ do fornecedor 3 — verificado nas queries)
INSERT INTO vendedor (nome, cpf, email, cnpj_fornecedor, taxa_comissao) VALUES
('Ricardo Mendes', '44455566677', 'ricardo@loja.com',  NULL,             8.00),
('Fernanda Costa', '55566677788', 'fernanda@loja.com', NULL,             6.50),
('Tech Parts ME',  '66677788899', 'vendas@techparts.com','55666777000123', 5.00);

INSERT INTO produto (nome, descricao, categoria, valor_unitario, id_vendedor) VALUES
('Smartphone XZ Pro',    'Celular 128GB, câmera 50MP',       'Eletrônicos', 2499.90, 1),
('Fone Bluetooth Max',   'Fone over-ear, 40h de bateria',    'Eletrônicos',  349.90, 1),
('Camiseta Premium',     'Algodão 100%, diversos tamanhos',  'Vestuário',     89.90, 2),
('Tênis Corrida Ultra',  'Solado amortecedor, leve',         'Vestuário',    459.90, 2),
('Cabo USB-C 2m',        'Carregamento rápido 65W',          'Acessórios',    49.90, 3),
('Carregador 65W GaN',   'Tecnologia GaN, bivolt',           'Eletrônicos',  199.90, 3);

INSERT INTO estoque (localizacao) VALUES
('Galpão A - Eletrônicos'),
('Galpão B - Vestuário'),
('Galpão C - Acessórios');

INSERT INTO produto_estoque (id_produto, id_estoque, quantidade) VALUES
(1, 1, 150), (2, 1, 300), (3, 2, 500), (4, 2, 200),
(5, 3, 1000),(6, 1, 250);

INSERT INTO produto_fornecedor (id_produto, id_fornecedor, preco_custo) VALUES
(1, 1, 1800.00), (2, 1,  220.00),
(3, 2,   45.00), (4, 2,  230.00),
(5, 3,   18.00), (6, 3,  110.00);

INSERT INTO pedido (id_cliente, id_forma_pagamento, status_pedido, valor_frete, valor_total) VALUES
(1, 1, 'CONCLUIDO',          19.90,  2869.70),
(1, 2, 'PAGO',               0.00,    349.90),
(2, 2, 'CONCLUIDO',          15.00,   474.90),
(3, 3, 'AGUARDANDO_PAGAMENTO',0.00,  2499.90),
(4, 1, 'CONCLUIDO',          12.00,   261.90),
(5, 3, 'PAGO',               0.00,   249.80),
(2, 2, 'CANCELADO',          15.00,   459.90);

INSERT INTO item_pedido (id_pedido, id_produto, quantidade, valor_unitario) VALUES
(1, 1, 1, 2499.90), (1, 3, 2,  89.90),
(2, 2, 1,  349.90),
(3, 4, 1,  459.90),
(4, 1, 1, 2499.90),
(5, 5, 2,   49.90), (5, 3, 2,  89.90),
(6, 5, 3,   49.90), (6, 6, 1, 199.90),
(7, 4, 1,  459.90);

INSERT INTO entrega (id_pedido, codigo_rastreio, status_entrega, transportadora, data_envio, data_entrega_prevista, data_entrega_real) VALUES
(1, 'BR100000001SP', 'ENTREGUE',    'Correios',  '2026-07-10', '2026-07-15', '2026-07-14 14:30:00'),
(2, 'BR100000002SP', 'EM_TRANSITO', 'JadLog',    '2026-08-05', '2026-08-10', NULL),
(3, 'BR100000003TO', 'ENTREGUE',    'Correios',  '2026-07-20', '2026-07-25', '2026-07-23 09:00:00'),
(5, 'BR100000005TO', 'ENTREGUE',    'Total Express','2026-07-28','2026-08-02','2026-08-01 16:00:00'),
(6, 'BR100000006GO', 'ENVIADO',     'Correios',  '2026-08-08', '2026-08-14', NULL);


-- =====================================================================
-- PARTE 3 — QUERIES SQL
-- =====================================================================

-- =====================================================================
-- Q1: Quantos pedidos foram feitos por cada cliente?
--     (SELECT + GROUP BY + JOIN + atributo derivado)
-- =====================================================================
-- Pergunta de negócio: quero saber o volume de compras por cliente
-- para identificar os mais ativos e potenciais candidatos a programa de fidelidade.
SELECT
    COALESCE(pf.nome_completo, pj.razao_social) AS nome_cliente,
    c.tipo_cliente,
    c.cidade,
    COUNT(p.id_pedido)                           AS total_pedidos,
    SUM(p.valor_total)                           AS valor_total_gasto,
    ROUND(AVG(p.valor_total), 2)                 AS ticket_medio
FROM cliente c
LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
LEFT JOIN pedido p      ON p.id_cliente  = c.id_cliente
GROUP BY c.id_cliente, nome_cliente, c.tipo_cliente, c.cidade
ORDER BY total_pedidos DESC, valor_total_gasto DESC;

-- =====================================================================
-- Q2: Algum vendedor também é fornecedor?
--     (JOIN + filtro WHERE + expressão condicional)
-- =====================================================================
-- Pergunta de negócio: existem vendedores cadastrados que também atuam
-- como fornecedores? Isso pode representar conflito de interesse ou
-- uma parceria estratégica a ser mapeada.
SELECT
    v.nome                                          AS nome_vendedor,
    v.email                                         AS email_vendedor,
    f.razao_social                                  AS razao_social_fornecedor,
    f.cidade                                        AS cidade_fornecedor,
    CONCAT('Sim — CNPJ: ', v.cnpj_fornecedor)       AS duplo_papel
FROM vendedor v
INNER JOIN fornecedor f ON f.cnpj = v.cnpj_fornecedor
WHERE v.cnpj_fornecedor IS NOT NULL;

-- =====================================================================
-- Q3: Relação de produtos, fornecedores e estoques
--     (JOIN múltiplo + ORDER BY)
-- =====================================================================
-- Pergunta de negócio: visão consolidada de cada produto com seu
-- fornecedor, preço de custo, margem e quantidade em estoque.
SELECT
    p.nome                                              AS produto,
    p.categoria,
    p.valor_unitario                                    AS preco_venda,
    f.razao_social                                      AS fornecedor,
    pf.preco_custo,
    ROUND(p.valor_unitario - pf.preco_custo, 2)         AS margem_bruta,
    ROUND(((p.valor_unitario - pf.preco_custo)
           / p.valor_unitario) * 100, 1)                AS margem_percentual,
    e.localizacao                                       AS local_estoque,
    pe.quantidade                                       AS qtd_em_estoque
FROM produto p
INNER JOIN produto_fornecedor pf ON pf.id_produto    = p.id_produto
INNER JOIN fornecedor f          ON f.id_fornecedor  = pf.id_fornecedor
INNER JOIN produto_estoque pe    ON pe.id_produto    = p.id_produto
INNER JOIN estoque e             ON e.id_estoque     = pe.id_estoque
ORDER BY p.categoria, margem_percentual DESC;

-- =====================================================================
-- Q4: Relação de nomes dos fornecedores e nomes dos produtos fornecidos
--     (JOIN + ORDER BY)
-- =====================================================================
-- Pergunta de negócio: catálogo de fornecimento — quais produtos
-- cada fornecedor abastece?
SELECT
    f.razao_social  AS fornecedor,
    f.cidade,
    f.uf,
    p.nome          AS produto,
    p.categoria,
    pf.preco_custo
FROM fornecedor f
INNER JOIN produto_fornecedor pf ON pf.id_fornecedor = f.id_fornecedor
INNER JOIN produto p             ON p.id_produto     = pf.id_produto
ORDER BY f.razao_social, p.categoria;

-- =====================================================================
-- Q5: Clientes com mais de 1 pedido e ticket médio acima de R$ 300
--     (HAVING + atributo derivado)
-- =====================================================================
-- Pergunta de negócio: quem são os clientes recorrentes e de alto valor?
-- Base para segmentação de campanhas de marketing.
SELECT
    COALESCE(pf.nome_completo, pj.razao_social) AS nome_cliente,
    c.tipo_cliente,
    COUNT(p.id_pedido)          AS total_pedidos,
    ROUND(AVG(p.valor_total),2) AS ticket_medio,
    SUM(p.valor_total)          AS valor_total_gasto
FROM cliente c
LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
INNER JOIN pedido p     ON p.id_cliente  = c.id_cliente
WHERE p.status_pedido <> 'CANCELADO'
GROUP BY c.id_cliente, nome_cliente, c.tipo_cliente
HAVING COUNT(p.id_pedido) > 1
   AND AVG(p.valor_total) > 300
ORDER BY valor_total_gasto DESC;

-- =====================================================================
-- Q6: Status das entregas com dias de atraso (atributo derivado)
--     (SELECT + WHERE + expressão com DATEDIFF + ORDER BY)
-- =====================================================================
-- Pergunta de negócio: quais entregas estão atrasadas e por quantos dias?
-- Essencial para gestão de SLA logístico.
SELECT
    e.codigo_rastreio,
    e.status_entrega,
    e.transportadora,
    COALESCE(pf.nome_completo, pj.razao_social) AS cliente,
    e.data_entrega_prevista,
    COALESCE(DATE(e.data_entrega_real), CURDATE())  AS data_referencia,
    DATEDIFF(
        COALESCE(DATE(e.data_entrega_real), CURDATE()),
        e.data_entrega_prevista
    )                                               AS dias_diferenca,
    CASE
        WHEN e.status_entrega = 'ENTREGUE'
             AND DATEDIFF(DATE(e.data_entrega_real), e.data_entrega_prevista) <= 0
             THEN 'No prazo'
        WHEN e.status_entrega = 'ENTREGUE'
             AND DATEDIFF(DATE(e.data_entrega_real), e.data_entrega_prevista) > 0
             THEN 'Entregue com atraso'
        WHEN e.status_entrega <> 'ENTREGUE'
             AND CURDATE() > e.data_entrega_prevista
             THEN 'Atrasado'
        ELSE 'Dentro do prazo'
    END AS situacao_entrega
FROM entrega e
INNER JOIN pedido p  ON p.id_pedido   = e.id_pedido
INNER JOIN cliente c ON c.id_cliente  = p.id_cliente
LEFT JOIN cliente_pf pf ON pf.id_cliente = c.id_cliente
LEFT JOIN cliente_pj pj ON pj.id_cliente = c.id_cliente
ORDER BY dias_diferenca DESC;

-- =====================================================================
-- Q7: Produtos mais vendidos com receita gerada
--     (GROUP BY + ORDER BY + atributo derivado)
-- =====================================================================
-- Pergunta de negócio: quais produtos geram mais receita?
-- Base para decisões de estoque, promoção e mix de produtos.
SELECT
    p.nome              AS produto,
    p.categoria,
    v.nome              AS vendedor_responsavel,
    SUM(ip.quantidade)  AS unidades_vendidas,
    p.valor_unitario    AS preco_atual,
    SUM(ip.quantidade * ip.valor_unitario) AS receita_total,
    pe.quantidade       AS estoque_atual,
    CASE
        WHEN pe.quantidade < 50  THEN 'ESTOQUE CRÍTICO'
        WHEN pe.quantidade < 150 THEN 'ESTOQUE BAIXO'
        ELSE 'ESTOQUE OK'
    END AS alerta_estoque
FROM produto p
INNER JOIN item_pedido ip    ON ip.id_produto = p.id_produto
INNER JOIN pedido ped        ON ped.id_pedido = ip.id_pedido
    AND ped.status_pedido <> 'CANCELADO'
INNER JOIN vendedor v        ON v.id_vendedor = p.id_vendedor
INNER JOIN produto_estoque pe ON pe.id_produto = p.id_produto
GROUP BY p.id_produto, p.nome, p.categoria, v.nome, p.valor_unitario, pe.quantidade
ORDER BY receita_total DESC;

-- =====================================================================
-- Q8: Formas de pagamento mais utilizadas por tipo de cliente
--     (JOIN + GROUP BY + HAVING + ORDER BY)
-- =====================================================================
-- Pergunta de negócio: PF e PJ têm preferências de pagamento diferentes?
-- Útil para negociar melhores condições com operadoras de pagamento.
SELECT
    c.tipo_cliente,
    fp.tipo                 AS forma_pagamento,
    COUNT(p.id_pedido)      AS total_pedidos,
    SUM(p.valor_total)      AS volume_financeiro
FROM pedido p
INNER JOIN cliente c        ON c.id_cliente         = p.id_cliente
INNER JOIN forma_pagamento fp ON fp.id_forma_pagamento = p.id_forma_pagamento
WHERE p.status_pedido <> 'CANCELADO'
GROUP BY c.tipo_cliente, fp.tipo
HAVING COUNT(p.id_pedido) >= 1
ORDER BY c.tipo_cliente, total_pedidos DESC;
