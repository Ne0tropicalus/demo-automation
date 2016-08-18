DROP TABLE [dbo].[warranty_stg]
GO

CREATE TABLE [dbo].[warranty_stg]
(
    [audit_id] [int] NULL,
	[hash_claim_no] [int] NULL,
	[REGION_CD] [varchar](100) NULL,
	[CLAIMANT_CD] [varchar](100) NULL,
	[PARTNER_ORGANIZATION_NM] [varchar](100) NULL,
	[CLAIM_NO] [varchar](100) NULL,
	[VIN_CD] [varchar](50) NULL,
	[REPAIR_ORDER_NO] [varchar](100) NULL,
	[REPAIR_ORDER_DT] [datetime] NULL,
	[REPAIR_ORDER_MILE_QTY] [bigint] NULL,
	[DATE_OF_FIRST_USE_DT] [datetime] NULL,
	[MONTHS_IN_SERVICE_QTY] [bigint] NULL,
	[MAIN_OPCODE_CD] [varchar](100) NULL,
	[TOTAL_CLAIM_AMT] [decimal](34, 2) NULL,
	[MODEL_TYPE_TXT] [varchar](100) NULL,
	[MODEL_YEAR] [int] NULL,
	[REPAIR_PROGRAM_TYPE_CD] [varchar](100) NULL,
	[APPROVED_DT] [datetime] NULL,
	[REPAIR_PROGRAM_NO] [varchar](100) NULL,
	[CLAIM_CNT] [decimal](18, 0) NULL,
	[REPAIR_PROGRAM_TYPE_TXT] [varchar](100) NULL,
	[OPERATION_TXT] [varchar](100) NULL,
	[FRANCHISE_NM] [varchar](100) NULL,
	[EIDH_ORIG_SOURCE] [varchar](100) NULL,
	[EIDH_DATA_ACQUISITION_TYPE] [varchar](100) NULL,
	[EIDH_BATCH_ID] [varchar](100) NULL,
	[EIDH_OWNER] [varchar](100) NULL,
	[EIDH_LOAD_DATE] [varchar](100) NULL,
	[EIDH_EISP_CLASS] [varchar](100) NULL,
	[EIDH_DATA] [varchar](100) NULL,
	[RECORD_DATE] [datetime] NULL,
	[date_partition] [int] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [hash_claim_no] ),
	CLUSTERED COLUMNSTORE INDEX,
	PARTITION
	(
		[date_partition] RANGE RIGHT FOR VALUES (200601, 200701, 200801, 200901, 201001, 201101, 201201, 201301, 201401, 201501, 201601)
	)
)

GO


