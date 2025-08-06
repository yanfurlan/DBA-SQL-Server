--1. Restauração do Banco de Dados
--

RESTORE FILELISTONLY 
FROM DISK = '/backup/backup.bak';


--

USE [master];
GO

-- Verificar se o banco já existe e, se existir, removê-lo
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'WWI_Avaliacao')
BEGIN
    ALTER DATABASE [WWI_Avaliacao] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [WWI_Avaliacao];
END
GO

-- Restaurar o banco de dados a partir do backup com os arquivos corretos
RESTORE DATABASE [WWI_Avaliacao] 
FROM DISK = '/backup/backup.bak'
WITH 
    MOVE 'WWI_Primary' TO '/var/opt/mssql/data/WWI_Avaliacao.mdf',
    MOVE 'WWI_UserData' TO '/var/opt/mssql/data/WWI_Avaliacao_UserData.ndf',
    MOVE 'WWI_Log' TO '/var/opt/mssql/data/WWI_Avaliacao.ldf',
    MOVE 'WWI_InMemory_Data_1' TO '/var/opt/mssql/data/WWI_Avaliacao_InMemory_Data_1',
    STATS = 5;
GO

--RESTORE DATABASE successfully processed 58496 pages in 0.442 seconds (1033.923 MB/sec).

--Horário de conclusão: 2025-07-22T12:24:17.4402805-03:00

--

-- Alterar o recovery model para FULL
ALTER DATABASE [WWI_Avaliacao] SET RECOVERY FULL;
GO

--Comandos concluídos com êxito.

--Horário de conclusão: 2025-07-22T12:25:17.1851726-03:00

-- Verificar integridade
USE [WWI_Avaliacao];
GO
DBCC CHECKDB WITH NO_INFOMSGS;
GO


--Comandos concluídos com êxito.

--Horário de conclusão: 2025-07-22T12:25:35.3421588-03:00

-- Contar clientes
SELECT COUNT(*) AS TotalClientes FROM Sales.Customers;
GO

--663
