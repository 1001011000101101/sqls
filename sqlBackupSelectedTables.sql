-- Смысл в том, чтобы не бекапировать данные счетчиков (архивы, текущие показания и прочее), 
-- а сохранять только структуру конфигурации (дома, точки учета, завномера, камменты, настройки).
-- Это позволяет существенно снизить объем бекапа телеметрии




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




declare @tableName varchar(32)
declare my_cursor cursor for 


SELECT name FROM sys.Tables

open my_cursor
fetch next from my_cursor into @tableName
while (@@FETCH_STATUS <> -1)
begin
-----------------------------
if (@tableName NOT IN (
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

  -- SQL Table Backup
-- Developed by DBATAG, www.DBATAG.com
DECLARE @table VARCHAR(128),
@file VARCHAR(255),
@cmd VARCHAR(512)
--SET @table = 'energy.dbo.' + @tableName --  Table Name which you want    to backup


SET @table = 'LERS.dbo.' + @tableName --  Table Name which you want    to backup
--SET @file = 'C:\sync\Scripts\' + @table --  Replace C:\MSSQL\Backup\ to destination dir where you want to place table data backup

--SET @file = 'C:\sync\Scripts-energy\' + @table --  Replace C:\MSSQL\Backup\ to destination dir where you want to place table data backup
SET @file = 'C:\sync\tables\' + @table --  Replace C:\MSSQL\Backup\ to destination dir where you want to place table data backup
+ '.txt'
--SET @cmd = 'bcp ' + @table + ' out ' + @file + ' -c -C 65001 -t";" -r"\n" -T'
 SET @cmd = 'bcp ' + @table + ' out ' + @file + ' -c -t";" -r"\n" -T -C RAW'
 --SET @cmd = 'bcp ' + @table + ' out ' + @file + ' -c -t";" -r"\n" -T '
EXEC master..xp_cmdshell @cmd

  END;

--RETURN;



FETCH NEXT FROM my_cursor INTO @tableName
end
close my_cursor
deallocate my_cursor
