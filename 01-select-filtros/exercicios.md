# 01 · Exercícios: SELECT e filtros

Contexto: você acabou de entrar no time de dados da Adventure Works, uma fabricante de bicicletas. As áreas de negócio começam a te mandar pedidos.

Cada exercício traz a **checagem** (quantas linhas o resultado deve ter). Se não bateu, revise o filtro antes de olhar o [gabarito](gabarito.sql).

---

### Exercício 1 · Catálogo de preços

**Pedido do Comercial:** "Preciso do catálogo de produtos que a gente vende, com código, nome e preço de tabela, do mais caro para o mais barato."

- Tabela: `Production.Product`
- Produto com `ListPrice = 0` não é vendido (é peça interna).
- Em caso de empate de preço, ordene pelo nome.

✅ Checagem: **304 linhas**.

---

### Exercício 2 · Os 10 produtos mais caros

**Pedido do Marketing:** "Quais são os 10 produtos mais caros? Vamos fazer uma vitrine premium."

- Mostre nome e preço.
- Pense: e se o 10º e o 11º tiverem o mesmo preço? Quem entra? Descubra o que `WITH TIES` faz.

✅ Checagem: **10 linhas** sem `WITH TIES`, **13 linhas** com.

---

### Exercício 3 · Cores do catálogo

**Pedido do Design:** "Quais cores de produto a gente tem hoje? Lista sem repetição, em ordem alfabética."

- Não traga "sem cor" como se fosse uma cor.

✅ Checagem: **9 linhas**.

---

### Exercício 4 · Campanha de produtos vermelhos ou pretos

**Pedido do Marketing:** "Vamos fazer uma campanha com produtos **vermelhos ou pretos** com preço **entre 500 e 1.500** (inclusive). Me passa nome, cor e preço, do mais caro para o mais barato."

- Tente escrever com `IN` e `BETWEEN`.
- Depois reescreva só com `OR`, `>=` e `<=`. O resultado tem que ser igual. Cuidado com os parênteses.

✅ Checagem: **51 linhas**.

---

### Exercício 5 · Linha Mountain

**Pedido do Gerente de Produto:** "Quero a lista dos produtos vendáveis cujo nome **começa com** 'Mountain'."

- Teste também com o curinga no começo e no fim e compare a contagem. Por que mudou?

✅ Checagem: **37 linhas**.

---

### Exercício 6 · Cadastro incompleto

**Pedido de Qualidade de Dados:** "Quais produtos vendáveis estão **sem cor cadastrada**? Ordene do mais caro para o mais barato."

- Tente primeiro com `= NULL` e veja o que acontece. Depois corrija.

✅ Checagem: **59 linhas**.

---

### Exercício 7 · Pedidos grandes no 1º trimestre de 2013

**Pedido do Financeiro:** "Quais pedidos do **primeiro trimestre de 2013** tiveram valor total **acima de 50 mil**? Quero número do pedido, data, cliente e valor, do maior para o menor."

- Tabela: `Sales.SalesOrderHeader`. Valor total = `TotalDue`.
- Filtre a data com intervalo semiaberto (`>=` e `<`). Leia o README se não lembrar por quê.

✅ Checagem: **46 linhas**.

---

### Exercício 8 · Faixa de preço

**Pedido do Comercial:** "Classifica cada produto vendável em uma faixa: **Econômico** (abaixo de 100), **Intermediário** (de 100 até abaixo de 1.000) e **Premium** (1.000 ou mais)."

- Mostre nome, preço e a faixa. Ordene por preço.
- Pense: se você inverter a ordem dos `WHEN`, o resultado muda?

✅ Checagem: **304 linhas**.

---

### Exercício 9 · Férias acumuladas

**Pedido do RH:** "Quais funcionários **ativos** têm **mais de 80 horas** de férias acumuladas? Mostra o ID, cargo, data de contratação e horas, do maior saldo para o menor."

- Tabela: `HumanResources.Employee`. Funcionário ativo: `CurrentFlag = 1`.

✅ Checagem: **57 linhas**.

---

### Exercício 10 · Produtos fora de linha

**Pedido do Estoque:** "Quais produtos **já pararam de ser vendidos**? Quero nome, início e fim da venda, e o preço, ordenado pela data de fim e depois pelo nome."

- Dica: olhe a coluna `SellEndDate`.

✅ Checagem: **98 linhas**.

---

## Desafio extra (sem gabarito)

Escreva uma consulta que encontre **pedidos de 2014 sem vendedor associado** (`SalesPersonID`) com valor acima de 3 mil. O que isso diz sobre o canal de venda desses pedidos? Dica: compare com a coluna `OnlineOrderFlag`.
