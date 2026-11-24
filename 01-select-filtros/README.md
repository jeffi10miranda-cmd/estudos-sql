# 01 · SELECT e filtros

> **Pergunta que este módulo responde:** "Me traga *estas* colunas, *destas* linhas, *nesta* ordem."

Quase toda consulta que você vai escrever na carreira começa aqui. Engenheiro de dados filtra dados o dia inteiro: para validar uma carga, investigar um registro estranho, montar a extração de uma pipeline. Errar um filtro (principalmente com `NULL` e datas) é a fonte número 1 de números errados em relatório.

## O que você vai aprender

| Conceito | Para que serve |
|---|---|
| `SELECT` colunas `AS` apelido | Escolher e renomear o que sai |
| `FROM` schema.tabela | De onde vem o dado |
| `WHERE` | Quais linhas entram |
| `AND`, `OR`, `NOT`, parênteses | Combinar condições |
| `IN`, `BETWEEN`, `LIKE` | Atalhos de filtro |
| `IS NULL` / `IS NOT NULL` | Testar ausência de valor |
| `ORDER BY ... ASC/DESC` | Ordenar o resultado |
| `TOP (n)` e `WITH TIES` | Limitar linhas |
| `DISTINCT` | Remover linhas repetidas |
| `CASE WHEN` | Criar colunas com regra de negócio |

## Ordem de execução (decore isto)

Você **escreve** nesta ordem:

```sql
SELECT ... FROM ... WHERE ... ORDER BY ...
```

O banco **executa** nesta:

```
FROM  →  WHERE  →  SELECT  →  ORDER BY  →  TOP
```

Consequência prática: um apelido criado no `SELECT` **não existe** ainda no `WHERE`, mas **existe** no `ORDER BY`.

```sql
-- ERRO: preco_tabela não existe no WHERE
SELECT ListPrice AS preco_tabela FROM Production.Product WHERE preco_tabela > 100;

-- OK
SELECT ListPrice AS preco_tabela FROM Production.Product WHERE ListPrice > 100 ORDER BY preco_tabela;
```

## Três armadilhas que derrubam muita gente

**1. `NULL` não é igual a nada, nem a ele mesmo.**

```sql
WHERE Color = NULL      -- nunca retorna linhas
WHERE Color IS NULL     -- correto
WHERE Color <> 'Red'    -- NÃO traz os produtos sem cor!
```

**2. Datas com hora.** `OrderDate BETWEEN '2013-01-01' AND '2013-03-31'` perde tudo que aconteceu em 31/03 depois da meia-noite, se a coluna tiver hora. Prefira o intervalo semiaberto:

```sql
WHERE OrderDate >= '2013-01-01' AND OrderDate < '2013-04-01'
```

**3. `AND` tem precedência sobre `OR`.** Na dúvida, use parênteses.

```sql
-- Traz TODOS os vermelhos + os pretos caros (provavelmente não é o que você quis)
WHERE Color = 'Red' OR Color = 'Black' AND ListPrice > 1000
-- O que você quis
WHERE (Color = 'Red' OR Color = 'Black') AND ListPrice > 1000
```

## Tabelas usadas

- `Production.Product`: catálogo (nome, cor, preço de tabela, datas de venda)
- `Sales.SalesOrderHeader`: cabeçalho dos pedidos (data, cliente, valor total)
- `HumanResources.Employee`: funcionários

Dica: antes de resolver, rode `SELECT TOP (20) * FROM Production.Product;` para conhecer as colunas. Em produção, nunca use `SELECT *` em código final; para explorar, tudo bem.

## Como estudar

1. Leia este README.
2. Resolva [exercicios.md](exercicios.md) sozinho. Cada exercício diz quantas linhas o resultado deve ter: use isso para se autocorrigir.
3. Só depois abra [gabarito.sql](gabarito.sql) e compare. Leia os comentários: eles explicam o *porquê*.
4. Salve suas respostas em `minhas-respostas.sql` nesta pasta e faça commit. Seu histórico de estudo vira portfólio.
