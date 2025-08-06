Atividade 3: Gestão de Segurança e Permissões

-- 1. Criação do Login no nível do servidor
CREATE LOGIN analista_dados 
WITH PASSWORD = 'QpalBq2V5!HU5wmSurZ';
GO

-- 2. Criar usuário no banco de dados WWI_Avaliacao
USE WWI_Avaliacao;
GO

CREATE USER analista_dados FOR LOGIN analista_dados;
GO

-- 3. Conceder permissões SELECT apenas nas tabelas autorizadas
GRANT SELECT ON Sales.Customers TO analista_dados;
GRANT SELECT ON Sales.Invoices TO analista_dados;
GRANT SELECT ON Sales.InvoiceLines TO analista_dados;
GO

-- 4. Script de validação: testar permissões com SELECTs
-- Esperado: sucesso
SELECT TOP 5 * FROM Sales.Customers;
SELECT TOP 5 * FROM Sales.Invoices;
SELECT TOP 5 * FROM Sales.InvoiceLines;

-- Esperado: erro de permissão
SELECT TOP 5 * FROM Warehouse.StockItems;

Estou anexando as prints comprovando sucesso e erro de permissão pelo usuário.