write-output "getting runbook vars for blob copy"
$storageKey = Get-AutomationVariable -Name 'Partner A StorageKey'
$storageAccount = Get-AutomationVariable -Name 'Partner A Storage Account'
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
$srcContainer = Get-AutomationVariable -Name 'Partner A SrcContainer'
$dstContainer = Get-AutomationVariable -Name 'Partner A DstContainer'
$srcblob = Get-AutomationVariable -Name 'Partner A SrcBlob'
$smanblob = $srcblob -replace 'psv.gz','man'
$dstblob = [string](get-date).year+"/"+[string](get-date).month+"/"+$srcblob+'_'+[string](get-date -format "yyyyMMddHHmmss")
$dmanblob= [string](get-date).year+"/"+[string](get-date).month+"/"+$smanblob+'_'+[string](get-date -format "yyyyMMddHHmmss")
write-output "copying Data blobs"
$tcdevblob = Start-AzureStorageBlobCopy -SrcBlob $srcblob -SrcContainer $srcContainer -DestContainer $dstContainer -DestBlob $dstblob -Context $storageContext

$status = $tcdevblob | Get-AzureStorageBlobCopyState
write-output $status

write-output "copying manifest blobs"
$tcdevblob = Start-AzureStorageBlobCopy -SrcBlob $smanblob -SrcContainer $srcContainer -DestContainer $dstContainer -DestBlob $dmanblob -Context $storageContext
$status = $tcdevblob | Get-AzureStorageBlobCopyState
write-output $status