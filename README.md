# estudos-sql

Estudo de SQL para análise e engenharia de dados com **SQL Server**, usando o banco de exemplo **AdventureWorks2022**.

A trilha vai do `SELECT` básico até window functions. Cada exercício é um **pedido de negócio** (como chegaria de uma área da empresa), não um "escreva um JOIN". O objetivo é treinar as duas coisas que o mercado cobra: escrever a consulta certa e **saber ler o número que ela devolve**.

## Trilha

| # | Módulo | Você aprende | Exercícios |
|---|---|---|---|
| 00 | [Ambiente](00-setup/README.md) | SQL Server no Docker, restaurar o AdventureWorks, conectar o editor | — |
| 01 | [SELECT e filtros](01-select-filtros/README.md) | `WHERE`, `IN`, `BETWEEN`, `LIKE`, `NULL`, `CASE`, `TOP` | 10 |
| 02 | [JOINs](02-joins/README.md) | `INNER`, `LEFT`, anti-join, self join, fan-out | 8 |
| 03 | [GROUP BY](03-group-by/README.md) | Agregações, `HAVING`, agregação condicional, `ROLLUP` | 9 |
| 04 | [Subqueries e CTEs](04-subqueries-cte/README.md) | Subquery escalar e correlacionada, `EXISTS`, armadilha do `NOT IN`, CTE, CTE recursiva | 9 |
| 05 | [Window functions](05-window-functions/README.md) | `ROW_NUMBER`, `RANK`, `LAG`, acumulado, média móvel, `NTILE`, deduplicação | 9 |

## Como cada módulo funciona

```
0X-modulo/
├── README.md        → teoria curta + armadilhas comuns
├── exercicios.md    → pedidos de negócio, cada um com a contagem de linhas esperada
└── gabarito.sql     → respostas comentadas (abra só depois de tentar!)
```

1. Leia o `README.md` do módulo.
2. Resolva o `exercicios.md`. Use a **checagem de linhas** de cada exercício para se autocorrigir.
3. Exercícios com 🧠 pedem uma frase de interpretação do resultado. Não pule: é isso que separa quem escreve SQL de quem entende dados.
4. Compare com o `gabarito.sql`. Leia os comentários, eles explicam o *porquê*.
5. Salve suas respostas em `minhas-respostas.sql` dentro da pasta do módulo e faça commit. O histórico vira portfólio.

## Começar

👉 [00 · Ambiente](00-setup/README.md): uns 15 minutos para ter tudo rodando.

## Notas

- Todos os gabaritos foram executados contra o AdventureWorks2022 (OLTP) restaurado no SQL Server 2022; as contagens de linhas nos exercícios vêm dessas execuções.
- O AdventureWorks é um banco **transacional**. Data warehouse, modelagem dimensional e pipelines ficam para as próximas etapas da trilha.
