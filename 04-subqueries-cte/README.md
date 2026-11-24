# 04 · Subqueries e CTEs

> **Pergunta que este módulo responde:** "Preciso do resultado de uma consulta para fazer outra."

Perguntas reais raramente cabem em um único `SELECT ... GROUP BY`. "Clientes que gastaram acima da média" exige calcular a média primeiro. "Quem comprou ano passado e não voltou" exige comparar dois conjuntos. Este módulo ensina a quebrar um problema em etapas, que é exatamente como se pensa uma pipeline de dados.

## Tipos de subquery

| Tipo | Retorna | Onde aparece | Exemplo |
|---|---|---|---|
| **Escalar** | 1 valor | `SELECT`, `WHERE` | `WHERE ListPrice > (SELECT AVG(ListPrice) FROM ...)` |
| **Lista** | 1 coluna, N linhas | `WHERE ... IN (...)` | `WHERE ProductID IN (SELECT ProductID FROM ...)` |
| **Tabela derivada** | N colunas, N linhas | `FROM (...) AS apelido` | `FROM (SELECT ... GROUP BY ...) AS t` |
| **Correlacionada** | depende da linha de fora | `WHERE`, `SELECT` | `WHERE EXISTS (SELECT 1 FROM x WHERE x.id = fora.id)` |

A **correlacionada** usa uma coluna da consulta externa, então é reavaliada linha a linha (conceitualmente; o otimizador muitas vezes a transforma em JOIN).

## EXISTS e NOT EXISTS

Respondem "existe pelo menos uma linha que...?". Não importa o que o `SELECT` interno retorna; por convenção se escreve `SELECT 1`.

```sql
-- Clientes com pelo menos um pedido acima de 50 mil
SELECT c.CustomerID
FROM Sales.Customer AS c
WHERE EXISTS (
    SELECT 1 FROM Sales.SalesOrderHeader AS soh
    WHERE soh.CustomerID = c.CustomerID AND soh.TotalDue > 50000
);
```

### ⚠️ A armadilha do `NOT IN`

Se a lista do `NOT IN` contiver **um único NULL**, a consulta retorna **zero linhas**, sem erro. O exercício 3 mostra isso com dados reais. Para "não está em", use `NOT EXISTS`.

## CTE (Common Table Expression)

Uma CTE dá **nome** a uma consulta intermediária. Mesmo poder da tabela derivada, mas lida de cima para baixo:

```sql
WITH vendas_por_cliente AS (           -- etapa 1
    SELECT CustomerID, SUM(TotalDue) AS total
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
),
media AS (                              -- etapa 2 usa a 1
    SELECT AVG(total) AS media_total FROM vendas_por_cliente
)
SELECT v.CustomerID, v.total            -- resultado final
FROM vendas_por_cliente v
CROSS JOIN media m
WHERE v.total > m.media_total;
```

Detalhes do SQL Server:

- A instrução **antes** de um `WITH` precisa terminar com `;`. Por isso muita gente escreve `;WITH`.
- A CTE só existe durante aquela instrução. Para reaproveitar em várias consultas, use tabela temporária (`#tabela`) ou uma view.

## CTE recursiva

Uma CTE que chama a si mesma. Serve para **hierarquias** (organograma, lista de materiais, categorias aninhadas) e para **gerar sequências** (calendário).

```sql
WITH numeros AS (
    SELECT 1 AS n               -- âncora: ponto de partida
    UNION ALL
    SELECT n + 1 FROM numeros   -- parte recursiva
    WHERE n < 10                -- condição de parada (obrigatória!)
)
SELECT n FROM numeros;
```

O SQL Server para em 100 níveis por padrão. Para ir além: `OPTION (MAXRECURSION 0)` no final da consulta.

## Subquery, CTE ou JOIN?

Muitas vezes os três resolvem. Critério na prática: **legibilidade primeiro**. CTEs nomeadas como etapas (`vendas_2013`, `clientes_ativos`) fazem o código se explicar. O otimizador do SQL Server costuma gerar o mesmo plano para as versões equivalentes; quando não gerar, você mede (isso é assunto de performance, mais adiante na trilha).

## Como estudar

Resolva [exercicios.md](exercicios.md) e compare com o [gabarito.sql](gabarito.sql). Para cada exercício, tente escrever **duas versões** (por exemplo, subquery e CTE) e confirme que o resultado é o mesmo.
