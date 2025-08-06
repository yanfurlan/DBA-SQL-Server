-- Atividade 4: Estratégia e Implementação de Backup

-- Diretório de Backup
EXEC xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory';

-- Resultado esperado: /var/opt/mssql/data

-- Configura o banco para o modelo de recuperação FULL, necessário para backups diferenciais e de log
ALTER DATABASE WWI_Avaliacao SET RECOVERY FULL;
GO

-- Backup FULL
DECLARE @BackupFileFull NVARCHAR(400);
SET @BackupFileFull = '/var/opt/mssql/data/WWI_Avaliacao_FULL_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';

BACKUP DATABASE WWI_Avaliacao
TO DISK = @BackupFileFull
WITH INIT, COMPRESSION, STATS = 10;
GO

-- Backup DIFFERENTIAL
DECLARE @BackupFileDiff NVARCHAR(400);
SET @BackupFileDiff = '/var/opt/mssql/data/WWI_Avaliacao_DIFF_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';

BACKUP DATABASE WWI_Avaliacao
TO DISK = @BackupFileDiff
WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10;
GO

-- Backup TRANSACTION LOG
DECLARE @BackupFileLog NVARCHAR(400);
SET @BackupFileLog = '/var/opt/mssql/data/WWI_Avaliacao_LOG_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.trn';

BACKUP LOG WWI_Avaliacao
TO DISK = @BackupFileLog
WITH INIT, COMPRESSION, STATS = 10;
GO

-- Comandos para habilitar opções avançadas e Agent XPs
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Agent XPs', 1;
RECONFIGURE;
GO

-- ============================================================
-- Script para criação de Jobs de Backup (FULL, DIFFERENTIAL, LOG)
-- Observação: estes jobs dependem do SQL Server Agent estar ativo.
-- Se o Agent não estiver ativo, os jobs não irão executar automaticamente.
-- ============================================================

-- 1. Job de Backup FULL
USE msdb;
GO

EXEC sp_add_job
    @job_name = N'Backup_Full_WWI_Avaliacao';

EXEC sp_add_jobstep
    @job_name = N'Backup_Full_WWI_Avaliacao',
    @step_name = N'Backup Full',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupFileFull NVARCHAR(400);
SET @BackupFileFull = ''/var/opt/mssql/data/WWI_Avaliacao_FULL_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + ''.bak'';

BACKUP DATABASE WWI_Avaliacao
TO DISK = @BackupFileFull
WITH INIT, COMPRESSION, STATS = 10;
',
    @on_success_action = 1, -- continuar para o próximo passo ou concluir
    @on_fail_action = 2; -- falhar o job em caso de erro

-- Agenda diária às 01:00 da manhã
EXEC sp_add_schedule
    @schedule_name = N'Diario_01h00',
    @freq_type = 4, -- Diário
    @freq_interval = 1,
    @active_start_time = 010000; -- 01:00:00 AM

EXEC sp_attach_schedule
    @job_name = N'Backup_Full_WWI_Avaliacao',
    @schedule_name = N'Diario_01h00';

EXEC sp_add_jobserver
    @job_name = N'Backup_Full_WWI_Avaliacao';
GO

-- 2. Job de Backup DIFFERENTIAL
USE msdb;
GO

EXEC sp_add_job
    @job_name = N'Backup_Diff_WWI_Avaliacao';

EXEC sp_add_jobstep
    @job_name = N'Backup_Diff_WWI_Avaliacao',
    @step_name = N'Backup Differential',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupFileDiff NVARCHAR(400);
SET @BackupFileDiff = ''/var/opt/mssql/data/WWI_Avaliacao_DIFF_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + ''.bak'';

BACKUP DATABASE WWI_Avaliacao
TO DISK = @BackupFileDiff
WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10;
',
    @on_success_action = 1,
    @on_fail_action = 2;

-- Agenda a cada 4 horas (240 minutos)
EXEC sp_add_schedule
    @schedule_name = N'Quatro_Horas',
    @freq_type = 4, -- Diário
    @freq_interval = 1,
    @freq_subday_type = 4, -- minutos
    @freq_subday_interval = 240,
    @active_start_time = 000000;

EXEC sp_attach_schedule
    @job_name = N'Backup_Diff_WWI_Avaliacao',
    @schedule_name = N'Quatro_Horas';

EXEC sp_add_jobserver
    @job_name = N'Backup_Diff_WWI_Avaliacao';
GO

-- 3. Job de Backup LOG
USE msdb;
GO

EXEC sp_add_job
    @job_name = N'Backup_Log_WWI_Avaliacao';

EXEC sp_add_jobstep
    @job_name = N'Backup_Log_WWI_Avaliacao',
    @step_name = N'Backup Log',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @BackupFileLog NVARCHAR(400);
SET @BackupFileLog = ''/var/opt/mssql/data/WWI_Avaliacao_LOG_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + ''.trn'';

BACKUP LOG WWI_Avaliacao
TO DISK = @BackupFileLog
WITH INIT, COMPRESSION, STATS = 10;
',
    @on_success_action = 1,
    @on_fail_action = 2;

-- Agenda a cada 15 minutos
EXEC sp_add_schedule
    @schedule_name = N'Quinze_Minutos',
    @freq_type = 4, -- Diário
    @freq_interval = 1,
    @freq_subday_type = 4, -- minutos
    @freq_subday_interval = 15,
    @active_start_time = 000000;

EXEC sp_attach_schedule
    @job_name = N'Backup_Log_WWI_Avaliacao',
    @schedule_name = N'Quinze_Minutos';

EXEC sp_add_jobserver
    @job_name = N'Backup_Log_WWI_Avaliacao';
GO

-- ============================================================
-- Observação importante:
-- Apesar dos scripts acima criarem jobs para automatizar backups,
-- a execução automática depende do SQL Server Agent estar ativo.
-- No ambiente atual, o SQL Server Agent não está ativo ou não está disponível,
-- o que impede que esses jobs rodem automaticamente.
--
-- Isso pode ocorrer porque:
-- 1. A edição do SQL Server é Express, que não suporta Agent.
-- 2. O serviço Agent não está instalado ou habilitado.
-- 3. A instância está rodando em Linux, onde o Agent pode não estar configurado.
--
-- Como alternativa, recomenda-se usar agendadores externos (ex: cron no Linux)
-- para executar scripts de backup automaticamente.
-- ============================================================

-- ============================================================
-- Exemplo de scripts para restauração (usados para validar backup)
-- ============================================================

-- 1. Restaurar backup FULL
RESTORE DATABASE WWI_Avaliacao
FROM DISK = '/var/opt/mssql/data/WWI_Avaliacao_FULL_20250722_173442.bak'
WITH NORECOVERY, REPLACE;

-- 2. Restaurar backup DIFFERENTIAL
RESTORE DATABASE WWI_Avaliacao
FROM DISK = '/var/opt/mssql/data/WWI_Avaliacao_DIFF_20250722_173443.bak'
WITH NORECOVERY;

-- 3. Restaurar backup LOG intermediário
RESTORE LOG WWI_Avaliacao
FROM DISK = '/var/opt/mssql/data/WWI_Avaliacao_LOG_20250722_173444.trn'
WITH NORECOVERY;

-- 4. Restaurar último backup LOG e finalizar restauração
RESTORE LOG WWI_Avaliacao
FROM DISK = '/var/opt/mssql/data/WWI_Avaliacao_LOG_20250722_200055.trn'
WITH RECOVERY;
GO

-- Fim do script
