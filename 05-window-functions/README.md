# 05 · Window functions

> **Pergunta que este módulo responde:** "Quero comparar cada linha com o grupo dela, *sem perder a linha*."

`GROUP BY` resume: 1.000 pedidos viram 1 linha por cliente. Window functions calculam sobre um grupo **mas mantêm todas as linhas**. Com elas você faz ranking, acumulado, média móvel, comparação com o mês anterior e deduplicação. Em entrevista para engenharia ou análise de dados, é praticamente certo cair uma pergunta de window function.

## Anatomia

```sql
FUNCAO(...) OVER (
    PARTITION BY coluna      -- opcional: "recomeça para cada ..."
    ORDER BY coluna          -- ordem dentro da partição
    ROWS BETWEEN ... AND ... -- opcional: tamanho da janela (frame)
)
```

- Sem `PARTITION BY`, a janela é o resultado inteiro.
- Sem `ORDER BY`, funções de agregação (`SUM`, `AVG`) olham a partição inteira.
- Com `ORDER BY` e sem `ROWS`, o SQL Server usa `RANGE UNBOUNDED PRECEDING` por padrão: dá um acumulado, mas trata empates de forma surpreendente e é mais lento. **Escreva o `ROWS` explicitamente.**

## As famílias

| Família | Funções | Exemplo de pergunta |
|---|---|---|
| Ranking | `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `NTILE` | "Top 5 produtos de cada categoria" |
| Agregação | `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` com `OVER` | "Acumulado no ano", "% do total" |
| Deslocamento | `LAG`, `LEAD`, `FIRST_VALUE`, `LAST_VALUE` | "Quanto cresceu em relação ao mês anterior?" |

### ROW_NUMBER x RANK x DENSE_RANK

| Valor | ROW_NUMBER | RANK | DENSE_RANK |
|---|---|---|---|
| 100 | 1 | 1 | 1 |
| 100 | 2 | 1 | 1 |
| 90  | 3 | 3 | 2 |
| 80  | 4 | 4 | 3 |

## Onde a window function roda

```
FROM → WHERE → GROUP BY → HAVING → **window functions** → SELECT → ORDER BY
```

Duas consequências:

1. **Não dá para usar no `WHERE`.** Para filtrar por `ROW_NUMBER() = 1`, calcule numa CTE e filtre fora.
2. **Ela enxerga o resultado do `GROUP BY`.** Por isso `SUM(SUM(TotalDue)) OVER ()` funciona: o `SUM` de dentro agrega por grupo, o de fora soma os grupos.

## O padrão mais importante para engenharia de dados

**Deduplicação com `ROW_NUMBER`:**

```sql
WITH numerado AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY chave_negocio ORDER BY data_atualizacao DESC) AS rn
    FROM tabela_bruta
)
SELECT * FROM numerado WHERE rn = 1;   -- fica só a versão mais recente de cada registro
```

Você vai usar isto em pipelines toda vez que uma fonte mandar o mesmo registro mais de uma vez.

## Leia o dado antes de confiar no gráfico

Os exercícios 6 e 7 mostram variações mensais de +400% e −99%. Antes de concluir qualquer coisa, investigue: **os pedidos de revenda do AdventureWorks são lançados concentrados nos dias 30, 31 e 1**, e **param em 01/05/2014**. Uma variação absurda quase sempre é problema (ou característica) do dado, não do negócio. Investigar isso é parte do trabalho.

## Como estudar

Resolva [exercicios.md](exercicios.md) e compare com o [gabarito.sql](gabarito.sql). Nos exercícios de ranking, troque `RANK` por `ROW_NUMBER` e `DENSE_RANK` e observe a diferença.
