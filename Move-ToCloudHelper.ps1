#Change these variables first to match your environment
$cloudadmin = "admin@domain.onmicrosoft.com" #Office 365 account with global administrator role
$onpremadmin = "domain.local\onpremadmin" #On-premises domain admin
$tenantURL = "domain.onmicrosoft.com" #Office 365 tenant root domain
$onpremURL = "mail.domain.org" #On-premises OWA URL (for migration endpoint)

#Create a folder on current user's desktop for logging.
If ((Test-Path “$ENV:USERPROFILE\Desktop\Move-ToCloudHelper Logs”) -eq $false)
{
Write-Host "Folder not found, Creating folder on the Desktop for logging."
New-Item -Type Directory -Path "$ENV:USERPROFILE\Desktop\Move-ToCloudHelper Logs"
}
Set-Location “$ENV:Userprofile\Desktop\Move-ToCloudHelper Logs”
$ts = Get-Date -Format "M-d-yy";
$FormatEnumerationLimit = -1


#Gather some information
$alias = Read-Host "Please enter the alias of the user you wish to move to the cloud."
$cloudcred = Get-Credential -UserName $cloudadmin -Message "☁ Enter O365 Tenant Admin Credentials ☁"
$onpremcred = Get-Credential -UserName $onpremadmin -Message "Enter On-Prem Admin Credentials"


#Connect to Office 365 Exchange Online PowerShell
Get-PSSession | Remove-PSSession
Write-Host "Connecting to Office 365 Exchange Online CloudShell™"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cloudcred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber


#Create the move request
$start=Get-Date
New-MoveRequest $alias -Remote -RemoteHostName $onpremURL -TargetDeliveryDomain $tenantURL -RemoteCredential $onpremcred -PrimaryOnly 
Write-Host "Creating new move request to the cloud for $alias." | Out-File "$ENV:USERPROFILE\Desktop\Move-ToCloudHelper Logs\$ts.$alias.txt"
Sleep 5
Get-MoveRequest $alias | Format-List | Out-File -Append "$ENV:USERPROFILE\Desktop\Move-ToCloudHelper Logs\$ts.$alias.txt"

#Check move request status every 5 seconds until complete
Do  {
    Get-MoveRequestStatistics $alias | FT DisplayName,StatusDetail,TotalMailboxSize,PercentComplete -AutoSize
    Get-MoveRequestStatistics $alias | FT DisplayName,StatusDetail,TotalMailboxSize,PercentComplete -AutoSize | Out-File -Append "$ENV:USERPROFILE\Desktop\Move-ToCloudHelper Logs\$ts.$alias.txt"
    $progress=(Get-MoveRequestStatistics $alias).PercentComplete
    sleep 5
    } 
    While ($progress -ne 100)
    $end=Get-date

    $result = ($end - $start)

#Send finishing messages to the user
Write-Host "Moving mailbox $alias to the cloud took approximately $result to complete."
Write-Host "Moving mailbox $alias to the cloud took approximately $result to complete." | Out-File -Append "$ENV:USERPROFILE\Desktop\Move-ToCloudHelper Logs\$ts.$alias.txt"
Read-Host "Press enter to close."