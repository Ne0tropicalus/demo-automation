ALTER PROC [dbo].[warranty_ingest] 
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
IF EXISTS ( select * from sys.external_data_sources where name = 'partnera_manifest')
	drop external data source partnera_manifest

create external data source partnera_manifest
  with (
	type = HADOOP,
	location = 'wasb://partnera-incoming@tcdevbatch1.blob.core.windows.net/warranty/warranty.man',
	credential = partnera
	);

print 'getting manifest data'
create external table manifest (
[file_name]	varchar(100)	null,
[record_count]	varchar(10)	null,
[file_ts] varchar(40)		null,
[file_md5]	varchar(40)		null )
with (
	location = '/',
	data_source=partnera_manifest,
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
	IF EXISTS (select * from sys.external_tables where name = 'warranty_raw')
	   drop external table warranty_raw;

	print 'creating warranty_raw external table - max reject value at 1%';
	create external table warranty_raw (
	REGION_CD					VARCHAR(100),
	CLAIMANT_CD					VARCHAR(100),
	PARTNER_ORGANIZATION_NM		VARCHAR(100),
	CLAIM_NO					VARCHAR(100),
	VIN_CD						VARCHAR(20),
	REPAIR_ORDER_NO				VARCHAR(100),
	REPAIR_ORDER_DT				VARCHAR(30),
	REPAIR_ORDER_MILE_QTY		VARCHAR(30),
	DATE_OF_FIRST_USE_DT		VARCHAR(30),
	MONTHS_IN_SERVICE_QTY		VARCHAR(30),
	MAIN_OPCODE_CD				VARCHAR(100),
	TOTAL_CLAIM_AMT				VARCHAR(50),
	MODEL_TYPE_TXT				VARCHAR(200),
	MODEL_YEAR					VARCHAR(200),
	REPAIR_PROGRAM_TYPE_CD		VARCHAR(200),
	APPROVED_DT					VARCHAR(30),
	REPAIR_PROGRAM_NO			VARCHAR(200),
	CLAIM_CNT					VARCHAR(30),
	REPAIR_PROGRAM_TYPE_TXT		VARCHAR(200),
	OPERATION_TXT				VARCHAR(200),
	FRANCHISE_NM				VARCHAR(200),
	EIDH_ORIG_SOURCE			VARCHAR(30),
	EIDH_DATA_ACQUISITION_TYPE	VARCHAR(30),
	EIDH_BATCH_ID				VARCHAR(100),
	EIDH_OWNER					VARCHAR(30),
	EIDH_LOAD_DATE				VARCHAR(30),
	EIDH_EISP_CLASS				VARCHAR(30),
	EIDH_DATA					VARCHAR(30),
	RECORD_DATE					VARCHAR(30)

	)
	with (
		 location ='/',
		 data_source=warranty,
		 file_format=pipe_delimited,
		 reject_type=percentage,
		 reject_value=1,
		 reject_sample_value=1000
		 );

print 'Getting next Audit ID'
SET @audit_id = (SELECT ISNULL(max(audit_id),0) + 1 from BI_audit);
print 'Counting number of rows in external table warranty_raw'
SET @ext_tbl_no_recs = (SELECT ISNULL(count(*),0) from warranty_raw);

print 'INSERTING DELTA CLAIMS into stage table';

INSERT INTO dbo.warranty_stg
select
 @audit_id,
 checksum([CLAIM_NO]),
 ltrim(rtrim(REGION_CD))
,ltrim(rtrim(CLAIMANT_CD))
,ltrim(rtrim(PARTNER_ORGANIZATION_NM))
,ltrim(rtrim(CLAIM_NO))
,ltrim(rtrim(VIN_CD))
,ltrim(rtrim(REPAIR_ORDER_NO))
,REPAIR_ORDER_DT
,case WHEN ISNUMERIC(REPAIR_ORDER_MILE_QTY) = 0 
      THEN 0 
	  ELSE REPAIR_ORDER_MILE_QTY 
	  END
,case WHEN ISDATE(DATE_OF_FIRST_USE_DT) = 0 
      THEN CONVERT (DATE, '1900-01-01',121) 
      ELSE CONVERT (DATE,DATE_OF_FIRST_USE_DT,121) 
	  END 
,case when ISNUMERIC(MONTHS_IN_SERVICE_QTY) = 0 
      THEN 0 
	  ELSE MONTHS_IN_SERVICE_QTY 
	  END
,ltrim(rtrim(MAIN_OPCODE_CD))
,case WHEN ISNUMERIC(TOTAL_CLAIM_AMT) = 0 
      THEN 0 
	  ELSE CONVERT(DECIMAL(34,2),TOTAL_CLAIM_AMT) 
	  END
,ltrim(rtrim(MODEL_TYPE_TXT))
,case when ISNUMERIC(MODEL_YEAR) = 0
     then -1
	 else convert(integer, ltrim(rtrim(MODEL_YEAR)))
 end
,ltrim(rtrim(REPAIR_PROGRAM_TYPE_CD))
,APPROVED_DT
,ltrim(rtrim(REPAIR_PROGRAM_NO))
,case when ISNUMERIC(CLAIM_CNT) = 0 
      THEN 0 
	  ELSE CONVERT(DECIMAL, CLAIM_CNT) 
	  END
,ltrim(rtrim(REPAIR_PROGRAM_TYPE_TXT))
,ltrim(rtrim(OPERATION_TXT))
,ltrim(rtrim(FRANCHISE_NM))
,ltrim(rtrim(EIDH_ORIG_SOURCE))
,ltrim(rtrim(EIDH_DATA_ACQUISITION_TYPE))
,ltrim(rtrim(EIDH_BATCH_ID))
,ltrim(rtrim(EIDH_OWNER))
,ltrim(rtrim(EIDH_LOAD_DATE))
,ltrim(rtrim(EIDH_EISP_CLASS))
,ltrim(rtrim(EIDH_DATA))
,case WHEN ISDATE(RECORD_DATE) = 0
      THEN CONVERT (DATETIME, '1900-01-01', 121)
	  ELSE CONVERT(DATETIME, REPAIR_ORDER_DT,121)
	  END
,CAST((YEAR([REPAIR_ORDER_DT]) * 100) + MONTH([REPAIR_ORDER_DT]) as INTEGER)
from warranty_raw
where not exists ( select 1 from warranty_stg x
                   where x.[hash_claim_no] = checksum([CLAIM_NO]));

SET @stg_tbl_no_recs = (SELECT ISNULL(count(*),0) from dbo.warranty_stg where audit_id = @audit_id);

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

CREATE STATISTICS stats_claim_no on dbo.warranty_stg([CLAIM_NO]);
CREATE STATISTICS stats_repair_order_no on dbo.warranty_stg([REPAIR_ORDER_NO]);
CREATE STATISTICS stats_repair_order_dt on dbo.warranty_stg([REPAIR_ORDER_DT]);
CREATE STATISTICS stats_vin on dbo.warranty_stg([VIN_CD]);

END

