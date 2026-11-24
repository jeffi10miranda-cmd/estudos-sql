# 05 · Exercícios: Window functions

Cada exercício traz a **checagem** de linhas. Nos marcados com 🧠, escreva também uma frase interpretando o resultado. Depois compare com o [gabarito](gabarito.sql).

---

### Exercício 1 · Numerar as compras de cada cliente

**Pedido do CRM:** "Para os clientes **11000**, **11091** e **29825**, lista todos os pedidos numerando a compra: 1ª compra, 2ª compra, e assim por diante."

- `ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate, SalesOrderID)`.
- Por que incluir `SalesOrderID` no `ORDER BY` da janela? (Pense em dois pedidos do mesmo cliente no mesmo dia.)

✅ Checagem: **43 linhas**.

---

### Exercício 2 · Novos clientes por ano 🧠

**Pedido da Diretoria:** "Quantos **clientes novos** (primeira compra) tivemos por ano, e qual o **ticket médio da primeira compra**?"

- Numere as compras de cada cliente numa CTE e filtre `rn = 1` fora dela.
- Depois agrupe por ano.
- 🧠 O ticket da primeira compra caiu muito ao longo dos anos. Usando o que você descobriu no módulo 03 (canais online x vendedor), qual a explicação mais provável?

✅ Checagem: **4 linhas**. A soma dos novos clientes deve bater com o número de clientes distintos (19.119).

---

### Exercício 3 · Top 5 por categoria

**Pedido do Gerente de Produto:** "Quais os **5 produtos que mais faturaram** (por `LineTotal`) **em cada categoria**?"

- Agrupe por categoria e produto, e aplique `RANK() OVER (PARTITION BY categoria ORDER BY SUM(LineTotal) DESC)` na mesma consulta.
- Filtre `posicao <= 5` numa consulta externa.
- Troque `RANK` por `ROW_NUMBER` e `DENSE_RANK`. Muda algo aqui? Em que situação mudaria?

✅ Checagem: **20 linhas**.

---

### Exercício 4 · Acumulado no ano

**Pedido do Financeiro:** "Mês a mês em **2013**: o faturamento do mês e o **acumulado no ano** até aquele mês."

- Primeiro agregue por mês (CTE). Depois `SUM(faturamento) OVER (ORDER BY mes ROWS UNBOUNDED PRECEDING)`.
- O acumulado de dezembro deve bater com o faturamento de 2013 do módulo 03.

✅ Checagem: **12 linhas**.

---

### Exercício 5 · Participação de cada território

**Pedido da Diretoria Comercial:** "Faturamento de cada território (histórico completo), o **% do total da empresa** e o **% dentro da própria região**."

- Faça numa consulta só, com `GROUP BY` e window functions sobre o resultado agregado.
- % do total: `SUM(SUM(TotalDue)) OVER ()`.
- % da região: mesma ideia, com `PARTITION BY st.[Group]`.
- Compare com o exercício 6 do módulo 04, que precisou de duas CTEs.

✅ Checagem: **10 linhas**.

---

### Exercício 6 · Crescimento mês contra mês 🧠

**Pedido do Financeiro:** "Para todos os meses da história: faturamento, faturamento do mês anterior e **variação percentual**."

- `LAG(faturamento) OVER (ORDER BY mes)`.
- Proteja a divisão com `NULLIF(..., 0)`.
- 🧠 Junho de 2014 mostra queda de 99%. A empresa quebrou? Investigue: qual foi o último pedido com `OnlineOrderFlag = 0`? E em que dias do mês os pedidos de vendedor costumam ser lançados?

✅ Checagem: **38 linhas**.

---

### Exercício 7 · Média móvel de 3 meses

**Pedido do Financeiro:** "O faturamento mensal oscila demais. Me dá uma **média móvel de 3 meses** para enxergar a tendência."

- `AVG(faturamento) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)`.
- Os 2 primeiros meses não têm 3 meses na janela. Mostre quantos meses entraram em cada média, para ninguém ser enganado.

✅ Checagem: **38 linhas**.

---

### Exercício 8 · Quartis de clientes 🧠

**Pedido do Marketing:** "Divide os clientes em **4 grupos de mesmo tamanho** pelo total gasto. Para cada quartil: quantos clientes, menor e maior gasto, faturamento e **% do faturamento total**."

- `NTILE(4) OVER (ORDER BY total_gasto DESC)`.
- 🧠 Quanto do faturamento vem dos 25% melhores clientes? Compare com a segmentação por faixas fixas do módulo 04, exercício 7. Qual das duas abordagens você levaria para o Marketing, e por quê?

✅ Checagem: **4 linhas**.

---

### Exercício 9 · Tempo entre compras 🧠

**Pedido do CRM:** "Nos pedidos do **site** (`OnlineOrderFlag = 1`), quanto tempo um cliente leva, em média, para **comprar de novo**? Quero: quantas recompras houve, quantos clientes recompraram, média de dias entre compras, mínimo e máximo."

- Em uma CTE, traga para cada pedido a data da compra anterior **do mesmo cliente** com `LAG(...) OVER (PARTITION BY CustomerID ...)`.
- Fora da CTE, ignore as primeiras compras (`compra_anterior IS NULL`) e agregue.
- `DATEDIFF(DAY, inicio, fim)` devolve inteiro; multiplique por `1.0` antes do `AVG` para não truncar.
- 🧠 Com essa média, depois de quantos dias sem comprar você consideraria um cliente "em risco"?

✅ Checagem: **1 linha**.

---

## Desafio extra (sem gabarito)

Volte ao exercício 4 do módulo 04 ("o maior pedido da vida do cliente") e resolva com `ROW_NUMBER()`. Depois, ative *Include Actual Execution Plan* no seu editor (ou rode `SET STATISTICS IO ON;`) e compare as duas versões. Qual leu menos páginas?
