-- Atividade 5: Diagnóstico e Resolução de Problemas
-- Objetivo: Avaliar habilidades de troubleshooting do DBA para crescimento inesperado do arquivo de log (.LDF)

-- 1. Diagnóstico da Causa
-- Utilização de DMVs para identificar transações abertas e consumo de log.

-- Consulta para identificar sessões e transações ativas no banco WWI_Avaliacao que possam estar impedindo a liberação do log:
SELECT 
    ses.session_id,
    ses.login_name,
    ses.status AS session_status,
    ses.host_name,
    req.command,
    req.status AS request_status,
    req.start_time AS request_start_time,
    DATEDIFF(MINUTE, req.start_time, GETDATE()) AS DurationMinutes,
    at.transaction_begin_time
FROM sys.dm_exec_sessions AS ses
LEFT JOIN sys.dm_exec_requests AS req ON ses.session_id = req.session_id
INNER JOIN sys.dm_tran_session_transactions AS tran_sess ON ses.session_id = tran_sess.session_id
INNER JOIN sys.dm_tran_database_transactions AS tran_db ON tran_sess.transaction_id = tran_db.transaction_id
INNER JOIN sys.dm_tran_active_transactions AS at ON tran_sess.transaction_id = at.transaction_id
WHERE tran_db.database_id = DB_ID('WWI_Avaliacao')
  AND ses.is_user_process = 1
ORDER BY DurationMinutes DESC;

-- 2. Identificação de Sessões Problemáticas
-- Consulta para identificar sessões ativas que estejam impedindo a reutilização do log (liberação dos VLFs - Virtual Log Files):

SELECT 
    tdt.transaction_id,
    tdt.database_transaction_begin_time,
    tdt.database_transaction_log_record_count,
    ses.session_id,
    ses.login_name,
    ses.host_name,
    ses.status,
    ses.program_name,
    req.command,
    req.status AS request_status,
    req.wait_type,
    req.wait_time
FROM sys.dm_tran_database_transactions tdt
JOIN sys.dm_tran_session_transactions tst ON tdt.transaction_id = tst.transaction_id
JOIN sys.dm_exec_sessions ses ON tst.session_id = ses.session_id
LEFT JOIN sys.dm_exec_requests req ON ses.session_id = req.session_id
WHERE tdt.database_id = DB_ID('WWI_Avaliacao')
  AND tdt.database_transaction_log_record_count > 0
  AND ses.status = 'running'
ORDER BY tdt.database_transaction_begin_time ASC;

-- 3. Plano de Ação para resolver o problema imediato:

-- a) Realizar backup do log de transações para liberar espaço no arquivo .LDF:
DECLARE @DataHora NVARCHAR(20) = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
DECLARE @Caminho NVARCHAR(200) = '/var/opt/mssql/data/WWI_Avaliacao_LOG_Backup_' + @DataHora + '.trn';
DECLARE @SQL NVARCHAR(MAX) = '
    BACKUP LOG WWI_Avaliacao
    TO DISK = N''' + @Caminho + '''
    WITH INIT, COMPRESSION, STATS = 10;';
EXEC(@SQL);

-- b) Identificar o nome lógico do arquivo de log:
USE WWI_Avaliacao;
GO
SELECT name, type_desc, physical_name
FROM sys.database_files;

-- c) Após o backup do log, executar o SHRINKFILE com o nome lógico correto do arquivo de log:
-- Nome lógico confirmado: WWI_Log
USE WWI_Avaliacao;
GO
DBCC SHRINKFILE (WWI_Log, 1024);  -- reduz para 1024 MB
GO

-- 4. Medidas preventivas recomendadas:

-- a) Manter backups regulares do log de transações (agendados via SQL Server Agent ou outro método)
-- b) Monitorar transações longas e sessões ativas que possam causar crescimento do log
-- c) Avaliar a configuração do modelo de recuperação do banco (FULL, BULK_LOGGED, SIMPLE)
-- d) Configurar alertas para crescimento excessivo do arquivo de log
-- e) Utilizar a DMV sys.dm_db_log_stats (SQL Server 2019+) para análises mais detalhadas do uso do log

-- 5. Justificativa:

-- O backup do log de transações é essencial para permitir a reutilização dos VLFs e evitar crescimento contínuo do arquivo de log.
-- Sem o backup, o log não é truncado, e o arquivo cresce consumindo espaço em disco.

-- A operação de SHRINKFILE deve ser usada com cautela, pois pode causar fragmentação e impacto na performance.
-- É recomendada apenas após o backup do log e quando há espaço real a ser liberado.