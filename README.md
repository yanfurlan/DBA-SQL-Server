DBA SQL Server

Este repositório contém a resolução do teste prático, com foco em administração, segurança, performance e boas práticas no SQL Server.

## 🛠️ Tecnologias Utilizadas

- SQL Server 2019+
- SQL Server Management Studio (SSMS)
- T-SQL

---

## 📂 Estrutura de Pastas

```
.
├── 1. Restauração do Banco de Dados
├── 2. Análise de Performance e Otimização de Consulta
├── 3. Gestão de Segurança e Permissões
├── 4. Estratégia e Implementação de Backup
└── 5. Diagnóstico e Resolução de Problemas
```

---

## 🔍 Descrição das Atividades

### 1. Restauração do Banco de Dados

- Restauração do banco `WideWorldImporters-Full.bak` como `WWI_Avaliacao`
- Alteração do recovery model para `FULL`
- Verificação de integridade com `DBCC CHECKDB`
- Consulta simples para verificar acessibilidade (`COUNT(*) FROM Sales.Customers`)

### 2. Análise de Performance e Otimização de Consulta

- Análise de uma consulta lenta sobre faturas de um vendedor específico
- Verificação do plano de execução
- Criação de índice não-clusterizado
- Comparação de desempenho antes e depois

### 3. Gestão de Segurança e Permissões

- Criação de login e usuário `analista_dados`
- Permissões de leitura (SELECT) apenas nas tabelas do schema `Sales`
- Script de validação das permissões

### 4. Estratégia e Implementação de Backup

- Estratégia de backup com base no RPO de 15 minutos e RTO de 1 hora
- Scripts para backups:
  - FULL (diário)
  - DIFFERENTIAL (a cada 4 horas)
  - LOG (a cada 15 minutos)
- Passo a passo de restauração para ponto no tempo

### 5. Diagnóstico e Resolução de Problemas

- Investigação de crescimento inesperado do arquivo `.LDF`
- Uso de DMVs para identificar sessões abertas
- Backup de log e SHRINK emergencial com justificativa
- Medidas preventivas para evitar recorrência

---

## 🧑‍💻 Autor

**Yan Furlan**  
DBA e Desenvolvedor SQL  
[LinkedIn](https://www.linkedin.com/in/yan-furlan-455ab820b/) | [GitHub](https://github.com/yanfurlan)

---

## 📌 Observações

Cada pasta contém os scripts, análises e prints relacionados à atividade correspondente.

Este projeto demonstra habilidades práticas essenciais para a atuação como DBA SQL Server, incluindo restauração, tuning de queries, controle de acesso, estratégias de backup e troubleshooting.
