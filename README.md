<h3>Office 365 Extractor</h3>
This script makes it possible to extract log data out of an Office365 environment. The script created by us consist out of four main options, which enable the investigator to easily extract logging out of an Office365 environment. 

1.	Show available log sources and amount of logging
2.	Extract all audit logging
3.	Extract group audit logging
4.	Extract Specific audit logging (advanced mode)

<h3>Show available log sources and amount of logging</h3>
Pretty straightforward a search is executed and the total number of logs within the<br>
set timeframe will be displayed and written to a csv file called "Amount_Of_Audit_Logs.csv" the file is prefixed with a random number to prevent duplicates.

<h3>Extract all audit logs</h3>
Extract all audit logs" this option wil get all available audit logs within the set timeframe and written out to a file called AuditRecords.CSV.

<h3>Extract group logging</h3>
Extract a group of logs. You can for example extract all Exchange or Azure logging in one go<br>

<h3>Extract specific audit logs</h3>
Extract specific audit logs" Use this option if you want to extract a subset of the audit logs. To configure what logs will be extracted the tool needs to<br>
be configured with the required Record Types. A full list of recordtypes can be found at the bottom of this page.<br>
The output files will be writen in a directory called 'Log_Directory" and will be given the name of their recordtype e.g. (ExchangeItem_AuditRecords.csv) <br>

<h3>Prerequisites</h3>
	-PowerShell<br>
	-Office365 account with privileges to access/extract audit logging<br>
	-One of the following windows versions:<br> 
Windows 10, Windows 8.1, Windows 8, or Windows 7 Service Pack 1 (SP1)<br>
Windows Server 2019, Windows Server 2016, Windows Server 2012 R2, Windows Server 2012, or Windows Server 2008 R2 SP1<br>
<br>

You have to be assigned the View-Only Audit Logs or Audit Logs role in Exchange Online to search the Office 365 audit log.
By default, these roles are assigned to the Compliance Management and Organization Management role groups on the Permissions page in the Exchange admin center. To give a user the ability to search the Office 365 audit log with the minimum level of privileges, you can create a custom role group in Exchange Online, add the View-Only Audit Logs or Audit Logs role, and then add the user as a member of the new role group. For more information, see Manage role groups in Exchange Online.
https://docs.microsoft.com/en-us/office365/securitycompliance/search-the-audit-log-in-security-and-compliance)<br>

<h3>How to use the script</h3>
1.	Download the Office365_Extractor.ps1<br>
2.	Right click on the script and press "Run with PowerShell".<br>
3.	Now pick any of the options in the menu.<br>
4.     The logs will be written to the logdirectory in the folder where the script is located.<br>

<h3>Output</h3>
<b>Amount_Of_Audit_Logs.csv:</b><br>
Will show what logs are available and how many for each RecordType.<br>
<b>AuditLog.txt:</b><br>
The AuditLog stores valuable information for debugging.<br>
<b>AuditRecords.csv:</b><br>
When all logs are extracted they will be written to this file.<br>
<b>[RecordType]__AuditRecords:</b><br>
When extracting specific RecordTypes, logs are sorted on RecordType and written to a CSV file.<br>
The name of this file is the RecordType + _AuditRecords.<br>

