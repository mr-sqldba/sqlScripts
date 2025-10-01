USE [master]
GO
/****** Object:  UserDefinedFunction [dbo].[TryConvertToJobName]    Script Date: 26.12.2021 12:54:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[TryConvertToJobName] ( 
@Program_Name nvarchar(1000)
)
-- берем имя программы из процессов и если это джоб, то резолвим его имя, иначе @program_name
-- Но если джоб был уже удален, то выскочит SOME DELETED JOB
RETURNS nvarchar(1000)
AS
BEGIN
	--declare @program_name varchar(3000) =	N'SQLAgent - TSQL JobStep (Job 0xE21A0F50C76BD643A5E8EB8DC8F1BCCB : Step 1)                                                        '
	--select CHARINDEX(N'SQLAgent - TSQL JobStep', @program_name) 
	if (CHARINDEX(N'SQLAgent - TSQL JobStep', @program_name) != 0)
		BEGIN 
			declare @BinJobID varchar(100) = SUBSTRING(@program_name , 32 , 34) 
			--select @BinJobID
			declare @JobUID varchar(100) 
			select	@JobUID =
					substring(@BinJobID, 7,2) + substring(@BinJobID, 5,2)+substring(@BinJobID, 3,2)+substring(@BinJobID, 1,2)
					+'-'
					+substring(@BinJobID, 11,2)+substring(@BinJobID, 9,2)
					+'-'
					+substring(@BinJobID, 15,2)+substring(@BinJobID, 13,2)
					+'-'
					+substring(@BinJobID, 17,2)+substring(@BinJobID, 19,2)
					+'-'
					+substring(@BinJobID, 21,12)
			--select @JobUID
			if exists (select name from msdb..sysjobs where job_id = convert(uniqueidentifier, @JobUID))
				select	@program_name = 'Job: ' + name + substring(@program_name,  CHARINDEX(' : Step 1', @program_name), 9)
				from msdb..sysjobs where job_id = convert(uniqueidentifier, @JobUID)
			else 
				set @Program_Name = 'SOME DELETED JOB'
		end
	--select @program_name

return @program_name
END
GO

USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_Locks2]    Script Date: 26.12.2021 12:54:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[sp_Locks2]
(
   @Mode int = 7,
   @Wait_Duration_ms int = 1000, /* 1 seconds */
   @MinSesionID int = 50
)
/*
  19/04/2008 Yaniv Etrogi
  http://www.sqlserverutilities.com  
*/
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-------------------- EXAMPLE ---------------- EXEC sp_Locks2 @Mode = 3, @Wait_Duration_ms = 1000
/* MODES 
first	second	third	mode
0		0		0		0
1		0		0		1
0		1		0		2
1		1		0		3
0		0		1		4
1		0		1		5
0		1		1		6
1		1		1		7

*/
IF @Mode & 4 != 0 -- вывести вершину иерархии блокировок
BEGIN
	SELECT 
    spid,
    [status],
    CONVERT(CHAR(3), blocked) AS blocked,
    loginame,
    [dbo].[TryConvertToJobName] (SUBSTRING([program_name] ,1,128)) AS program,
    SUBSTRING(DB_NAME(p.dbid),1,10) AS [database],
    SUBSTRING(hostname, 1, 12) AS host,
    cmd,
    waittype,
    t.[text]
  FROM sys.sysprocesses p
    CROSS APPLY sys.dm_exec_sql_text (p.sql_handle) t
  WHERE spid IN (SELECT blocked FROM sys.sysprocesses WHERE blocked <> 0) 
    AND blocked = 0;
END;

/*  */
IF @Mode & 2 != 0 -- кто кого блокирует 
BEGIN;
	  SELECT
      t.blocking_session_id           AS blocking,
      t.session_id                    AS blocked,
      [dbo].[TryConvertToJobName] (p2.[program_name] )              AS program_blocking,
      [dbo].[TryConvertToJobName] (p1.[program_name] )              AS program_blocked,
      DB_NAME(l.resource_database_id) AS [database],
      p2.[hostname]                   AS host_blocking,
      p1.[hostname]                   AS host_blocked,
	  p2.loginame as login_blocking, 
	  p1.loginame as login_blocked,
      t.wait_duration_ms,
      l.request_mode,
      l.resource_type,
      t.wait_type,
      (SELECT SUBSTRING(st.text, (r.statement_start_offset/2) + 1, 
              ((CASE r.statement_end_offset 
                  WHEN -1 THEN DATALENGTH(st.text) 
                  ELSE r.statement_end_offset END
                - r.statement_start_offset) /2 ) + 1)
        FROM sys.dm_exec_requests AS r 
          CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st 
        WHERE r.session_id = l.request_session_id) AS statement_blocked,
      CASE WHEN t.blocking_session_id > 0 THEN 
        (SELECT st.text 
          FROM sys.sysprocesses AS p 
            CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) AS st
          WHERE p.spid = t.blocking_session_id)
      ELSE NULL END AS statement_blocking
       --,t.resource_description AS blocking_resource_description
       --,l.resource_associated_entity_id
    FROM sys.dm_os_waiting_tasks AS t
      INNER JOIN sys.dm_tran_locks AS l 
        ON t.resource_address = l.lock_owner_address
      INNER JOIN sys.sysprocesses p1 ON p1.spid = t.session_id
      INNER JOIN sys.sysprocesses p2 ON p2.spid = t.blocking_session_id
    WHERE t.session_id > @MinSesionID  AND t.wait_duration_ms > @Wait_Duration_ms;
END;


/*  */
IF @Mode & 1 != 0 -- что вообще выполняется 
BEGIN
SELECT DISTINCT
    r.session_id             AS spid,
    r.percent_complete       AS [percent],
	s.loginame,
    r.open_transaction_count AS open_trans,
    r.[status],
    r.reads,
    r.logical_reads,
    r.writes,
    s.cpu,
    DB_NAME(r.database_id)   AS [db_name],
    s.[hostname],
    [dbo].[TryConvertToJobName] (s.[program_name]) as [program_name],
  --s.loginame,
  --s.login_time,
    r.start_time,
  --r.wait_type,
    r.wait_time,
    r.last_wait_type,
    r.blocking_session_id    AS blocking,
    r.command,
    (SELECT SUBSTRING(text, statement_start_offset / 2 + 1,
            (CASE WHEN statement_end_offset = -1 THEN
                    LEN(CONVERT(NVARCHAR(MAX),text)) * 2 
                  ELSE statement_end_offset 
                  END - statement_start_offset) / 2)
      FROM sys.dm_exec_sql_text(r.sql_handle)) AS [statement],
    t.[text]
    --,query_plan 
  FROM sys.dm_exec_requests r
    INNER JOIN sys.sysprocesses s ON s.spid = r.session_id
    CROSS APPLY sys.dm_exec_sql_text (r.sql_handle) t
    --CROSS APPLY sys.dm_exec_query_plan (r.plan_handle) 
  WHERE 1=1
	AND r.session_id > @MinSesionID  
	AND r.session_id <> @@spid
    --AND s.[program_name] NOT LIKE 'SQL Server Profiler%'
    --AND db_name(r.database_id) NOT LIKE N'distribution'
    --AND r.wait_type IN ('SQLTRACE_LOCK', 'IO_COMPLETION', 'TRACEWRITE')
  ORDER BY s.CPU DESC;
END;

