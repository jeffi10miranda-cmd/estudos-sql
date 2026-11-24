# 03 · Exercícios: GROUP BY e agregações

Cada exercício traz a **checagem** de linhas. Nos marcados com 🧠, escreva também uma frase interpretando o resultado. Depois compare com o [gabarito](gabarito.sql).

---

### Exercício 1 · Resultado por ano 🧠

**Pedido da Diretoria:** "Quantos pedidos, quanto faturamos e qual o ticket médio **por ano**?"

- Faturamento = `SUM(TotalDue)`. Ticket médio = `AVG(TotalDue)`.
- 🧠 O faturamento de 2014 caiu em relação a 2013? Antes de responder, confira quais meses existem em 2014. E o que aconteceu com o ticket médio a partir de 2013?

✅ Checagem: **4 linhas**.

---

### Exercício 2 · Faturamento por categoria

**Pedido do Gerente de Produto:** "Quanto cada **categoria** vendeu, em unidades e em valor? Da maior para a menor."

- Comece em `Sales.SalesOrderDetail` (valor do item = `LineTotal`, unidades = `OrderQty`) e junte até `ProductCategory`.
- Por que aqui não há fan-out?

✅ Checagem: **4 linhas**. Bikes deve aparecer em primeiro, com cerca de 94,6 milhões.

---

### Exercício 3 · Ticket médio por território 🧠

**Pedido da Diretoria Comercial:** "Qual território tem o **maior ticket médio**? Quero território, região (`Group`), quantidade de pedidos, faturamento e ticket médio."

- Tabelas: `Sales.SalesOrderHeader` e `Sales.SalesTerritory`.
- A coluna `Group` é palavra reservada: escreva `st.[Group]`.
- 🧠 O território com maior faturamento é o mesmo com maior ticket médio? O que isso sugere sobre o perfil de cliente de cada um?

✅ Checagem: **10 linhas**.

---

### Exercício 4 · Subcategorias milionárias

**Pedido do Gerente de Produto:** "Quais **subcategorias** faturaram **mais de 1 milhão** (somando `LineTotal`)?"

- Use `HAVING`. Tente colocar o filtro no `WHERE` e leia o erro.

✅ Checagem: **6 linhas**.

---

### Exercício 5 · Clientes mais frequentes

**Pedido do CRM:** "Quem são os clientes com **20 pedidos ou mais**? Quero quantidade de pedidos, total gasto, primeira e última compra."

- Ordene por quantidade de pedidos e, no empate, por total gasto.

✅ Checagem: **14 linhas**.

---

### Exercício 6 · Online x Vendedor 🧠

**Pedido da Diretoria:** "Por ano, quantos pedidos e quanto faturamento vieram do **site** e quantos vieram **via vendedor**? Tudo numa linha por ano."

- Coluna `OnlineOrderFlag`: 1 = site, 0 = vendedor.
- Use agregação condicional: `SUM(CASE WHEN ... THEN ... ELSE 0 END)`.
- 🧠 Qual canal tem mais pedidos? Qual traz mais dinheiro? Isso explica o que você viu no ticket médio do exercício 1?

✅ Checagem: **4 linhas**.

---

### Exercício 7 · Contando direito

**Pedido de Qualidade de Dados:** "Numa linha só: total de pedidos, quantos pedidos têm vendedor, quantos **vendedores diferentes** e quantos **clientes diferentes** compraram."

- Compare `COUNT(*)`, `COUNT(SalesPersonID)` e `COUNT(DISTINCT SalesPersonID)`.

✅ Checagem: **1 linha**. Total de pedidos = 31.465.

---

### Exercício 8 · Faturamento mensal de 2013

**Pedido do Financeiro:** "Preciso do faturamento e da quantidade de pedidos **mês a mês em 2013**, com o mês como data (primeiro dia do mês)."

- Filtre 2013 com intervalo semiaberto no `WHERE`.
- Para o mês: `DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1)`. Lembre de repetir a expressão no `GROUP BY`.

✅ Checagem: **12 linhas**.

---

### Exercício 9 · Relatório com subtotais

**Pedido do Financeiro:** "Faturamento de **2013** por **região** e **território**, com **subtotal por região** e **total geral** no fim."

- Use `GROUP BY ROLLUP(st.[Group], st.Name)`.
- Use `GROUPING()` para trocar os `NULL` dos subtotais por rótulos como "* subtotal *" e "** TOTAL GERAL **".

✅ Checagem: **14 linhas** (10 territórios + 3 subtotais + 1 total).

---

## Desafio extra (sem gabarito)

Calcule a **média mensal** de faturamento de 2013 e de 2014 (só os meses que existem em cada ano) e diga se a empresa cresceu ou encolheu. Compare com a conclusão que você teria tirado olhando só o total anual.
