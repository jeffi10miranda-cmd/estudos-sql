/* =====================================================================
   Módulo 02 · JOINs · GABARITO
   Tente resolver em exercicios.md ANTES de abrir este arquivo.
   ===================================================================== */
USE AdventureWorks2022;
GO

/* ---------------------------------------------------------------------
   Exercício 1 · Pedidos do último dia com nome do cliente
   Caminho: SalesOrderHeader.CustomerID -> Customer.CustomerID
            Customer.PersonID          -> Person.BusinessEntityID
   --------------------------------------------------------------------- */
SELECT
    soh.SalesOrderID,
    soh.OrderDate,
    p.FirstName + ' ' + p.LastName AS cliente,
    soh.TotalDue
FROM Sales.SalesOrderHeader AS soh
INNER JOIN Sales.Customer   AS c ON c.CustomerID       = soh.CustomerID
INNER JOIN Person.Person    AS p ON p.BusinessEntityID = c.PersonID
WHERE soh.OrderDate >= '2014-06-30'
  AND soh.OrderDate <  '2014-07-01'
ORDER BY soh.TotalDue DESC;
-- Resultado: 40 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 2 · Produto -> subcategoria -> categoria
   INNER JOIN descarta os produtos sem subcategoria (peças internas).
   É exatamente o que o enunciado pede ("apenas produtos classificados").
   --------------------------------------------------------------------- */
SELECT
    pc.Name  AS categoria,
    ps.Name  AS subcategoria,
    p.Name   AS produto,
    p.ListPrice AS preco_tabela
FROM Production.Product            AS p
INNER JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
INNER JOIN Production.ProductCategory    AS pc ON pc.ProductCategoryID    = ps.ProductCategoryID
ORDER BY categoria, subcategoria, produto;
-- Resultado: 295 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 3 · Nota fiscal do pedido 43659
   --------------------------------------------------------------------- */
SELECT
    sod.SalesOrderDetailID,
    p.Name           AS produto,
    sod.OrderQty     AS quantidade,
    sod.UnitPrice    AS preco_unitario,
    sod.UnitPriceDiscount AS desconto,
    sod.LineTotal    AS total_linha
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p ON p.ProductID = sod.ProductID
WHERE sod.SalesOrderID = 43659
ORDER BY sod.SalesOrderDetailID;
-- Resultado: 12 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 4 · Produtos vendáveis que nunca venderam (anti-join)
   Padrão: LEFT JOIN + WHERE <coluna da direita> IS NULL.
   Atenção: o filtro de ListPrice fica no WHERE porque é sobre a tabela
   da esquerda. Um filtro sobre a tabela da DIREITA no WHERE transformaria
   o LEFT JOIN em INNER JOIN sem você perceber.
   --------------------------------------------------------------------- */
SELECT
    p.ProductID,
    p.Name      AS produto,
    p.ListPrice AS preco_tabela
FROM Production.Product AS p
LEFT JOIN Sales.SalesOrderDetail AS sod ON sod.ProductID = p.ProductID
WHERE sod.ProductID IS NULL
  AND p.ListPrice > 0
ORDER BY p.ListPrice DESC;
-- Resultado: 38 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 5 · Vendedores e território
   LEFT JOIN em SalesTerritory: 3 vendedores não têm território e
   sumiriam com INNER JOIN. ISNULL troca o NULL por um rótulo legível.
   --------------------------------------------------------------------- */
SELECT
    p.FirstName + ' ' + p.LastName       AS vendedor,
    ISNULL(st.Name, '(sem território)')  AS territorio,
    sp.SalesYTD                          AS vendas_no_ano
FROM Sales.SalesPerson AS sp
INNER JOIN Person.Person        AS p  ON p.BusinessEntityID = sp.BusinessEntityID
LEFT  JOIN Sales.SalesTerritory AS st ON st.TerritoryID     = sp.TerritoryID
ORDER BY sp.SalesYTD DESC;
-- Resultado: 17 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 6 · Departamento atual de cada funcionário
   EmployeeDepartmentHistory guarda o histórico: a linha com EndDate NULL
   é a lotação atual. Esse padrão (histórico com data de início/fim) é o
   mesmo de uma dimensão SCD tipo 2 em data warehouse.
   --------------------------------------------------------------------- */
SELECT
    p.FirstName + ' ' + p.LastName AS funcionario,
    e.JobTitle  AS cargo,
    d.Name      AS departamento,
    d.GroupName AS area,
    edh.StartDate AS no_departamento_desde
FROM HumanResources.Employee AS e
INNER JOIN Person.Person AS p
        ON p.BusinessEntityID = e.BusinessEntityID
INNER JOIN HumanResources.EmployeeDepartmentHistory AS edh
        ON edh.BusinessEntityID = e.BusinessEntityID
       AND edh.EndDate IS NULL
INNER JOIN HumanResources.Department AS d
        ON d.DepartmentID = edh.DepartmentID
ORDER BY departamento, funcionario;
-- Resultado: 290 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 7 · Nome de exibição de todos os clientes
   Um cliente pode ser pessoa (PersonID), loja (StoreID) ou ambos
   (o contato da loja). Dois LEFT JOINs + COALESCE resolvem.
   COALESCE devolve o primeiro valor não nulo da lista.
   --------------------------------------------------------------------- */
SELECT
    c.CustomerID,
    c.AccountNumber,
    COALESCE(s.Name, p.FirstName + ' ' + p.LastName) AS nome_exibicao,
    CASE
        WHEN c.StoreID IS NOT NULL THEN 'Loja'
        ELSE 'Pessoa física'
    END AS tipo_cliente
FROM Sales.Customer AS c
LEFT JOIN Sales.Store   AS s ON s.BusinessEntityID = c.StoreID
LEFT JOIN Person.Person AS p ON p.BusinessEntityID = c.PersonID
ORDER BY c.CustomerID;
-- Resultado: 19820 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 8 · Funcionário e chefe direto (self join)
   A mesma tabela entra duas vezes com apelidos diferentes.
   O AdventureWorks guarda a hierarquia em OrganizationNode (tipo
   hierarchyid). GetAncestor(1) devolve o nó do chefe imediato.
   LEFT JOIN para manter o CEO, que não tem chefe.
   --------------------------------------------------------------------- */
SELECT
    pe.FirstName + ' ' + pe.LastName AS funcionario,
    e.JobTitle                       AS cargo,
    ISNULL(pg.FirstName + ' ' + pg.LastName, '(sem chefe)') AS chefe,
    g.JobTitle                       AS cargo_chefe
FROM HumanResources.Employee AS e
INNER JOIN Person.Person AS pe ON pe.BusinessEntityID = e.BusinessEntityID
LEFT  JOIN HumanResources.Employee AS g
        ON g.OrganizationNode = e.OrganizationNode.GetAncestor(1)
LEFT  JOIN Person.Person AS pg ON pg.BusinessEntityID = g.BusinessEntityID
ORDER BY chefe, funcionario;
-- Resultado: 290 linhas
GO
