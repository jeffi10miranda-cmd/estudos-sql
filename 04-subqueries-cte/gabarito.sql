/* =====================================================================
   Módulo 04 · Subqueries e CTEs · GABARITO
   Tente resolver em exercicios.md ANTES de abrir este arquivo.
   ===================================================================== */
USE AdventureWorks2022;
GO

/* ---------------------------------------------------------------------
   Exercício 1 · Produtos acima do preço médio (subquery escalar)
   A subquery retorna UM valor e é usada como se fosse uma constante.
   --------------------------------------------------------------------- */
SELECT
    Name      AS produto,
    ListPrice AS preco_tabela,
    (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0) AS preco_medio
FROM Production.Product
WHERE ListPrice > (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0)
ORDER BY ListPrice DESC;
-- Resultado: 112 linhas
-- Por que filtrar ListPrice > 0 também dentro da média? Sem isso, os 200
-- itens de preço zero puxam a média para baixo e o "acima da média" muda.
GO

/* ---------------------------------------------------------------------
   Exercício 2 · Clientes que compraram em 2013 e não voltaram em 2014
   EXISTS / NOT EXISTS: só testa se existe pelo menos uma linha.
   É uma subquery CORRELACIONADA: usa c.CustomerID da consulta de fora.
   --------------------------------------------------------------------- */
SELECT c.CustomerID
FROM Sales.Customer AS c
WHERE EXISTS (
        SELECT 1
        FROM Sales.SalesOrderHeader AS soh
        WHERE soh.CustomerID = c.CustomerID
          AND soh.OrderDate >= '2013-01-01'
          AND soh.OrderDate <  '2014-01-01'
      )
  AND NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderHeader AS soh
        WHERE soh.CustomerID = c.CustomerID
          AND soh.OrderDate >= '2014-01-01'
      )
ORDER BY c.CustomerID;
-- Resultado: 8312 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 3 · A armadilha do NOT IN com NULL
   Funcionários que nunca aparecem como vendedor em nenhum pedido.
   --------------------------------------------------------------------- */
-- (a) Versão "óbvia" com NOT IN: retorna ZERO funcionários.
SELECT COUNT(*) AS qtd_not_in
FROM HumanResources.Employee AS e
WHERE e.BusinessEntityID NOT IN (
    SELECT soh.SalesPersonID
    FROM Sales.SalesOrderHeader AS soh
);
-- Resultado: 1 linha
-- Por quê? Pedidos online não têm vendedor: SalesPersonID é NULL em
-- milhares de linhas. "x NOT IN (1, 2, NULL)" equivale a
-- "x <> 1 AND x <> 2 AND x <> NULL". Comparar com NULL dá UNKNOWN,
-- então a condição inteira nunca é TRUE. Nenhum erro, só um número errado.
GO

-- (b) Versão segura com NOT EXISTS: NULL não atrapalha.
SELECT COUNT(*) AS qtd_not_exists
FROM HumanResources.Employee AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader AS soh
    WHERE soh.SalesPersonID = e.BusinessEntityID
);
-- Resultado: 1 linha
-- 290 funcionários - 17 vendedores = 273. Agora sim.
-- (Também funcionaria: NOT IN (... WHERE SalesPersonID IS NOT NULL),
--  ou LEFT JOIN ... WHERE soh.SalesOrderID IS NULL.)
-- Regra: para "não está em", prefira NOT EXISTS.
GO

/* ---------------------------------------------------------------------
   Exercício 4 · O maior pedido de cada cliente (subquery correlacionada)
   Para cada linha de fora, a subquery calcula o MAX daquele cliente.
   No módulo 05 você vai resolver isso de forma mais eficiente com
   ROW_NUMBER().
   --------------------------------------------------------------------- */
SELECT
    soh.CustomerID,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue
FROM Sales.SalesOrderHeader AS soh
WHERE soh.TotalDue = (
        SELECT MAX(x.TotalDue)
        FROM Sales.SalesOrderHeader AS x
        WHERE x.CustomerID = soh.CustomerID
      )
  AND soh.OrderDate >= '2014-01-01'
ORDER BY soh.TotalDue DESC;
-- Resultado: 7964 linhas
-- Lê-se: pedidos de 2014 que foram o maior pedido da história daquele cliente.
GO

/* ---------------------------------------------------------------------
   Exercício 5 · Vendedores acima da média da equipe em 2013 (CTE)
   A CTE (WITH ... AS) dá nome a um resultado intermediário.
   Fica muito mais legível que uma subquery aninhada.
   --------------------------------------------------------------------- */
WITH vendas_2013 AS (
    SELECT
        soh.SalesPersonID,
        SUM(soh.TotalDue) AS faturamento
    FROM Sales.SalesOrderHeader AS soh
    WHERE soh.SalesPersonID IS NOT NULL
      AND soh.OrderDate >= '2013-01-01'
      AND soh.OrderDate <  '2014-01-01'
    GROUP BY soh.SalesPersonID
)
SELECT
    p.FirstName + ' ' + p.LastName AS vendedor,
    v.faturamento,
    (SELECT AVG(faturamento) FROM vendas_2013) AS media_equipe
