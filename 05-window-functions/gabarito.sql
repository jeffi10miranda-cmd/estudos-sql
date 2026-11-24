/* =====================================================================
   Módulo 05 · Window functions · GABARITO
   Tente resolver em exercicios.md ANTES de abrir este arquivo.
   ===================================================================== */
USE AdventureWorks2022;
GO

/* ---------------------------------------------------------------------
   Exercício 1 · Numerar as compras de cada cliente
   PARTITION BY = "recomeça a conta para cada cliente".
   ORDER BY dentro do OVER = em que ordem numerar.
   SalesOrderID no desempate garante resultado determinístico.
   --------------------------------------------------------------------- */
SELECT
    CustomerID,
    SalesOrderID,
    OrderDate,
    TotalDue,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate, SalesOrderID) AS n_compra
FROM Sales.SalesOrderHeader
WHERE CustomerID IN (11000, 11091, 29825)
ORDER BY CustomerID, n_compra;
-- Resultado: 43 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 2 · Primeira compra de cada cliente (deduplicação)
   Window function não pode ir no WHERE (o WHERE roda antes dela),
   então calculamos numa CTE e filtramos fora. Este padrão
   "ROW_NUMBER() + filtro = 1" é o jeito padrão de deduplicar em
   pipelines de dados.
   --------------------------------------------------------------------- */
WITH numerado AS (
    SELECT
        CustomerID,
        SalesOrderID,
        OrderDate,
        TotalDue,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate, SalesOrderID) AS rn
    FROM Sales.SalesOrderHeader
)
SELECT
    YEAR(OrderDate) AS ano_primeira_compra,
    COUNT(*)        AS novos_clientes,
    AVG(TotalDue)   AS ticket_medio_primeira_compra
FROM numerado
WHERE rn = 1
GROUP BY YEAR(OrderDate)
ORDER BY ano_primeira_compra;
-- Resultado: 4 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 3 · Top 5 produtos por faturamento em cada categoria
   ROW_NUMBER: 1,2,3,4    (nunca empata; no empate escolhe arbitrariamente)
   RANK:       1,1,3,4    (empata e PULA posições)
   DENSE_RANK: 1,1,2,3    (empata e NÃO pula)
   Para "top N" de negócio, RANK é o mais honesto: se dois empatam
   no 5º lugar, os dois aparecem. Aqui não há empates, então as três
   dão o mesmo resultado; troque e compare.
   A janela roda depois do GROUP BY, por isso ORDER BY SUM(...) funciona.
   --------------------------------------------------------------------- */
WITH ranqueado AS (
    SELECT
        pc.Name            AS categoria,
        p.Name             AS produto,
        SUM(sod.LineTotal) AS faturamento,
        RANK() OVER (PARTITION BY pc.Name ORDER BY SUM(sod.LineTotal) DESC) AS posicao
    FROM Sales.SalesOrderDetail AS sod
    INNER JOIN Production.Product            AS p  ON p.ProductID = sod.ProductID
    INNER JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
    INNER JOIN Production.ProductCategory    AS pc ON pc.ProductCategoryID = ps.ProductCategoryID
    GROUP BY pc.Name, p.Name
)
SELECT categoria, posicao, produto, faturamento
FROM ranqueado
WHERE posicao <= 5
ORDER BY categoria, posicao;
-- Resultado: 20 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 4 · Faturamento acumulado no ano (running total)
   Agregamos por mês primeiro (CTE) e aplicamos a janela depois.
   ROWS UNBOUNDED PRECEDING = "do começo até a linha atual".
   Sem ROWS, o padrão é RANGE, que é mais lento e trata empates
   de forma diferente. Seja explícito.
   --------------------------------------------------------------------- */
WITH mensal AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS mes,
        SUM(TotalDue) AS faturamento
    FROM Sales.SalesOrderHeader
    WHERE OrderDate >= '2013-01-01'
      AND OrderDate <  '2014-01-01'
    GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
)
SELECT
    mes,
    faturamento,
    SUM(faturamento) OVER (ORDER BY mes ROWS UNBOUNDED PRECEDING) AS acumulado_ano
FROM mensal
ORDER BY mes;
-- Resultado: 12 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 5 · Participação de cada território (% do total)
   SUM(...) OVER () sem PARTITION = total de TODAS as linhas.
   Compare com o módulo 04, exercício 6: lá precisamos de duas CTEs.
   Aqui uma janela resolve. Note SUM(SUM(...)): a janela roda DEPOIS
   do GROUP BY, sobre os valores já agregados.
   --------------------------------------------------------------------- */
