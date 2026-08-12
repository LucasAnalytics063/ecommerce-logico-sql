# Modelo Lógico de E-commerce — Projeto de Banco de Dados

## Contexto

Este projeto implementa o **modelo lógico relacional de um sistema de e-commerce**, evoluindo o modelo conceitual anterior com a criação do esquema físico completo (DDL), persistência de dados para testes e um conjunto de queries SQL analíticas que respondem a perguntas reais de negócio.

## Refinamentos Aplicados

Conforme proposto no desafio, três refinamentos foram incorporados ao modelo base:

|               Refinamento         |                                       Solução de Modelagem                                                    |
|-----------------------------------|---------------------------------------------------------------------------------------------------------------|
| **Cliente PJ e PF exclusivos**    | Especialização com `cliente_pf` e `cliente_pj` como subtipos (herança), com triggers garantindo exclusividade |
| **Múltiplas formas de pagamento** | Relacionamento N:N via tabela associativa `cliente_forma_pagamento`                                           |
| **Entrega com status e rastreio** | Tabela `entrega` com ENUM de status e campo `codigo_rastreio` único                                           |

### Entidades e Tabelas

|          Tabela           |                     Descrição                               |
|---------------------------|-------------------------------------------------------------|
| `cliente`                 | Superclasse com dados comuns (e-mail, endereço, tipo PF/PJ) |
| `cliente_pf`              | Subtipo com CPF, nome completo e data de nascimento         |
| `cliente_pj`              | Subtipo com CNPJ e razão social                             |
| `forma_pagamento`         | Catálogo de modalidades de pagamento                        |
| `cliente_forma_pagamento` | Associativa: múltiplas formas por cliente                   |
| `fornecedor`              | Empresas que fornecem produtos ao marketplace               |
| `vendedor`                | Vendedores cadastrados (podem também ser fornecedores)      |
| `produto`                 | Catálogo de produtos com categoria e preço                  |
| `estoque`                 | Locais de armazenamento físico                              |
| `produto_estoque`         | Quantidade de cada produto em cada estoque                  |
| `produto_fornecedor`      | Vínculo produto-fornecedor com preço de custo               |
| `pedido`                  | Registro de compras com status e valor total                |
| `item_pedido`             | Produtos comprados em cada pedido (com preço histórico)     |
| `entrega`                 | Rastreamento de entrega de cada pedido                      |

## Queries SQL — Perguntas de Negócio

| #  |                     Pergunta Respondida                      |               Cláusulas Utilizadas                  |
|----|--------------------------------------------------------------|-----------------------------------------------------|
| Q1 | Quantos pedidos foram feitos por cada cliente?               | SELECT, JOIN, GROUP BY, ORDER BY, atributo derivado |
| Q2 | Algum vendedor também é fornecedor?                          | JOIN, WHERE, expressão condicional                  |
| Q3 | Relação de produtos, fornecedores, margens e estoques        | JOIN múltiplo, atributo derivado, ORDER BY          |
| Q4 | Relação de nomes dos fornecedores e produtos fornecidos      | JOIN, ORDER BY                                      |
| Q5 | Clientes recorrentes com ticket médio acima de R$ 300        | HAVING, WHERE, GROUP BY, atributo derivado          |
| Q6 | Entregas com status e dias de atraso calculados              | SELECT, DATEDIFF, CASE, WHERE, ORDER BY             |
| Q7 | Produtos mais vendidos com alerta de estoque                 | GROUP BY, ORDER BY, CASE, atributo derivado         |
| Q8 | Formas de pagamento preferidas por tipo de cliente (PF x PJ) | JOIN, GROUP BY, HAVING, ORDER BY                    |

## Autor

**Lucas Beserra Ribeiro**  
Analista de Business Intelligence | Sicoob Tocantins  
[GitHub: LucasAnalytics063](https://github.com/LucasAnalytics063)
