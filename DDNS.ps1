#requires -version 2
<#
.SYNOPSIS
DNS update script
.DESCRIPTION
The script takes the dynamic ip address from no-ip and pushes this into AWS R53
.INPUTS
C:\Script\DDNS\Aname.txt
.OUTPUTS
C:\Script\DDNS\Aname.txt
.NOTES
  Version:        1.0
  Author:         Glenn O'Sullivan
  Creation Date:  31/01/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
./DDNS.ps1
#>


#Import
Import-Module AWSpowershell
Set-AWSCredential -AccessKey xxxxxxxxxxxxxxxx -SecretKey xxxxxxxxxxxxxxxxxxxxxxxxxx

#check the current A name value
$currentA = Resolve-DnsName -Name Domain.ddns.net
$currentA = $currentA.ipaddress
nslookup Domain.ddns.net


#get last A name value
$lastA = Get-Content C:\Script\DDNS\Aname.txt

#test if there is a change 
if( $currentA -ne $lastA)
{
	Write-Host "vaule does not match, running update"

	#Setting up mail alert

	$SmtpServer = 'smtp.live.com'
	$SmtpUser = 'xxxxx@outlook.com'
	$smtpPassword = 'xxxxxxxxxxxxxxx'
	$MailFrom = 'xxxxx@outlook.com'
	$MailSubject = "DDNS Update" 
	$MailBody	="Updating A name to $currentA"

	$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $SmtpUser, $($smtpPassword | ConvertTo-SecureString -AsPlainText -Force) 
	Send-MailMessage -To "xxxxxxxxxxxxxxx@outlook.com" -from "$MailFrom" -Subject $MailSubject  -body $MailBody -SmtpServer $SmtpServer -Port 587 -Credential $Credentials -UseSsl


	$change1 = New-Object Amazon.Route53.Model.Change
	$change1.Action = "DELETE"
	$change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
	$change1.ResourceRecordSet.Name = "Domain.ie"
	$change1.ResourceRecordSet.Type = "A"
	$change1.ResourceRecordSet.TTL = 600
	$change1.ResourceRecordSet.ResourceRecords.Add(@{Value="$lastA"})

	$change2 = New-Object Amazon.Route53.Model.Change
	$change2.Action = "CREATE"
	$change2.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
	$change2.ResourceRecordSet.Name = "Domain.ie"
	$change2.ResourceRecordSet.Type = "A"
	$change2.ResourceRecordSet.TTL = 600
	$change2.ResourceRecordSet.ResourceRecords.Add(@{Value="$currentA"})

	$params = @{

		HostedZoneId="xxxxxxxxxxxxxxx"
		ChangeBatch_Comment="Script update."
		ChangeBatch_Change=$change1,$change2

		}
	
	Edit-R53ResourceRecordSet @params

	#cleanup
	Remove-Item C:\Script\DDNS\Aname.txt
	$currentA | out-file C:\Script\DDNS\Aname.txt


}
else {
	get-date | Out-File C:\Script\DDNS\Log.txt -Append
	"Current IP matches expected value" | Out-File C:\Script\DDNS\Log.txt -Append
	

}