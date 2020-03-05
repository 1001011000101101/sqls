--THIS SCRIPT CREATES BACKUP WITHOUT SELECTED TABLES:
--1. BACKUP THE 'SOURCE DB'
--2. RESTORE JUST BACKUPED DB TO 'TEMP DB'
--3. REMOVE ALL ROWS FROM SELECTED TABLES IN 'TEMP DB'
--4. BACKUP 'TEMP DB'
--5. REMOVE 'TEMP DB'S .mdf & .ldf files (JUST RESTORED TEMP DB). 
--6. AS RESULT WE HAVE .bak FILE WITHOUT UNNECESSARY DATA: LOGS, MEASURED VALUES AND ETC.
-- Смысл в том, чтобы не бекапировать данные счетчиков (архивы, текущие показания и прочее), 
-- а сохранять только структуру конфигурации (дома, точки учета, завномера, камменты, настройки).
-- Это позволяет существенно снизить объем бекапа телеметрии.
-- Протестировано в АСКУЭ ЛЕРС Учет, Энергия
--CREATED BY MATYUSHKIN ROMAN

--https://stackoverflow.com/questions/5131491/enable-xp-cmdshell-sql-server
--https://dba.stackexchange.com/questions/102745/how-can-i-take-backup-of-particular-tables-in-sql-server-2008-using-t-sql-script
-- To allow advanced options to be changed.
--EXEC sp_configure 'show advanced options', 1
--GO
---- To update the currently configured value for advanced options.
--RECONFIGURE
--GO
---- To enable the feature.
--EXEC sp_configure 'xp_cmdshell', 1
--GO
---- To update the currently configured value for this feature.
--RECONFIGURE
--GO

-------------------DECLARATIONS
DECLARE @backup_folder VARCHAR(128)
DECLARE @temp_folder VARCHAR(128)
DECLARE @db_source VARCHAR(128)
DECLARE @db_source_filename VARCHAR(128)
DECLARE @db_source_log_filename VARCHAR(128)
DECLARE @db_target VARCHAR(128)
DECLARE @db_target_full_path VARCHAR(128)
DECLARE @db_target_backup_path VARCHAR(128)
DECLARE @db_target_backup_name VARCHAR(128)
DECLARE @db_target_mdf_path VARCHAR(128)
DECLARE @db_target_log_path VARCHAR(128)
DECLARE @db_target_configuration_only_backup_name VARCHAR(128)
DECLARE @cmd VARCHAR(512)
declare @tableName varchar(32)
DECLARE @table VARCHAR(128)
DECLARE @db_source_id int



-----------------------------MAIN VARIABLES
SET @temp_folder = N'C:\temp\'
SET @backup_folder = N'C:\backups\'
SET @db_source = 'lers' -- CASE INSENSITIVE DATABASE NAME



-----------------------------DERIVATIVES VARIABLES
SET @db_target = @db_source + '_only_configuration'
SET @db_target_full_path = @temp_folder + @db_target + '.bak'
SET @db_target_backup_path = @backup_folder + @db_target + '.bak'
SET @db_target_mdf_path = @temp_folder + @db_target + '.mdf'
SET @db_target_log_path = @temp_folder + @db_target + '_log.ldf'
SET @db_target_backup_name = @db_source + '-Full Database Backup'
SET @db_target_configuration_only_backup_name = @db_source + '_only_configuration-Full Database Backup'



SELECT @db_source_id = DB_ID(@db_source); 

select @db_source_filename = name from sys.master_files WHERE database_id = @db_source_id AND type_desc = 'ROWS' AND [type] = 0;
select @db_source_log_filename = name from sys.master_files WHERE database_id = @db_source_id AND type_desc = 'LOG' AND [type] = 1;


if exists (
    select  * from tempdb.dbo.sysobjects o
    where o.xtype in ('U') 

   and o.id = object_id(N'tempdb..#temp_table')
)
DROP TABLE #temp_table;
CREATE TABLE #temp_table ([Name] [varchar](128) NOT NULL)
------------------------------------------------------------------------------------------------------------------------------------------------------------



BACKUP DATABASE @db_source TO  DISK = @db_target_full_path WITH NOFORMAT, INIT,  NAME = @db_target_backup_name, SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10

USE [master]
RESTORE DATABASE @db_target FROM  DISK = @db_target_full_path WITH  FILE = 1,  MOVE @db_source_filename TO @db_target_mdf_path,  MOVE @db_source_log_filename TO @db_target_log_path,  NOUNLOAD,  REPLACE,  STATS = 5

SET @cmd = 'INSERT INTO #temp_table SELECT TABLE_NAME FROM '+ @db_target + '.INFORMATION_SCHEMA.TABLES; '
EXEC sp_sqlexec @cmd



declare my_cursor cursor for 
SELECT * FROM #temp_table

open my_cursor
fetch next from my_cursor into @tableName
while (@@FETCH_STATUS <> -1)
begin
-----------------------------
if (@tableName IN (
'PollSessionLog',
 'WaterConsumptionHour',
  'WaterTotals',
  'ElectricTotals',
  'ElectricConsumptionDay'
  ,'WaterConsumptionDay'
  ,'WaterConsumptionCurrent'
  ,'SystemLog'
  ,'AccountLog'
 ,'ElectricConsumptionHour'
  ,'ElectricPowerQuality'
  ,'Notification'
  ,'ContingencyLog'
  ,'WaterConsumptionMonth'
  ,'DataStatus'
  ,'EquipmentPollStatistics'
  ,'ElectricConsumptionMonth'
  ,'EavConsumptionLastValue'
   ,'ElectricPower'
  
  ,'Events'
  ,'EventsLog'
  ,'ChannelsArchiveOld'
  ,'MeasuresHour'
  ,'MeasuresLog'
  ,'MeasuresShort'
  ,'MeasuresDay'
  ,'MeasuresCut'
  ,'MeasuresTime'
  ,'MeasuresCurrent'
  ,'MessageLog'
  ,'DevicesTraffic'
  ,'MeasuresLong'
 ,'MeasureID'
  ,'ChannelsParams'
  ,'OperatorsSessionLog'
  ,'DevicesState'
 ,'Table_6_NewVersion'
  ,'DevicesStateAux'
  )) 

BEGIN

SET @table = @db_target + '.dbo.' + @tableName
SET @cmd = 'DELETE FROM ' + @table
EXEC sp_sqlexec @cmd

END;



FETCH NEXT FROM my_cursor INTO @tableName
end
close my_cursor
deallocate my_cursor

BACKUP DATABASE @db_target TO  DISK = @db_target_backup_path WITH NOFORMAT, INIT,  NAME = @db_target_configuration_only_backup_name, SKIP, NOREWIND, NOUNLOAD, NO_COMPRESSION,  STATS = 10

EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = @db_target

USE [master]

SET @cmd = 'DROP DATABASE  ' + @db_target
EXEC sp_sqlexec @cmd


