

SELECT	
	convert(varchar(100), DB_NAME()) as dbName,
	OBJECT_SCHEMA_NAME(objects.object_id) As SchemaName ,
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates,
	dm_db_index_usage_stats.user_lookups,
	indexes.type_desc,
	is_unique,
	is_disabled,
	has_filter,

	(dm_db_index_usage_stats.user_seeks * 100 + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups * 20) - dm_db_index_usage_stats.user_updates,
	(dm_db_index_usage_stats.user_seeks  + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups ) - dm_db_index_usage_stats.user_updates

FROM
    sys.dm_db_index_usage_stats
    inner  JOIN sys.objects ON sys.dm_db_index_usage_stats.OBJECT_ID = sys.objects.OBJECT_ID
    inner JOIN sys.indexes ON sys.indexes.index_id = sys.dm_db_index_usage_stats.index_id AND sys.dm_db_index_usage_stats.OBJECT_ID = sys.indexes.OBJECT_ID



--where 	(dm_db_index_usage_stats.user_seeks * 100 + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups * 20) - dm_db_index_usage_stats.user_updates <=0 
--and indexes.name is not null 
where 1=1 
-- and indexes.type_desc in ('HEAP', 'CLUSTERED') 
and   sys.indexes.name = 'IX_Order Details2_Quantity' 

order by (dm_db_index_usage_stats.user_seeks * 100 + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups * 20) - dm_db_index_usage_stats.user_updates asc








--alter table [dbo].[Order Details2]
--	add ID int identity(1,1) primary key clustered 






























/*

use ServiceDB
go 
create function indexMon.getIndexUsageStat( @dt as datetime)
returns table 
as 

RETURN(
SELECT
	@dt as logdate,
	convert(varchar(100), 'sf') as dbName,
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates,
	indexes.type_desc,
	is_unique,
	is_disabled,
	has_filter
	
FROM
    sf.sys.dm_db_index_usage_stats
    INNER JOIN sf.sys.objects ON sf.sys.dm_db_index_usage_stats.OBJECT_ID = sf.sys.objects.OBJECT_ID
    INNER JOIN sf.sys.indexes ON sf.sys.indexes.index_id = sf.sys.dm_db_index_usage_stats.index_id AND sf.sys.dm_db_index_usage_stats.OBJECT_ID = sf.sys.indexes.OBJECT_ID
 --where user_updates > last_user_seek + user_scans  
--ORDER BY
    --sf.sys.dm_db_index_usage_stats.user_updates DESC

	union all 
SELECT
	@dt as logdate,
	convert(varchar(100), 'tolupp') as dbName,
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates,
	indexes.type_desc,
	is_unique,
	is_disabled,
	has_filter
	
FROM
    tolupp.sys.dm_db_index_usage_stats
    INNER JOIN tolupp.sys.objects ON tolupp.sys.dm_db_index_usage_stats.OBJECT_ID = tolupp.sys.objects.OBJECT_ID
    INNER JOIN tolupp.sys.indexes ON tolupp.sys.indexes.index_id = tolupp.sys.dm_db_index_usage_stats.index_id AND tolupp.sys.dm_db_index_usage_stats.OBJECT_ID = tolupp.sys.indexes.OBJECT_ID
 --where user_updates > last_user_seek + user_scans  
 --where indexes.name like '%custom%'
--ORDER BY
--    tolupp.sys.dm_db_index_usage_stats.user_updates DESC
	
	union all 
SELECT
	@dt as logdate,
	convert(varchar(100), 'wms5') as dbName,
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates,
	indexes.type_desc,
	is_unique,
	is_disabled,
	has_filter
	
FROM
    wms5.sys.dm_db_index_usage_stats
    INNER JOIN wms5.sys.objects ON wms5.sys.dm_db_index_usage_stats.OBJECT_ID = wms5.sys.objects.OBJECT_ID
    INNER JOIN wms5.sys.indexes ON wms5.sys.indexes.index_id = wms5.sys.dm_db_index_usage_stats.index_id AND wms5.sys.dm_db_index_usage_stats.OBJECT_ID = wms5.sys.indexes.OBJECT_ID

	union all 
SELECT
	@dt as logdate,
	convert(varchar(100), 'ka') as dbName,
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates,
	indexes.type_desc,
	is_unique,
	is_disabled,
	has_filter
	
FROM
    ka.sys.dm_db_index_usage_stats
    INNER JOIN ka.sys.objects ON ka.sys.dm_db_index_usage_stats.OBJECT_ID = ka.sys.objects.OBJECT_ID
    INNER JOIN ka.sys.indexes ON ka.sys.indexes.index_id = ka.sys.dm_db_index_usage_stats.index_id AND ka.sys.dm_db_index_usage_stats.OBJECT_ID = ka.sys.indexes.OBJECT_ID
);
go

*/

/********************


SELECT	
	convert(varchar(100), 'sf') as dbName,
    objects.name AS Table_name,
    indexes.name AS Index_name,
    dm_db_index_usage_stats.user_seeks,
    dm_db_index_usage_stats.user_scans,
    dm_db_index_usage_stats.user_updates,
	dm_db_index_usage_stats.user_lookups,
	indexes.type_desc,
	is_unique,
	is_disabled,
	has_filter,

	(dm_db_index_usage_stats.user_seeks * 100 + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups * 20) - dm_db_index_usage_stats.user_updates,
	(dm_db_index_usage_stats.user_seeks  + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups ) - dm_db_index_usage_stats.user_updates

FROM
    sys.dm_db_index_usage_stats
    INNER JOIN sys.objects ON sys.dm_db_index_usage_stats.OBJECT_ID = sys.objects.OBJECT_ID
    INNER JOIN sys.indexes ON sys.indexes.index_id = sys.dm_db_index_usage_stats.index_id AND sys.dm_db_index_usage_stats.OBJECT_ID = sys.indexes.OBJECT_ID
where 	(dm_db_index_usage_stats.user_seeks * 100 + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups * 20) - dm_db_index_usage_stats.user_updates <=0 
and indexes.name is not null 
order by (dm_db_index_usage_stats.user_seeks * 100 + dm_db_index_usage_stats.user_scans +dm_db_index_usage_stats.user_lookups * 20) - dm_db_index_usage_stats.user_updates asc

--  secondsUptime 











*********************/









