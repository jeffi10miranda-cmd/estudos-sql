/* =====================================================================
   Módulo 03 · GROUP BY e agregações · GABARITO
   Tente resolver em exercicios.md ANTES de abrir este arquivo.
   ===================================================================== */
USE AdventureWorks2022;
GO

/* ---------------------------------------------------------------------
   Exercício 1 · Pedidos e faturamento por ano
   Aqui YEAR() é aceitável: está no SELECT/GROUP BY, não filtrando.
   --------------------------------------------------------------------- */
SELECT
    YEAR(OrderDate)    AS ano,
    COUNT(*)           AS qtd_pedidos,
    SUM(TotalDue)      AS faturamento,
    AVG(TotalDue)      AS ticket_medio
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY ano;
-- Resultado: 4 linhas
-- Leitura crítica: 2014 parece pior que 2013, mas só tem 6 meses de dados.
GO

/* ---------------------------------------------------------------------
   Exercício 2 · Faturamento por categoria
   Granularidade: SalesOrderDetail (1 linha por item). LineTotal é o
   valor do item, então somar aqui NÃO tem fan-out.
   --------------------------------------------------------------------- */
SELECT
    pc.Name                 AS categoria,
    SUM(sod.OrderQty)       AS unidades_vendidas,
    SUM(sod.LineTotal)      AS faturamento
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product            AS p  ON p.ProductID = sod.ProductID
INNER JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
INNER JOIN Production.ProductCategory    AS pc ON pc.ProductCategoryID = ps.ProductCategoryID
GROUP BY pc.Name
ORDER BY faturamento DESC;
-- Resultado: 4 linhas
-- Observação: SUM(LineTotal) não bate com SUM(TotalDue), porque TotalDue
-- inclui imposto (TaxAmt) e frete (Freight). Saber de onde vem cada
-- número é metade do trabalho de engenharia de dados.
GO

/* ---------------------------------------------------------------------
   Exercício 3 · Ticket médio por território
   --------------------------------------------------------------------- */
SELECT
    st.Name                AS territorio,
    st.[Group]             AS regiao,
    COUNT(*)               AS qtd_pedidos,
    SUM(soh.TotalDue)      AS faturamento,
    AVG(soh.TotalDue)      AS ticket_medio
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st ON st.TerritoryID = soh.TerritoryID
GROUP BY st.Name, st.[Group]
ORDER BY ticket_medio DESC;
-- Resultado: 10 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 4 · Subcategorias acima de 1 milhão (HAVING)
   WHERE filtra LINHAS antes de agrupar; HAVING filtra GRUPOS depois.
   --------------------------------------------------------------------- */
SELECT
    ps.Name            AS subcategoria,
    SUM(sod.LineTotal) AS faturamento
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product            AS p  ON p.ProductID = sod.ProductID
INNER JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
GROUP BY ps.Name
HAVING SUM(sod.LineTotal) > 1000000
ORDER BY faturamento DESC;
-- Resultado: 6 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 5 · Clientes mais frequentes
   --------------------------------------------------------------------- */
SELECT
    CustomerID,
    COUNT(*)       AS qtd_pedidos,
    SUM(TotalDue)  AS total_gasto,
    MIN(OrderDate) AS primeira_compra,
    MAX(OrderDate) AS ultima_compra
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) >= 20
ORDER BY qtd_pedidos DESC, total_gasto DESC;
-- Resultado: 14 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 6 · Online x Vendedor, por ano (agregação condicional)
   SUM(CASE ...) "pivota" categorias em colunas. Padrão muito usado.
   --------------------------------------------------------------------- */
SELECT
    YEAR(OrderDate) AS ano,
    SUM(CASE WHEN OnlineOrderFlag = 1 THEN 1 ELSE 0 END)        AS pedidos_online,
    SUM(CASE WHEN OnlineOrderFlag = 0 THEN 1 ELSE 0 END)        AS pedidos_vendedor,
    SUM(CASE WHEN OnlineOrderFlag = 1 THEN TotalDue ELSE 0 END) AS faturamento_online,
    SUM(CASE WHEN OnlineOrderFlag = 0 THEN TotalDue ELSE 0 END) AS faturamento_vendedor
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY ano;
-- Resultado: 4 linhas
-- Leitura: o online tem muito mais pedidos; o canal de vendedor
-- (revendas/lojas) tem muito mais faturamento.
GO

/* ---------------------------------------------------------------------
   Exercício 7 · COUNT(*) x COUNT(coluna) x COUNT(DISTINCT coluna)
   COUNT(*)             conta linhas
   COUNT(coluna)        conta valores NÃO nulos
   COUNT(DISTINCT col)  conta valores distintos não nulos
   --------------------------------------------------------------------- */
SELECT
    COUNT(*)                      AS total_pedidos,
    COUNT(SalesPersonID)          AS pedidos_com_vendedor,
    COUNT(DISTINCT SalesPersonID) AS vendedores_distintos,
    COUNT(DISTINCT CustomerID)    AS clientes_distintos
FROM Sales.SalesOrderHeader;
-- Resultado: 1 linha
GO

/* ---------------------------------------------------------------------
   Exercício 8 · Faturamento mês a mês em 2013
   DATEFROMPARTS gera uma data "primeiro dia do mês", ótima para eixo
   de gráfico. No SQL Server 2022 também existe DATETRUNC(month, OrderDate).
   --------------------------------------------------------------------- */
SELECT
    DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS mes,
    COUNT(*)      AS qtd_pedidos,
    SUM(TotalDue) AS faturamento
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01'
  AND OrderDate <  '2014-01-01'
GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
ORDER BY mes;
-- Resultado: 12 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 9 · Subtotais por região e território (ROLLUP)
   ROLLUP(a, b) gera: (a,b), (a) e () -> detalhe, subtotal e total geral.
   GROUPING(col) = 1 indica que a linha é um subtotal para aquela coluna.
   --------------------------------------------------------------------- */
SELECT
    CASE WHEN GROUPING(st.[Group]) = 1 THEN '** TOTAL GERAL **' ELSE st.[Group] END AS regiao,
    CASE
        WHEN GROUPING(st.[Group]) = 1 THEN ''
        WHEN GROUPING(st.Name)    = 1 THEN '* subtotal *'
        ELSE st.Name
    END AS territorio,
    SUM(soh.TotalDue) AS faturamento
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st ON st.TerritoryID = soh.TerritoryID
WHERE soh.OrderDate >= '2013-01-01'
  AND soh.OrderDate <  '2014-01-01'
GROUP BY ROLLUP (st.[Group], st.Name)
ORDER BY GROUPING(st.[Group]), st.[Group], GROUPING(st.Name), st.Name;
-- Resultado: 14 linhas
GO