SELECT
    st.Name                AS territorio,
    st.[Group]             AS regiao,
    SUM(soh.TotalDue)      AS faturamento,
    CAST(100.0 * SUM(soh.TotalDue) / SUM(SUM(soh.TotalDue)) OVER ()
         AS DECIMAL(5, 2)) AS pct_total,
    CAST(100.0 * SUM(soh.TotalDue) / SUM(SUM(soh.TotalDue)) OVER (PARTITION BY st.[Group])
         AS DECIMAL(5, 2)) AS pct_da_regiao
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.SalesTerritory AS st ON st.TerritoryID = soh.TerritoryID
GROUP BY st.Name, st.[Group]
ORDER BY faturamento DESC;
-- Resultado: 10 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 6 · Crescimento mês contra mês (LAG)
   LAG(col, 1) = valor da linha anterior na ordem da janela.
   NULLIF evita divisão por zero (se o mês anterior fosse 0).
   O primeiro mês fica com NULL: não há mês anterior para comparar.
   --------------------------------------------------------------------- */
WITH mensal AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS mes,
        SUM(TotalDue) AS faturamento
    FROM Sales.SalesOrderHeader
    GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
)
SELECT
    mes,
    faturamento,
    LAG(faturamento) OVER (ORDER BY mes) AS faturamento_mes_anterior,
    CAST(100.0 * (faturamento - LAG(faturamento) OVER (ORDER BY mes))
         / NULLIF(LAG(faturamento) OVER (ORDER BY mes), 0)
         AS DECIMAL(7, 2)) AS variacao_pct
FROM mensal
ORDER BY mes;
-- Resultado: 38 linhas
-- Leitura crítica: a queda de -99% em jun/2014 não é colapso de vendas.
-- O último pedido de revenda (OnlineOrderFlag = 0) é de 01/05/2014, então
-- junho só tem vendas do site. E os pedidos de revenda são lançados quase
-- todos nos dias 29, 30, 31 ou 1: um dia a mais ou a menos no mês muda o
-- total e gera os "picos" de +400%. Confira:
--   SELECT DAY(OrderDate) AS dia, COUNT(*) FROM Sales.SalesOrderHeader
--   WHERE OnlineOrderFlag = 0 GROUP BY DAY(OrderDate) ORDER BY 2 DESC;
GO

/* ---------------------------------------------------------------------
   Exercício 7 · Média móvel de 3 meses
   ROWS BETWEEN 2 PRECEDING AND CURRENT ROW = este mês + os 2 anteriores.
   Nos 2 primeiros meses a janela tem menos de 3 linhas; a coluna
   qtd_meses_na_janela deixa isso visível em vez de esconder.
   --------------------------------------------------------------------- */
WITH mensal AS (
    SELECT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS mes,
        SUM(TotalDue) AS faturamento
    FROM Sales.SalesOrderHeader
    GROUP BY DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)
)
SELECT
    mes,
    faturamento,
    AVG(faturamento) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel_3m,
    COUNT(*)         OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS qtd_meses_na_janela
FROM mensal
ORDER BY mes;
-- Resultado: 38 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 8 · Quartis de clientes por valor (NTILE)
   NTILE(4) divide as linhas ordenadas em 4 grupos de tamanho ~igual.
   Diferente do módulo 04 (faixas fixas em R$), aqui as faixas
   são relativas: cada quartil tem 25% dos clientes.
   --------------------------------------------------------------------- */
WITH gasto_cliente AS (
    SELECT
        CustomerID,
        SUM(TotalDue) AS total_gasto
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
),
quartis AS (
    SELECT
        CustomerID,
        total_gasto,
        NTILE(4) OVER (ORDER BY total_gasto DESC) AS quartil
    FROM gasto_cliente
)
SELECT
    quartil,
    COUNT(*)         AS qtd_clientes,
    MIN(total_gasto) AS menor_gasto,
    MAX(total_gasto) AS maior_gasto,
    SUM(total_gasto) AS faturamento,
    CAST(100.0 * SUM(total_gasto) / SUM(SUM(total_gasto)) OVER () AS DECIMAL(5, 2)) AS pct_faturamento
FROM quartis
GROUP BY quartil
ORDER BY quartil;
-- Resultado: 4 linhas
-- Leitura: o 1º quartil (25% dos clientes) concentra ~92,5% do faturamento.
-- São majoritariamente as lojas/revendas atendidas por vendedor.
GO

/* ---------------------------------------------------------------------
   Exercício 9 · Intervalo entre compras
   LAG por cliente traz a data da compra anterior DO MESMO cliente.
   Depois agregamos para responder a pergunta de negócio.
   --------------------------------------------------------------------- */
WITH com_anterior AS (
    SELECT
        CustomerID,
        OrderDate,
        LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate, SalesOrderID) AS compra_anterior
    FROM Sales.SalesOrderHeader
    WHERE OnlineOrderFlag = 1
)
SELECT
    COUNT(*)                                              AS recompras,
    COUNT(DISTINCT CustomerID)                            AS clientes_que_recompraram,
    AVG(DATEDIFF(DAY, compra_anterior, OrderDate) * 1.0) AS media_dias_entre_compras,
    MIN(DATEDIFF(DAY, compra_anterior, OrderDate))        AS min_dias,
    MAX(DATEDIFF(DAY, compra_anterior, OrderDate))        AS max_dias
FROM com_anterior
WHERE compra_anterior IS NOT NULL;
-- Resultado: 1 linha
GO
