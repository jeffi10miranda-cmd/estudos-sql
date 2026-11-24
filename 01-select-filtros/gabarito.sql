/* =====================================================================
   Módulo 01 · SELECT e filtros · GABARITO
   Tente resolver em exercicios.md ANTES de abrir este arquivo.
   Há mais de uma resposta certa; compare o resultado, não o texto.
   ===================================================================== */
USE AdventureWorks2022;
GO

/* ---------------------------------------------------------------------
   Exercício 1 · Catálogo de preços
   Pegadinha: produtos com ListPrice = 0 são peças internas, não vendáveis.
   --------------------------------------------------------------------- */
SELECT
    ProductID,
    Name          AS produto,
    ProductNumber AS codigo,
    ListPrice     AS preco_tabela
FROM Production.Product
WHERE ListPrice > 0
ORDER BY ListPrice DESC, Name;
-- Resultado: 304 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 2 · Os 10 produtos mais caros
   WITH TIES traz os empatados com o 10º. Sem ele, o banco escolhe
   arbitrariamente quem entra quando há empate: resultado não determinístico.
   --------------------------------------------------------------------- */
SELECT TOP (10) WITH TIES
    Name      AS produto,
    ListPrice AS preco_tabela
FROM Production.Product
ORDER BY ListPrice DESC;
-- Resultado: 13 linhas com WITH TIES (sem ele, 10). O 10º lugar (3374,99) está empatado entre 4 "Mountain-100 Black".
GO

/* ---------------------------------------------------------------------
   Exercício 3 · Cores do catálogo
   DISTINCT olha a linha inteira. NULL não é uma cor, então filtramos.
   --------------------------------------------------------------------- */
SELECT DISTINCT Color AS cor
FROM Production.Product
WHERE Color IS NOT NULL
ORDER BY Color;
-- Resultado: 9 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 4 · Campanha de bikes vermelhas ou pretas
   IN substitui vários OR. BETWEEN inclui as duas pontas (500 e 1500).
   --------------------------------------------------------------------- */
SELECT
    Name      AS produto,
    Color     AS cor,
    ListPrice AS preco_tabela
FROM Production.Product
WHERE Color IN ('Red', 'Black')
  AND ListPrice BETWEEN 500 AND 1500
ORDER BY ListPrice DESC;
-- Resultado: 51 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 5 · Linha "Mountain"
   '%Mountain%' = contém em qualquer posição.
   'Mountain%'  = começa com.  O enunciado pede "começa com".
   --------------------------------------------------------------------- */
SELECT
    Name      AS produto,
    ListPrice AS preco_tabela
FROM Production.Product
WHERE Name LIKE 'Mountain%'
  AND ListPrice > 0
ORDER BY Name;
-- Resultado: 37 linhas  (com '%Mountain%' seriam 90: entram 'HL Mountain Frame', 'Fender Set - Mountain' etc.)
GO

/* ---------------------------------------------------------------------
   Exercício 6 · Produtos sem cor cadastrada
   Erro clássico: WHERE Color = NULL nunca retorna nada.
   Qualquer comparação com NULL resulta em UNKNOWN, não TRUE.
   --------------------------------------------------------------------- */
SELECT
    Name      AS produto,
    ListPrice AS preco_tabela
FROM Production.Product
WHERE Color IS NULL
  AND ListPrice > 0
ORDER BY ListPrice DESC;
-- Resultado: 59 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 7 · Pedidos grandes no 1º trimestre de 2013
   Use intervalo semiaberto: >= início AND < início do próximo período.
   Funciona para DATE e para DATETIME (com hora), e permite usar índice.
   Evite YEAR(OrderDate) = 2013 no WHERE: a função impede o uso de índice.
   --------------------------------------------------------------------- */
SELECT
    SalesOrderID,
    OrderDate,
    CustomerID,
    TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01'
  AND OrderDate <  '2013-04-01'
  AND TotalDue  >  50000
ORDER BY TotalDue DESC;
-- Resultado: 46 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 8 · Faixa de preço
   CASE avalia de cima para baixo e para no primeiro WHEN verdadeiro,
   então a ordem dos WHEN importa.
   --------------------------------------------------------------------- */
SELECT
    Name      AS produto,
    ListPrice AS preco_tabela,
    CASE
        WHEN ListPrice < 100  THEN 'Econômico'
        WHEN ListPrice < 1000 THEN 'Intermediário'
        ELSE 'Premium'
    END AS faixa_preco
FROM Production.Product
WHERE ListPrice > 0
ORDER BY ListPrice;
-- Resultado: 304 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 9 · Férias acumuladas
   --------------------------------------------------------------------- */
SELECT
    BusinessEntityID,
    JobTitle      AS cargo,
    HireDate      AS data_contratacao,
    VacationHours AS horas_ferias
FROM HumanResources.Employee
WHERE VacationHours > 80
  AND CurrentFlag = 1
ORDER BY VacationHours DESC;
-- Resultado: 57 linhas
GO

/* ---------------------------------------------------------------------
   Exercício 10 · Produtos que saíram de linha
   --------------------------------------------------------------------- */
SELECT
    Name         AS produto,
    SellStartDate AS inicio_venda,
    SellEndDate   AS fim_venda,
    ListPrice     AS preco_tabela
FROM Production.Product
WHERE SellEndDate IS NOT NULL
ORDER BY SellEndDate, Name;
-- Resultado: 98 linhas
GO
