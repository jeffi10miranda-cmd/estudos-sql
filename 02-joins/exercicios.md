# 02 · Exercícios: JOINs

Cada exercício traz a **checagem** de linhas. Se não bateu, revise antes de olhar o [gabarito](gabarito.sql).

---

### Exercício 1 · Pedidos do dia com nome do cliente

**Pedido do Atendimento:** "Me passa os pedidos de **30/06/2014** com o **nome do cliente** (nome e sobrenome juntos) e o valor total, do maior para o menor."

- Caminho: `Sales.SalesOrderHeader` → `Sales.Customer` → `Person.Person`.
- Atenção: em `Customer` a coluna que aponta para a pessoa se chama `PersonID`, mas em `Person` ela se chama `BusinessEntityID`.

✅ Checagem: **40 linhas**.

---

### Exercício 2 · Árvore de produtos

**Pedido do Gerente de Produto:** "Quero ver cada produto com sua **subcategoria** e **categoria**, ordenado por categoria, subcategoria e produto. Só os produtos classificados."

- Três tabelas em cadeia: `Product` → `ProductSubcategory` → `ProductCategory`.
- Todas têm uma coluna `Name`. Dê apelidos claros.
- O catálogo tem 504 produtos. Quantos sobraram? Por quê?

✅ Checagem: **295 linhas**.

---

### Exercício 3 · Itens de um pedido

**Pedido do Financeiro:** "Abre o pedido **43659** item a item: produto, quantidade, preço unitário, desconto e total da linha."

- Tabelas: `Sales.SalesOrderDetail` e `Production.Product`.

✅ Checagem: **12 linhas**.

---

### Exercício 4 · Produtos encalhados

**Pedido do Estoque:** "Quais produtos **vendáveis** (preço maior que zero) **nunca apareceram em nenhum pedido**? Do mais caro para o mais barato."

- Isso é um **anti-join**: `LEFT JOIN` + filtro `IS NULL` na tabela da direita.
- Pense: em qual tabela deve estar o `IS NULL`? Em qual coluna?

✅ Checagem: **38 linhas**.

---

### Exercício 5 · Vendedores e seus territórios

**Pedido da Diretoria Comercial:** "Lista **todos** os vendedores com o território e as vendas no ano (`SalesYTD`). Quem não tem território deve aparecer como '(sem território)'."

- Tabelas: `Sales.SalesPerson`, `Person.Person`, `Sales.SalesTerritory`.
- Faça primeiro com `INNER JOIN` em território e conte as linhas. Depois troque para `LEFT JOIN`. Quem apareceu?
- Para trocar `NULL` por texto: `ISNULL(coluna, 'texto')` ou `COALESCE(coluna, 'texto')`.

✅ Checagem: **17 linhas** (com INNER seriam 14).

---

### Exercício 6 · Onde cada funcionário trabalha hoje

**Pedido do RH:** "Quero cada funcionário com nome, cargo, **departamento atual**, área (`GroupName`) e desde quando está nesse departamento."

- O histórico fica em `HumanResources.EmployeeDepartmentHistory`. Um funcionário pode ter passado por vários departamentos.
- A lotação atual é a linha em que `EndDate` está vazio.
- Tente colocar a condição do `EndDate` no `ON` e depois no `WHERE`. Para um `INNER JOIN`, muda alguma coisa?

✅ Checagem: **290 linhas** (um por funcionário).

---

### Exercício 7 · Nome de exibição de todos os clientes

**Pedido do CRM:** "Preciso de uma lista com **todos os clientes**: ID, número da conta, um **nome de exibição** e se é **Loja** ou **Pessoa física**."

- Regra do nome: se o cliente é uma loja, use o nome da loja (`Sales.Store.Name`); senão, nome e sobrenome da pessoa.
- `Sales.Customer` tem `StoreID` e `PersonID`; qualquer um dos dois pode ser `NULL`.
- Dica: dois `LEFT JOIN` e `COALESCE`.

✅ Checagem: **19.820 linhas**.

---

### Exercício 8 · Quem é o chefe de quem

**Pedido do RH:** "Monta o organograma: cada funcionário com seu cargo, o nome do **chefe direto** e o cargo do chefe. Quem não tem chefe aparece como '(sem chefe)'."

- Você vai juntar `HumanResources.Employee` **com ela mesma** (*self join*), usando apelidos diferentes, por exemplo `e` (funcionário) e `g` (gestor).
- A hierarquia está na coluna `OrganizationNode`, do tipo `hierarchyid`. O nó do chefe imediato é `e.OrganizationNode.GetAncestor(1)`.
- Você também vai precisar de `Person.Person` duas vezes: uma para o nome do funcionário, outra para o do chefe.

✅ Checagem: **290 linhas**.

---

## Desafio extra (sem gabarito)

**Prove o fan-out.** Some `TotalDue` de todos os pedidos de 2013 direto em `SalesOrderHeader`. Depois faça a mesma soma juntando com `SalesOrderDetail`. Quantas vezes maior ficou o segundo número? Explique o motivo em um comentário no seu arquivo.
