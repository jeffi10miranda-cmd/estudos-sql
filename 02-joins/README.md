# 02 · JOINs

> **Pergunta que este módulo responde:** "A informação que eu preciso está espalhada em várias tabelas. Como junto tudo?"

Bancos transacionais como o AdventureWorks são **normalizados**: cada fato mora em uma tabela só. O pedido sabe o `CustomerID`, mas o nome do cliente está em `Person.Person`. Juntar tabelas é a habilidade mais usada em engenharia de dados, e também a que mais gera bugs silenciosos: linhas que somem ou que se multiplicam sem dar erro nenhum.

## Os tipos de JOIN

| JOIN | Retorna | Uso típico |
|---|---|---|
| `INNER JOIN` | Só as linhas que têm par dos dois lados | "Pedidos **com** o nome do cliente" |
| `LEFT JOIN` | Todas da esquerda + par da direita (ou `NULL`) | "Todos os vendedores, **mesmo os sem** território" |
| `RIGHT JOIN` | O espelho do LEFT | Quase ninguém usa; reescreva como LEFT |
| `FULL JOIN` | Tudo dos dois lados | Reconciliar duas fontes (o que tem num e não no outro) |
| `CROSS JOIN` | Todas as combinações | Gerar grade (ex.: todo produto × todo mês) |

```sql
SELECT ...
FROM tabela_a AS a
INNER JOIN tabela_b AS b ON b.chave = a.chave
LEFT  JOIN tabela_c AS c ON c.chave = b.outra_chave
```

Use **apelidos** curtos (`soh`, `p`, `c`) e sempre prefixe as colunas com eles. Quando duas tabelas têm uma coluna com o mesmo nome (`Name`, `ModifiedDate`), sem prefixo dá erro de ambiguidade.

## Os dois bugs que você precisa reconhecer

**1. Linhas que somem (INNER onde deveria ser LEFT).**
3 dos 17 vendedores não têm território. Um `INNER JOIN` com `SalesTerritory` os elimina e ninguém percebe, porque não há erro.

**2. Linhas que se multiplicam (fan-out).**
Se você junta `SalesOrderHeader` (1 linha por pedido) com `SalesOrderDetail` (N linhas por pedido) e depois soma `TotalDue`, o valor de cada pedido é contado N vezes. Antes de todo JOIN, pergunte: **"qual é a granularidade de cada tabela? Uma linha representa o quê?"**

## LEFT JOIN: onde colocar o filtro

```sql
-- Filtro da tabela da DIREITA no WHERE: vira INNER JOIN disfarçado
SELECT ...
FROM Sales.SalesPerson sp
LEFT JOIN Sales.SalesTerritory st ON st.TerritoryID = sp.TerritoryID
WHERE st.[Group] = 'Europe';           -- some quem não tem território

-- Filtro no ON: mantém todos os vendedores, só "casa" com territórios da Europa
LEFT JOIN Sales.SalesTerritory st ON st.TerritoryID = sp.TerritoryID AND st.[Group] = 'Europe'
```

A exceção útil é o **anti-join**: `WHERE direita.chave IS NULL` traz quem **não tem** par (ex.: produto que nunca foi vendido).

## Mapa de chaves do AdventureWorks (o que liga com o quê)

```
Sales.SalesOrderHeader.CustomerID      → Sales.Customer.CustomerID
Sales.Customer.PersonID                → Person.Person.BusinessEntityID
Sales.Customer.StoreID                 → Sales.Store.BusinessEntityID
Sales.SalesOrderHeader.SalesPersonID   → Sales.SalesPerson.BusinessEntityID
Sales.SalesOrderHeader.TerritoryID     → Sales.SalesTerritory.TerritoryID
Sales.SalesOrderDetail.SalesOrderID    → Sales.SalesOrderHeader.SalesOrderID
Sales.SalesOrderDetail.ProductID       → Production.Product.ProductID
Production.Product.ProductSubcategoryID→ Production.ProductSubcategory.ProductSubcategoryID
Production.ProductSubcategory.ProductCategoryID → Production.ProductCategory.ProductCategoryID
HumanResources.Employee.BusinessEntityID → Person.Person.BusinessEntityID
```

## Como estudar

1. Resolva [exercicios.md](exercicios.md). Use a contagem de linhas de cada exercício para se autocorrigir.
2. Quando a contagem não bater, a causa quase sempre é: INNER no lugar de LEFT, filtro no lugar errado, ou fan-out.
3. Compare com o [gabarito.sql](gabarito.sql).
