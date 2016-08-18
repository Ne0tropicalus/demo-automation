ALTER PROC [dbo].[warranty_part_ingest] 
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
	location = 'wasb://partnera-incoming@tcdevbatch1.blob.core.windows.net/warranty_parts/warranty_part.man',
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
	IF EXISTS (select * from sys.external_tables where name = 'warranty_parts_raw')
	   drop external table warranty_parts_raw;

	print 'creating warranty_parts_raw external table - max reject value at 1%';
	create external table warranty_parts_raw (
PART_NO							VARCHAR(200),
PART_NM_CD						VARCHAR(200),
PART_PROD_GROUP_CD				VARCHAR(200),
PART_TXT						VARCHAR(200),
PART_OLTP_SEQ_ID				DECIMAL,
LIFETIME_START_DT				VARCHAR(50),
LIFETIME_END_DT					VARCHAR(50),
PART_IDENTIFICATION_CD			VARCHAR(200),
PART_IDENTIFICATION_TXT			VARCHAR(200),
PART_WARRANTY_RATE				VARCHAR(20),
DISTRIBUTOR_FD_CD				VARCHAR(200),
PART_TYPE_INDICATOR_CD			VARCHAR(200),
PART_TYPE_INDICATOR_TXT			VARCHAR(200),
SUPPLIER_CD						VARCHAR(200),
SUPPLIER_SUBLEDGER_CD			VARCHAR(200),
SUPPLIER_PARTNER_OLTP_SEQ_ID	VARCHAR(20),
VENDOR_CD						VARCHAR(200),
TRAFFIC_CD						VARCHAR(200),
PART_COMMODITY_CD				VARCHAR(200),
PART_COMMODITY_TXT				VARCHAR(200),
PART_STATUS_CD					VARCHAR(200),
PART_STATUS_TXT					VARCHAR(200),
PART_PRIORITY_CD				VARCHAR(200),
PART_PRIORITY_TXT				VARCHAR(200),
PART_SYSTEM_ALERT_IND			CHAR(1),
PART_CREATE_DT					DATETIME,
PART_CREATE_BY					VARCHAR(200),
PART_LAST_UPDATE_DT				DATETIME,
PART_LAST_UPDATE_BY				VARCHAR(200),
CREATE_TS						DATETIME,
LAST_UPDATE_TS					DATETIME,
PARTQUANTITYLIMIT				VARCHAR(20),
WARRANTY_PART_SEQ_ID			VARCHAR(20),
ACCESSORY_IND					VARCHAR(200),
APS_LAST_PART_IN_CHAIN_NO		VARCHAR(200),
COUNTRY_OF_ORIGIN_CD			VARCHAR(200),
PART_NAME_CD					VARCHAR(200),
PORT_INSTALLED_OPTION_IND		VARCHAR(200),
EIDH_ORIG_SOURCE				VARCHAR(30),
EIDH_DATA_ACQUISITION_TYPE		VARCHAR(30),
EIDH_BATCH_ID					VARCHAR(20),
EIDH_OWNER						VARCHAR(30),
EIDH_LOAD_DATE					VARCHAR(30),
EIDH_EISP_CLASS					VARCHAR(30),
EIDH_DATA						VARCHAR(30),
RECORD_DATE						varchar(25)
)
with (
	 location ='/',
	 data_source=warranty_part,
	 file_format=pipe_delimited,
	 reject_type=percentage,
	 reject_value=1,
	 reject_sample_value=1000
	 );

print 'Getting next Audit ID'
SET @audit_id = (SELECT ISNULL(max(audit_id),0) + 1 from BI_audit);
print 'Counting number of rows in external table warranty_raw'
SET @ext_tbl_no_recs = (SELECT ISNULL(count(*),0) from warranty_parts_raw);

print 'Create table as external table';
INSERT INTO [dbo].[warranty_parts_stg]
SELECT @audit_id
      ,[PART_NO]
      ,[PART_NM_CD]
      ,[PART_PROD_GROUP_CD]
      ,[PART_TXT]
      ,[PART_OLTP_SEQ_ID]
      ,[LIFETIME_START_DT]
      ,[LIFETIME_END_DT]
      ,[PART_IDENTIFICATION_CD]
      ,[PART_IDENTIFICATION_TXT]
      ,[PART_WARRANTY_RATE]
      ,[DISTRIBUTOR_FD_CD]
      ,[PART_TYPE_INDICATOR_CD]
      ,[PART_TYPE_INDICATOR_TXT]
      ,[SUPPLIER_CD]
      ,[SUPPLIER_SUBLEDGER_CD]
      ,[SUPPLIER_PARTNER_OLTP_SEQ_ID]
      ,[VENDOR_CD]
      ,[TRAFFIC_CD]
      ,[PART_COMMODITY_CD]
      ,[PART_COMMODITY_TXT]
      ,[PART_STATUS_CD]
      ,[PART_STATUS_TXT]
      ,[PART_PRIORITY_CD]
      ,[PART_PRIORITY_TXT]
      ,[PART_SYSTEM_ALERT_IND]
      ,[PART_CREATE_DT]
      ,[PART_CREATE_BY]
      ,[PART_LAST_UPDATE_DT]
      ,[PART_LAST_UPDATE_BY]
      ,[CREATE_TS]
      ,[LAST_UPDATE_TS]
      ,[PARTQUANTITYLIMIT]
      ,[WARRANTY_PART_SEQ_ID]
      ,[ACCESSORY_IND]
      ,[APS_LAST_PART_IN_CHAIN_NO]
      ,[COUNTRY_OF_ORIGIN_CD]
      ,[PART_NAME_CD]
      ,[PORT_INSTALLED_OPTION_IND]
      ,[EIDH_ORIG_SOURCE]
      ,[EIDH_DATA_ACQUISITION_TYPE]
      ,[EIDH_BATCH_ID]
      ,[EIDH_OWNER]
      ,[EIDH_LOAD_DATE]
      ,[EIDH_EISP_CLASS]
      ,[EIDH_DATA]
      ,[RECORD_DATE]
FROM dbo.warranty_parts_raw;

SET @stg_tbl_no_recs = (SELECT ISNULL(count(*),0) from dbo.warranty_parts_stg where audit_id = @audit_id);

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

END

