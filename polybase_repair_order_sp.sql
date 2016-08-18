
ALTER PROC [dbo].[repair_order_ingest] 
			@provider [nvarchar](100),
			@file_compressed [char](1),
			@external_tbl_name [nvarchar](100),
			@stage_tbl_name [nvarchar](100)
AS
BEGIN
	DECLARE  @stg_tbl_no_recs	int = 0,
			 @ext_tbl_no_recs	int = 0,
			 @audit_id			int = 0,
			 @man_id			int = 0,
			 @file_timestamp	varchar(50),
			 @file_name			varchar(50),
			 @md5				varchar(50),
			 @file_cnt			int = 0;

print 'dropping external table manifest'
IF EXISTS ( select * from sys.external_tables where name = 'manifest' )
	drop external table manifest

print 'dropping previous external DATA source if exsits'
IF EXISTS ( select * from sys.external_data_sources where name = 'partnerb_manifest')
	drop external data source partnerb_manifest

create external data source partnerb_manifest
  with (
	type = HADOOP,
	location = 'wasb://partnerb-incoming@tcdevbatch2.blob.core.windows.net/repair_order/repair_order.man',
	credential = partnerb
	);

print 'getting manifest data'
create external table manifest (
[file_name]	varchar(100)	null,
[record_count]	varchar(10)	null,
[file_ts] varchar(40)		null,
[file_md5]	varchar(40)		null )
with (
	location = '/',
	data_source=partnerb_manifest,
	file_format=manifest
	);

SET @man_id = (SELECT ISNULL(max(manifest_id),0) + 1 from BI_manifest);
		
insert into dbo.BI_manifest
select	@man_id,
		current_timestamp,
		@provider,
		[file_name],
		convert(int, record_count),
		[file_ts],
		[file_md5] 
from manifest

SET @file_timestamp = ( SELECT file_timestamp from BI_manifest where manifest_id = @man_id);
SET @file_name = ( SELECT file_name from BI_manifest where manifest_id = @man_id);
SET @md5 = ( SELECT file_md5 from BI_manifest where manifest_id = @man_id);
SET @file_cnt = ( SELECT record_count from BI_manifest where manifest_id = @man_id);

	print 'dropping previous external table if exists';
	IF EXISTS (select * from sys.external_tables where name = 'repair_orders_raw')
		drop external table repair_orders_raw;
	print 'dropping stage table if exists';
	IF EXISTS (select * from sys.tables where name = 'repair_orders_stg')
		drop table repair_orders_stg;
	print 'creating repair_orders_raw external table - max reject value at 1%';
	  
create external table repair_orders_raw (
rec_count		int,
dealer_no		varchar(10),
order_no		varchar(10),
repair_date		varchar(30),
mileage			varchar(10),
rasmid			varchar(30),
rdn_date		varchar(30),
vin				varchar(20),
repair_notes	varchar(250),
repair_open_dt	varchar(30),
no_days_ro_open	varchar(25),
crt_uid			varchar(20),
crt_ts			varchar(50),
CRT_PGM_ID		varchar(20),
UPDT_UID		varchar(20),
UPDT_TS			varchar(50),
UPDT_PGM_ID		varchar(20),
RECORD_CREATE_DT	varchar(25),
RECORD_LAST_UPDATE_DT	varchar(25),
DATA_SOURCE_ID	varchar(20),
DELETE_FLAG	varchar(25)
)
with (
	 location ='/repair_order/',
	 data_source=repair_order,
	 file_format=comma_delimited,
	 reject_type=percentage,
	 reject_value=1,
	 reject_sample_value=1000);

print 'Getting next Audit ID'
SET @audit_id = (SELECT ISNULL(max(audit_id),0) + 1 from BI_audit);
print 'Counting number of rows in external table repair_orders_raw'
SET @ext_tbl_no_recs = (SELECT ISNULL(count(*),0) from repair_orders_raw);

print 'Creating distributed stage table';

CREATE TABLE dbo.repair_orders_stg 
       WITH (DISTRIBUTION = HASH([order_no]))  
AS SELECT @audit_id as audit_id,
		  rec_count,
          ltrim(rtrim(dealer_no)) as dealer_no,
		  ltrim(rtrim(order_no)) as order_no,
		  case when isdate(repair_date) = 0 
		       then convert(datetime, '1900-01-01', 121) 
			   else convert(datetime, repair_date, 121) end as repair_date,
		  case when isnumeric(mileage) = 0
		       then 0
			   else convert(int, mileage) end as mileage,
		  rasmid,
		  case when isdate(rdn_date) = 0
		       then convert(datetime, '1900-01-01', 121)
			   else convert(datetime, rdn_date, 121) end as rdn_date,
		  ltrim(rtrim(vin)) as vin,
		  ltrim(rtrim(repair_notes)) as repair_notes,
		  case when isdate(repair_open_dt) = 0
		       then convert(datetime, '1900-01-01', 121)
			   else convert(datetime, repair_open_dt, 121) end as repair_open_dt,
		  case when isnumeric(no_days_ro_open) = 0
		       then 0
			   else convert(int, no_days_ro_open) end as no_days_ro_open,
		  ltrim(rtrim(crt_uid)) as crt_uid,
		  ltrim(rtrim(crt_ts)) as crt_ts,
		  ltrim(rtrim([CRT_PGM_ID])) as crt_pgm_id,
		  ltrim(rtrim([UPDT_UID])) as updt_uid,
		  ltrim(rtrim([UPDT_TS])) as updt_ts,
		  ltrim(rtrim([UPDT_PGM_ID])) as updt_pgm_id,
		  case when isdate([RECORD_CREATE_DT]) = 0
		       then convert(datetime, '1900-01-01', 121)
			   else convert(datetime, [RECORD_CREATE_DT], 121) end as record_create_dt
FROM [dbo].[repair_orders_raw]        
   OPTION (LABEL = 'CTAS : Load [dbo].[repair_order_stg]');

SET @stg_tbl_no_recs = (SELECT ISNULL(count(*),0) from dbo.repair_orders_stg where audit_id = @audit_id);

print 'Creating audit record'
insert into BI_audit
select @audit_id,
       current_timestamp,
       @provider,
	   convert(datetime,@file_timestamp,121),
	   @file_name,
	   @file_compressed,
	   @md5,
	   @file_cnt,
	   @external_tbl_name,
	   @ext_tbl_no_recs,
	   @stage_tbl_name,
	   @stg_tbl_no_recs;

CREATE STATISTICS stats_dealer_no on dbo.repair_orders_stg(dealer_no);
CREATE STATISTICS stats_order_no on dbo.repair_orders_stg(order_no);
CREATE STATISTICS stats_repair_date on dbo.repair_orders_stg(repair_date);
CREATE STATISTICS stats_vin on dbo.repair_orders_stg(vin);
CREATE STATISTICS stats_repair_open_dt on dbo.repair_orders_stg(repair_open_dt);

END