FROM vendas_2013 AS v
INNER JOIN Person.Person AS p ON p.BusinessEntityID = v.SalesPersonID
WHERE v.faturamento > (SELECT AVG(faturamento) FROM vendas_2013)
ORDER BY v.faturamento DESC;
-- Resultado: 7 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 6 · Participação de cada categoria (CTEs encadeadas)
   Uma CTE pode usar a anterior. Pense nelas como etapas de pipeline.
   Multiplicar por 100.0 (não 100) evita divisão inteira.
   --------------------------------------------------------------------- */
WITH vendas_categoria AS (
    SELECT
        pc.Name            AS categoria,
        SUM(sod.LineTotal) AS faturamento
    FROM Sales.SalesOrderDetail AS sod
    INNER JOIN Production.Product            AS p  ON p.ProductID = sod.ProductID
    INNER JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
    INNER JOIN Production.ProductCategory    AS pc ON pc.ProductCategoryID = ps.ProductCategoryID
    GROUP BY pc.Name
),
total AS (
    SELECT SUM(faturamento) AS faturamento_total
    FROM vendas_categoria
)
SELECT
    vc.categoria,
    vc.faturamento,
    CAST(100.0 * vc.faturamento / t.faturamento_total AS DECIMAL(5, 2)) AS pct_do_total
FROM vendas_categoria AS vc
CROSS JOIN total AS t
ORDER BY pct_do_total DESC;
-- Resultado: 4 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 7 · Segmentação de clientes por valor gasto
   Primeiro agrega por cliente (CTE), depois classifica e agrega de novo.
   "Agregar em duas etapas" é um padrão que você vai usar sempre.
   --------------------------------------------------------------------- */
WITH gasto_cliente AS (
    SELECT
        CustomerID,
        SUM(TotalDue) AS total_gasto
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
),
segmentado AS (
    SELECT
        CustomerID,
        total_gasto,
        CASE
            WHEN total_gasto <    1000 THEN '1. Até 1 mil'
            WHEN total_gasto <   10000 THEN '2. 1 mil a 10 mil'
            WHEN total_gasto <  100000 THEN '3. 10 mil a 100 mil'
            ELSE                            '4. Acima de 100 mil'
        END AS segmento
    FROM gasto_cliente
)
SELECT
    segmento,
    COUNT(*)         AS qtd_clientes,
    SUM(total_gasto) AS faturamento,
    AVG(total_gasto) AS gasto_medio
FROM segmentado
GROUP BY segmento
ORDER BY segmento;
-- Resultado: 4 linhas
-- Leitura: 254 clientes (~1,3%) acima de 100 mil respondem por ~66% do
-- faturamento. Perder um deles dói mais que perder milhares do segmento 1.
GO

/* ---------------------------------------------------------------------
   Exercício 8 · Calendário completo com CTE recursiva
   Âncora: primeiro dia. Parte recursiva: dia anterior + 1, até o fim.
   Depois LEFT JOIN com as vendas: dias sem venda aparecem com zero.
   Tabela-calendário (dim_data) é peça básica de todo data warehouse.
   MAXRECURSION 0 remove o limite padrão de 100 níveis.
   --------------------------------------------------------------------- */
WITH calendario AS (
    SELECT CAST('2011-05-31' AS DATE) AS dia
    UNION ALL
    SELECT DATEADD(DAY, 1, dia)
    FROM calendario
    WHERE dia < '2011-12-31'
),
vendas_dia AS (
    SELECT
        CAST(OrderDate AS DATE) AS dia,
        COUNT(*)                AS qtd_pedidos
    FROM Sales.SalesOrderHeader
    GROUP BY CAST(OrderDate AS DATE)
)
SELECT
    cal.dia,
    DATENAME(WEEKDAY, cal.dia)  AS dia_semana
FROM calendario AS cal
LEFT JOIN vendas_dia AS v ON v.dia = cal.dia
WHERE v.dia IS NULL
ORDER BY cal.dia
OPTION (MAXRECURSION 0);
-- Resultado: 3 linhas
-- São os dias de 2011 (a partir da 1ª venda) em que a empresa não vendeu nada.
GO

/* ---------------------------------------------------------------------
   Exercício 9 (desafio) · Explosão da lista de materiais (BOM)
   Quais componentes, em todos os níveis, formam a bike 'Road-150 Red, 62'
   (ProductID 749)? Recursão sobre Production.BillOfMaterials.
   --------------------------------------------------------------------- */
WITH bom AS (
    -- Âncora: componentes diretos da bike
    SELECT
        b.ComponentID,
        b.PerAssemblyQty,
        1 AS nivel
    FROM Production.BillOfMaterials AS b
    WHERE b.ProductAssemblyID = 749
      AND b.EndDate IS NULL

    UNION ALL

    -- Recursão: componentes dos componentes
    SELECT
        b.ComponentID,
        b.PerAssemblyQty,
        bom.nivel + 1
    FROM Production.BillOfMaterials AS b
    INNER JOIN bom ON b.ProductAssemblyID = bom.ComponentID
    WHERE b.EndDate IS NULL
)
SELECT
    bom.nivel,
    p.Name AS componente,
    bom.PerAssemblyQty AS qtd_por_montagem
FROM bom
INNER JOIN Production.Product AS p ON p.ProductID = bom.ComponentID
ORDER BY bom.nivel, componente;
-- Resultado: 89 linhas
GO
