# 03 · GROUP BY e agregações

> **Pergunta que este módulo responde:** "Quanto, quantos, qual a média, *por* alguma coisa?"

Até aqui cada linha do resultado era uma linha da tabela. Com `GROUP BY`, cada linha do resultado passa a representar um **grupo** de linhas. É assim que nascem KPIs, relatórios e as tabelas agregadas que um engenheiro de dados entrega para BI.

## Funções de agregação

| Função | O que faz | Ignora NULL? |
|---|---|---|
| `COUNT(*)` | Conta linhas | Não (conta tudo) |
| `COUNT(coluna)` | Conta valores preenchidos | Sim |
| `COUNT(DISTINCT coluna)` | Conta valores diferentes | Sim |
| `SUM(coluna)` | Soma | Sim |
| `AVG(coluna)` | Média | Sim (e isso muda a média!) |
| `MIN` / `MAX` | Menor / maior | Sim |

## A regra de ouro

> Toda coluna no `SELECT` precisa estar **dentro de uma agregação** ou **no `GROUP BY`**.

```sql
-- ERRO: Name não está agregado nem no GROUP BY
SELECT TerritoryID, Name, SUM(TotalDue) FROM ... GROUP BY TerritoryID;
```

Faz sentido: se o grupo tem 500 pedidos, qual dos 500 nomes o banco deveria mostrar?

## WHERE x HAVING

Ordem de execução completa:

```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → TOP
```

- `WHERE` filtra **linhas** antes de agrupar. Não enxerga `SUM()`.
- `HAVING` filtra **grupos** depois de agrupar. É onde vai `SUM(...) > 1000000`.

Regra prática: se o filtro não depende de agregação, coloque no `WHERE`. É mais rápido, porque agrupa menos linhas.

## Agregação condicional

O truque mais útil deste módulo. Transforma categorias em colunas:

```sql
SELECT
    YEAR(OrderDate) AS ano,
    SUM(CASE WHEN OnlineOrderFlag = 1 THEN TotalDue ELSE 0 END) AS online,
    SUM(CASE WHEN OnlineOrderFlag = 0 THEN TotalDue ELSE 0 END) AS loja
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate);
```

## ROLLUP: subtotais de graça

`GROUP BY ROLLUP(regiao, territorio)` devolve o detalhe, um subtotal por região e o total geral numa consulta só. `GROUPING(coluna)` diz se a linha é subtotal.

## Cuidados de quem vai trabalhar com dados

- **Granularidade antes de somar.** `SUM(TotalDue)` depois de um JOIN com `SalesOrderDetail` conta cada pedido várias vezes (fan-out, módulo 02).
- **Períodos incompletos.** No AdventureWorks, 2011 começa em maio e 2014 termina em junho. Comparar o total anual de 2014 com 2013 é desonesto. Compare meses equivalentes ou médias mensais.
- **`TotalDue` ≠ `SUM(LineTotal)`.** O primeiro inclui imposto e frete. Sempre saiba de onde vem o número.
- **`AVG` ignora NULL.** A média de `(10, NULL, 20)` é 15, não 10.

## Como estudar

Resolva [exercicios.md](exercicios.md), confira as contagens e compare com o [gabarito.sql](gabarito.sql). Nos exercícios marcados com 🧠, escreva também **uma frase de interpretação**: número sem leitura não vale nada para o negócio.
