# 04 · Exercícios: Subqueries e CTEs

Cada exercício traz a **checagem** de linhas. Nos marcados com 🧠, escreva também uma frase interpretando o resultado. Depois compare com o [gabarito](gabarito.sql).

---

### Exercício 1 · Acima do preço médio

**Pedido do Comercial:** "Quais produtos têm preço de tabela **acima da média** do catálogo vendável? Mostra também a média para referência."

- Média do catálogo vendável = média de `ListPrice` só dos produtos com preço maior que zero.
- Use uma subquery escalar no `WHERE`.
- Teste também calculando a média **com** os produtos de preço zero. Quantas linhas mudam? Qual das duas médias faz sentido para o negócio?

✅ Checagem: **112 linhas**.

---

### Exercício 2 · Clientes que não voltaram 🧠

**Pedido do CRM:** "Quais clientes **compraram em 2013** e **não compraram nada em 2014**? Quero só a lista de IDs."

- Use `EXISTS` para "comprou em 2013" e `NOT EXISTS` para "não comprou em 2014".
- 🧠 2014 só tem dados até junho. Isso muda a interpretação de "não voltou"? Como você chamaria esse número num relatório para não induzir ninguém ao erro?

✅ Checagem: **8.312 linhas**.

---

### Exercício 3 · A armadilha do NOT IN

**Pedido do RH:** "Quantos funcionários **nunca aparecem como vendedor** em nenhum pedido?"

- Faça primeiro com `WHERE e.BusinessEntityID NOT IN (SELECT SalesPersonID FROM Sales.SalesOrderHeader)`. Anote o número.
- Depois faça com `NOT EXISTS`. Anote o número.
- Os números são diferentes. Explique por quê num comentário (dica: quantos pedidos não têm `SalesPersonID`?).

✅ Checagem: as duas consultas retornam **1 linha** (é um `COUNT`). Os valores certos você confere no gabarito.

---

### Exercício 4 · O maior pedido da vida do cliente

**Pedido do CRM:** "Quais pedidos de **2014** foram o **maior pedido que aquele cliente já fez**? Do maior para o menor."

- Use uma subquery **correlacionada**: para cada pedido, compare o `TotalDue` com o `MAX(TotalDue)` do mesmo cliente.

✅ Checagem: **7.964 linhas**.

---

### Exercício 5 · Vendedores acima da média da equipe

**Pedido da Diretoria Comercial:** "Em **2013**, quais vendedores faturaram **acima da média da equipe**? Quero o nome, o faturamento e a média."

- Monte uma CTE `vendas_2013` com o faturamento por `SalesPersonID` (ignore pedidos sem vendedor).
- Na consulta final, junte com `Person.Person` e compare com a média calculada sobre a própria CTE.

✅ Checagem: **7 linhas**.

---

### Exercício 6 · Participação de cada categoria

**Pedido da Diretoria:** "Qual o **percentual** de cada categoria no faturamento total (por `LineTotal`)?"

- Use duas CTEs encadeadas: uma com o faturamento por categoria, outra com o total.
- Cuidado com divisão: `100 * a / b` com inteiros pode truncar. Use `100.0`.
- Arredonde para 2 casas com `CAST(... AS DECIMAL(5,2))`.

✅ Checagem: **4 linhas**, somando 100%.

---

### Exercício 7 · Segmentação de clientes 🧠

**Pedido do Marketing:** "Quero dividir os clientes por quanto já gastaram com a gente (somando `TotalDue`): **até 1 mil**, **1 mil a 10 mil**, **10 mil a 100 mil** e **acima de 100 mil**. Para cada faixa: quantos clientes, faturamento total e gasto médio."

- Etapa 1 (CTE): total gasto por cliente.
- Etapa 2 (CTE): classificar cada cliente com `CASE`.
- Etapa 3: agrupar por faixa.
- Dica: prefixe as faixas com "1.", "2." etc. para ordenar direito.
- 🧠 Que porcentagem dos clientes está na faixa mais alta, e que porcentagem do faturamento ela representa? O que isso significa para a estratégia comercial?

✅ Checagem: **4 linhas**.

---

### Exercício 8 · Dias sem venda (CTE recursiva)

**Pedido de Qualidade de Dados:** "Entre o primeiro pedido da história (**31/05/2011**) e **31/12/2011**, houve algum **dia sem nenhuma venda**? Quais, e em que dia da semana?"

- Gere um calendário com uma CTE recursiva (um dia por linha).
- Faça uma segunda CTE com os dias que tiveram pedido (`CAST(OrderDate AS DATE)`).
- Use `LEFT JOIN` + `IS NULL` para achar os buracos.
- Não esqueça `OPTION (MAXRECURSION 0)`: são mais de 100 dias.

✅ Checagem: **3 linhas**.

---

### Exercício 9 · Desafio: do que é feita uma bicicleta (BOM recursiva)

**Pedido da Engenharia:** "Quais são **todos os componentes**, em todos os níveis, da bike **'Road-150 Red, 62'** (ProductID 749)? Mostra o nível, o nome do componente e a quantidade por montagem."

- Tabela: `Production.BillOfMaterials`. Coluna `ProductAssemblyID` = o produto "pai", `ComponentID` = a peça.
- Considere só a estrutura vigente (`EndDate IS NULL`).
- Âncora: componentes diretos da 749. Parte recursiva: componentes dos componentes.

✅ Checagem: **89 linhas**.

---

## Desafio extra (sem gabarito)

Reescreva o exercício 4 sem subquery correlacionada: monte uma CTE com o `MAX(TotalDue)` por cliente e faça `JOIN`. Os resultados batem? No módulo 05 você vai fazer uma terceira versão com `ROW_NUMBER()`.
