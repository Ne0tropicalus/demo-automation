# Get the username and password from the SQL Credential
	$SqlServer = Get-AutomationVariable -Name 'SqlServer'
	$Database = Get-AutomationVariable -Name 'Database'
	$sdwCredential = Get-AutomationPSCredential -Name 'sdwCredential'	
    $SqlUsername = $sdwCredential.UserName
    $SqlPass = $sdwCredential.GetNetworkCredential().Password
	
	$stage_tbl_name = Get-AutomationVariable -Name 'WARRANTY_PARTS_STG'
	$external_tbl_name = Get-AutomationVariable -Name 'WARRANTY_PARTS_RAW'
	$provider = Get-AutomationVariable -Name 'Partner A Storage Account'
    
# Define the connection to the SQL Database
		
$now=(get-date -format "yyyy-MM-dd HH:mm") + " Connecting to Sql Data Warehouse"
write-output $now

$stcon = 'Server='+ $SqlServer +
         '.database.windows.net;Database=' + $Database +
		 ';User ID=' + $SqlUsername +
		 ';Password=' + $SqlPass +
		 ';Trusted_Connection=False;Encrypt=True;Connection Timeout=30;'
			 
$Conn = New-Object System.Data.SqlClient.SqlConnection("$stcon")
        
# Open the SQL connection
$Conn.Open()

# Define the SQL command to run. In this case we are getting the number of rows in the table
        
$now=(get-date -format "yyyy-MM-dd HH:mm") +" Running Warranty Parts Stored Procedure"
write-output $now

$Cmd=new-object system.Data.SqlClient.SqlCommand("EXEC [TCDEVSQLDW].[dbo].[warranty_part_ingest]
													@provider = N'$provider',
													@file_compressed = N'Y',
													@external_tbl_name = N'$external_tbl_name',
													@stage_tbl_name = N'$stage_tbl_name'", $Conn)
$Cmd.CommandTimeout=900

# Execute the SQL command
$Ds = New-object system.Data.DataSet
$Da = New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
[void]$Da.fill($Ds)

$Ds
		
$now=(get-date -format "yyyy-MM-dd HH:mm") + " Getting Audit Record"
write-output $now
$Cmd=new-object system.Data.SqlClient.SqlCommand("SELECT * FROM [dbo].[BI_audit] where audit_id = (select max(audit_id) from [dbo].[BI_audit] where stage_table_name = '$stage_tbl_name' )", $Conn)

$Ds=New-Object system.Data.DataSet
$Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
[void]$Da.fill($Ds)
 
$Ds.Tables.Rows

# Close the SQL connection
$now=(get-date -format "yyyy-MM-dd HH:mm") + " runbook closing connection - finished"
write-output $now
$Conn.Close()