<h3>Available RecordTypes</h3>
SyntheticProbe<br>
AzureActiveDirectory<br>
AzureActiveDirectoryAccountLogon<br>
AzureActiveDirectoryStsLogon<br>
ComplianceDLPExchange<br>
ComplianceDLPSharePoint<br>
CRM<br>
DataCenterSecurityCmdlet<br>
Discovery<br>
ExchangeAdmin<br>
ExchangeAggregatedOperation<br>
ExchangeItem<br>
ExchangeItemGroup<br>
MicrosoftTeamsAddOns<br>
MicrosoftTeams<br>
MicrosoftTeamsSettingsOperation<br>
OneDrive<br>
PowerBIAudit<br>
SecurityComplianceCenterEOPCmdlet<br>
SharePoint<br>
SharePointFileOperation<br>
SharePointSharingOperation<br>
SkypeForBusinessCmdlets<br>
SkypeForBusinessPSTNUsage<br>
SkypeForBusinessUsersBlocked<br>
Sway<br>
ThreatIntelligence<br>
Yammer<br>
MicrosoftStream<br>
Project<br>
SharepointListOperation<br>
SecurityComplianceAlerts<br>
ThreatIntelligenceUrl<br>
ThreatIntelligenceAtpContent<br>
AeD<br>
ThreatFinder<br>
DataGovernance<br>
WorkplaceAnalytics<br>
SecurityComplianceInsights<br>
ExchangeItemAggregated<br>
PowerAppsApp<br>
HygieneEvent<br>
PowerAppsPlan<br>
LabelExplorer<br>
TeamsHealthcare<br>
SharePointFieldOperation<br>

<h3>Frequently Asked Questions</h3>
<b>If I enable mailbox auditing now can I see historical records?</b><br>
No, additionaly if you enable auditing now it will take up to 24 hours before events will be logged. 
<br>

<b>I logged into a mailbox with auditing turned on but I don't see my events?</b><br>
It can take up to 24 hours before an event is stored in the UAL.

<br>

<b>Which date format does the script accepts as input?</b><br>
The script will tell what the correct date format is. For Start and End data variables it will show between brackets what the format is (yyyy-MM-dd).<br>
<br>

<b>Do I need to configure the time period?</b><br>
No if you don't specify a time period the script will use the default If you don't include a timestamp in the value for the StartDate or EndDate parameters, the default timestamp 12:00 AM (midnight) is used.<br>
<br>

<b>What about timestamps?</b><br>
The audit logs are in UTC, and they will be exported as such<br>
<br>

<b>What is the retention period?</b><br>
Office 365 E3 - Audit records are retained for 90 days. That means you can search the audit log for activities that were performed within the last 90 days.

Office 365 E5 - Audit records are retained for 365 days (one year). That means you can search the audit log for activities that were performed within the last year. Retaining audit records for one year is also available for users that are assigned an E3/Exchange Online Plan 1 license and have an Office 365 Advanced Compliance add-on license.
<br>

<b>Can this script also acquire Message Trace Logs?</b><br>
At the moment it cannot, but there are several open-source scripts available that can help you with getting the MTL
One example can be found here: https://gallery.technet.microsoft.com/scriptcenter/Export-Mail-logs-to-CSV-d5b6c2d6
<br>

<h3>Known errors</h3>
<b>Import-PSSession : No command proxies have been created, because all of the requested remote....</b><br>
This error is caused when the script did not close correctly and an active session will be running in the background.
The script tries to import/load all modules again, but this is not necessary since it is already loaded. This error message has no impact on the script and will be gone when the open session gets closed. This can be done by restarting the PowerShell Windows or entering the following command: Get-PSSession | Remove-PSSession <br>

<b>Audit logging is enabled in the Office 365 environment but no logs are getting displayed?</b><br>
The user must be assigned an Office 365 E5 license. Alternatively, users with an Office 365 E1 or E3 license can be assigned an Advanced eDiscovery standalone license. Administrators and compliance officers who are assigned to cases and use Advanced eDiscovery to analyze data don't need an E5 license.<br>

<b>Audit log search argument start date should be after</b><br>
The start date should be earlier then the end date.

<b>New-PSSession: [outlook.office365.com] Connecting to remove server outlook.office365.com failed with the following error message: Access is denied.</b><br>
The password/username combination are incorrect or the user has not enough privileges to extract the audit logging.<br>
<br>
<br>
Custom script was developed by Joey Rentenaar and Korstiaan Stam from PwC Netherlands Incident Response team. <br>
Idea is based on a script developed by Tehnoon Raza from Microsoft:<br>
(https://blogs.msdn.microsoft.com/tehnoonr/2018/01/26/retrieving-office-365-audit-data-using-powershell/).
