#Change these variables first to match your environment.
$cloudadmin = "admin@domain.onmicrosoft.com"
$onpremadmin = "domain.local\onpremadmin"
$tenantURL = "domain.onmicrosoft.com"
$onpremURL = "mail.domain.org"
$targetdeliveryURL = "domain.org"
$onpremDB = "EX2013-03-DB01"
$archivedomain = "domain.mail.onmicrosoft.com"

#Create a folder on current user's desktop for logging.
If ((Test-Path “$ENV:USERPROFILE\Desktop\Move-ToOnPremHelper Logs”) -eq $false)
{
Write-Host "Creating folder on the Desktop for logging."
New-Item -Type Directory -Path "$ENV:USERPROFILE\Desktop\Move-ToOnPremHelper Logs"
}
Set-Location “$ENV:Userprofile\Desktop\Move-ToOnPremHelper Logs”
$ts = Get-Date -Format "M-d-yy";
$FormatEnumerationLimit = -1


#Gather some information
$alias = Read-Host "Please enter the alias of the user you wish to move to on-premises Exchange database $onpremDB."
$cloudcred = Get-Credential -UserName $cloudadmin -Message "☁ Enter O365 Tenant Admin Credentials ☁"
$onpremcred = Get-Credential -UserName $onpremadmin -Message "Enter On-Prem Admin Credentials"


#Connect to Office 365 Exchange Online PowerShell
Get-PSSession | Remove-PSSession
Write-Host "Connecting to Office 365 Exchange Online CloudShell™"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cloudcred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber

#Create the move request
$start = Get-Date
Write-Host "Creating new move request to on-premises Exchange database $onpremDB for $alias."
Write-Host "Creating new move request to on-premises Exchange database $onpremDB for $alias." | Out-File "$ENV:USERPROFILE\Desktop\Move-ToOnPremHelper Logs\$ts.$alias.txt"
New-MoveRequest $alias -Outbound -RemoteHostName $onpremURL -TargetDeliveryDomain $targetdeliveryURL -RemoteCredential $onpremcred -PrimaryOnly -RemoteTargetDatabase $onpremDB -ArchiveDomain $archivedomain
Get-MoveRequest $alias | Format-List | Out-File -Append "$ENV:USERPROFILE\Desktop\Move-ToOnPremHelper Logs\$ts.$alias.txt"

#Check move request status every 3 seconds until complete
Do  {
    Get-MoveRequestStatistics $alias | FT DisplayName,StatusDetail,TotalMailboxSize,PercentComplete -AutoSize
    Get-MoveRequestStatistics $alias | FT DisplayName,StatusDetail,TotalMailboxSize,PercentComplete -AutoSize | Out-File -Append "$ENV:USERPROFILE\Desktop\Move-ToOnPremHelper Logs\$ts.$alias.txt"
    $progress=(Get-MoveRequestStatistics $alias).PercentComplete
    sleep 3
    } 
    While ($progress -ne 100)
$end=Get-date
$result = ($end - $start)
Write-Host "Moving mailbox $alias to on-premises Exchange database $onpremDB took approximately $result to complete."
Write-Host "Moving mailbox $alias to on-premises Exchange database $onpremDB took approximately $result to complete." | Out-File -Append "$ENV:USERPROFILE\Desktop\Move-ToOnPremHelper Logs\$ts.$alias.txt"
Read-Host "Press enter to close."



