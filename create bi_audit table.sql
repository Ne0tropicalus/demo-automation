CREATE TABLE [dbo].[BI_audit]
(
	[audit_id] [int] NULL,
	[audit_run_ts] [datetime] NULL,
	[provider_name] [varchar](50) NULL,
	[file_timestamp] [datetime] NULL,
	[file_name] [varchar](50) NULL,
	[file_compressed] [char](1) NULL,
	[file_md5hash] [char](32) NULL,
	[file_no_recs] [bigint] NULL,
	[external_table_name] [varchar](50) NULL,
	[ext_tbl_no_recs] [bigint] NULL,
	[stage_table_name] [varchar](50) NULL,
	[stage_no_recs] [bigint] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)

create table BI_manifest (
  [manifest_id]	int		null,
  [provider_name]	varchar(100)	null,
  [file_name]		varchar(100)	null,
  [record_count]	int				null,
  [file_timestamp]	varchar(50)		null,
  [file_md5]		varchar(50)		null
  )
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED COLUMNSTORE INDEX
)
