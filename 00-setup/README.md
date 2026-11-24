# 00 · Ambiente: SQL Server + AdventureWorks no Docker

Objetivo: em uns 15 minutos, ter um SQL Server 2022 rodando na sua máquina, com o banco de exemplo **AdventureWorks2022** restaurado e um editor conectado.

> Por que Docker? Você não instala o SQL Server "de verdade" no seu sistema. Se algo der errado, apaga o container e começa de novo. É também como bancos rodam em muitos ambientes de engenharia de dados, então já é prática útil.

---

## 1. Pré-requisitos

| Item | Onde baixar | Observação |
|---|---|---|
| Docker Desktop | https://www.docker.com/products/docker-desktop/ | No Windows, ative o WSL 2 quando o instalador pedir. |
| Editor SQL | **VS Code** + extensão **SQL Server (mssql)**, ou **SSMS** (só Windows) | O Azure Data Studio foi descontinuado; prefira um dos dois. |
| ~4 GB de RAM livres | | O SQL Server exige no mínimo 2 GB para o container. |

> **Mac com Apple Silicon (M1/M2/M3/M4):** a imagem do SQL Server é x86. No Docker Desktop, ative *Settings → General → "Use Rosetta for x86_64/amd64 emulation"* e acrescente `--platform linux/amd64` no comando `docker run` abaixo.

---

## 2. Subir o SQL Server

Escolha uma senha forte (mínimo 8 caracteres, com maiúscula, minúscula, número e símbolo). Nos exemplos usamos `Estudos@SQL2022`; troque pela sua.

**Windows (PowerShell):**

```powershell
docker run -d --name sql-estudos `
  -e "ACCEPT_EULA=Y" `
  -e "MSSQL_SA_PASSWORD=Estudos@SQL2022" `
  -p 1433:1433 `
  -v sql-estudos-data:/var/opt/mssql `
  mcr.microsoft.com/mssql/server:2022-latest
```

**Mac / Linux (bash/zsh):**

```bash
docker run -d --name sql-estudos \
  -e "ACCEPT_EULA=Y" \
  -e "MSSQL_SA_PASSWORD=Estudos@SQL2022" \
  -p 1433:1433 \
  -v sql-estudos-data:/var/opt/mssql \
  mcr.microsoft.com/mssql/server:2022-latest
```

O `-v sql-estudos-data:/var/opt/mssql` cria um *volume*: seus dados sobrevivem se você parar ou recriar o container.

Confira se subiu (espere ~30 s):

```bash
docker logs sql-estudos | grep "ready for client connections"
```

No PowerShell, troque `grep` por `Select-String`.

---

## 3. Baixar e restaurar o AdventureWorks2022

**3.1 Baixe o backup** (≈200 MB) do repositório oficial da Microsoft:

https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak

**3.2 Copie o arquivo para dentro do container** (rode na pasta onde o `.bak` foi salvo):

```bash
docker exec sql-estudos mkdir -p /var/opt/mssql/backup
docker cp AdventureWorks2022.bak sql-estudos:/var/opt/mssql/backup/
```

**3.3 Restaure o banco.** A imagem já traz o `sqlcmd`; o `-C` aceita o certificado autoassinado do servidor:

```bash
docker exec sql-estudos /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Estudos@SQL2022" -C -Q "RESTORE DATABASE AdventureWorks2022 FROM DISK = '/var/opt/mssql/backup/AdventureWorks2022.bak' WITH MOVE 'AdventureWorks2022' TO '/var/opt/mssql/data/AdventureWorks2022.mdf', MOVE 'AdventureWorks2022_log' TO '/var/opt/mssql/data/AdventureWorks2022_log.ldf'"
```

A saída deve terminar com `RESTORE DATABASE successfully processed ...`.

---

## 4. Conectar o editor

| Campo | Valor |
|---|---|
| Server | `localhost,1433` |
| Authentication | SQL Login |
| User | `sa` |
| Password | a senha que você escolheu |
| Database | `AdventureWorks2022` |
| Trust server certificate | **Sim / marcado** (sem isso a conexão falha) |

**Teste de sanidade.** Rode isto; deve retornar `2011-05-31`, `2014-06-30` e `31465`:

```sql
USE AdventureWorks2022;
SELECT MIN(OrderDate) AS primeiro_pedido,
       MAX(OrderDate) AS ultimo_pedido,
       COUNT(*)       AS total_pedidos
FROM Sales.SalesOrderHeader;
```

Se bateu, está pronto para o [módulo 01](../01-select-filtros/README.md).

---

## 5. Comandos do dia a dia

```bash
docker stop sql-estudos     # desliga (dados ficam no volume)
docker start sql-estudos    # liga de novo
docker rm -f sql-estudos    # apaga o container (o volume continua)
docker volume rm sql-estudos-data   # apaga os dados de vez
```

---

## 6. Problemas comuns

| Sintoma | Causa provável | Solução |
|---|---|---|
| Container sobe e morre em segundos | Senha fraca | `docker logs sql-estudos` mostra o erro. Recrie com senha mais forte. |
| `port is already allocated` | Já existe um SQL Server na 1433 | Use `-p 1434:1433` e conecte em `localhost,1434`. |
| `certificate chain was issued by an authority that is not trusted` | Certificado autoassinado | Marque *Trust server certificate*. |
| `sqlcmd: no such file or directory` | Imagem antiga (tools sem o "18") | Use `/opt/mssql-tools/bin/sqlcmd` e remova o `-C`. |
| Mac M1+ trava ou fica lento | Emulação x86 | Confirme o Rosetta ligado e `--platform linux/amd64`. |

---

## 7. Mapa rápido do AdventureWorks

É o banco **transacional (OLTP)** de uma fabricante fictícia de bicicletas. Os schemas que você mais vai usar:

| Schema | Tabelas-chave | Para que serve |
|---|---|---|
| `Sales` | `SalesOrderHeader`, `SalesOrderDetail`, `Customer`, `SalesPerson`, `SalesTerritory`, `Store` | Pedidos, itens, clientes, vendedores, regiões |
| `Production` | `Product`, `ProductSubcategory`, `ProductCategory`, `ProductInventory`, `ProductReview` | Catálogo e estoque |
| `Person` | `Person`, `EmailAddress`, `Address` | Dados de pessoas (clientes, funcionários, contatos) |
| `HumanResources` | `Employee`, `Department`, `EmployeeDepartmentHistory`, `EmployeePayHistory` | RH |
| `Purchasing` | `Vendor`, `PurchaseOrderHeader`, `ProductVendor` | Compras de fornecedores |

Duas pegadinhas que aparecem nos exercícios:

- **Datas vão de mai/2011 a jun/2014.** 2011 e 2014 são anos incompletos; cuidado ao comparar anos.
- **`BusinessEntityID`** é a chave "universal" de pessoa: `Person.Person.BusinessEntityID` = `HumanResources.Employee.BusinessEntityID` = `Sales.SalesPerson.BusinessEntityID`. Já `Sales.Customer` liga em `Person` pela coluna `PersonID`.
