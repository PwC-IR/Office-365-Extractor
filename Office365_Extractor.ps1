<#
Copyright 2019 PricewaterhouseCoopers Advisory N.V.
	N.B. The idea for this script is based on a script developed by Tehnoon Raza (Microsoft) and published in the following blog:
	https://blogs.msdn.microsoft.com/tehnoonr/2018/01/26/retrieving-office-365-audit-data-using-
	powershell/
	PricewaterhouseCoopers Advisory N.V. (PwC 1 ) has expanded and altered the script.
Redistribution and use in source and binary forms, with or without modification, are permitted provided that
the following conditions are met:
	1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
	   following disclaimer in the documentation and/or other materials provided with the distribution.
	3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or
	   promote products derived from this software without specific prior written permission.
	
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS &quot;AS IS&quot; AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
HENCE, USE OF THE SCRIPT IS FOR YOUR OWN ACCOUNT, RESPONSIBILITY AND RISK. YOU SHOULD
NOT USE THE (RESULTS OF) THE SCRIPT WITHOUT OBTAINING PROFESSIONAL ADVICE. PWC DOES
NOT PROVIDE ANY WARRANTY, NOR EXPLICIT OR IMPLICIT, WITH REGARD TO THE CORRECTNESS
OR COMPLETENESS OF (THE RESULTS) OF THE SCRIPT. PWC, ITS REPRESENTATIVES, PARTNERS
AND EMPLOYEES DO NOT ACCEPT OR ASSUME ANY LIABILITY OR DUTY OF CARE FOR ANY
(POSSIBLE) CONSEQUENCES OF ANY ACTION OR OMISSION BY ANYONE AS A CONSEQUENCE OF THE
USE OF (THE RESULTS OF) SCRIPT OR ANY DECISION BASED ON THE USE OF THE INFORMATION
CONTAINED IN (THE RESULTS OF) THE SCRIPT.
‘PwC’ refers to the PwC network and/or one or more of its member firms. Each member firm in the PwC
network is a separate legal entity. For further details, please see www.pwc.com/structure.
#>

$menupart1=@"
   ____     __    __   _                   ____      __    _____     ______          _                           _                  
  / __ \   / _|  / _| (_)                 |___ \    / /   | ____|   |  ____|        | |                         | |                 
 | |  | | | |_  | |_   _    ___    ___      __) |  / /_   | |__     | |__    __  __ | |_   _ __    __ _    ___  | |_    ___    _ __ 
 | |  | | |  _| |  _| | |  / __|  / _ \    |__ <  | '_ \  |___ \    |  __|   \ \/ / | __| | '__|  / _` |  / __| | __|  / _ \  | '__|
 | |__| | | |   | |   | | | (__  |  __/    ___) | | (_) |  ___) |   | |____   >  <  | |_  | |    | (_| | | (__  | |_  | (_) | | |    
  \____/  |_|   |_|   |_|  \___|  \___|   |____/   \___/  |____/    |______| /_/\_\  \__| |_|     \__,_|  \___|  \__|  \___/  |_|   
                                                                                                                                    
                                                                                                                                    
Script created by Joey Rentenaar & Korstiaan Stam @ PwC Incident Response Netherlands
Visit our Github https://github.com/PwC-IR/Office-365-Extractor for the full readme
"@

Clear-Host
$menupart1


function Get-startDate{
    Do {    
	    $DateStart= read-host "Please enter start date (format: yyyy-MM-dd) or ENTER for maximum 90 days"
        if ([string]::IsNullOrWhiteSpace($DateStart)) { $DateStart = [datetime]::Now.ToUniversalTime().AddDays(-90) }
		$StartDate = $DateStart -as [datetime]
		if (!$StartDate) { write-host "Not A valid date and time"}
	} while ($StartDate -isnot [datetime])
	   
    return Get-Date $startDate -Format "yyyy-MM-dd HH:mm:ss"
	
}

function Get-endDate{
    Do {    
        $DateEnd= read-host "Please enter end date (format: yyyy-MM-dd) or ENTER for today"
        if ([string]::IsNullOrWhiteSpace($DateEnd)) { $DateEnd =  [datetime]::Now.ToUniversalTime() }
		$EndDate = $DateEnd -as [datetime]
		if (!$EndDate) { write-host "Not A valid date and time"}
    } while ($EndDate -isnot [datetime])

    return Get-Date $EndDate -Format "yyyy-MM-dd HH:mm:ss"
}

function Users{
	write-host "Would you like to extract log events for [1]All users or [2]Specific users"
	$AllorSingleUse = read-host ">"
	
	if($AllorSingleUse -eq "1"){
		write-host "Extracting the Unified Audit Log for all users..."
		$script:Userstoextract = "*"}
	
	elseif($AllorSingleUse -eq "2"){
		write-host "Provide accounts that you wish to acquire, use comma separated values for multiple accounts, example (bob@acmecorp.onmicrosoft.com,alice@acmecorp.onmicrosoft.com)"
		$script:Userstoextract = read-host ">"}
		
	else{
		write-host "Please pick between option 1 or 2"
		Users}}


function Main{
	####################Configuration settings####################
	$OutputFileNumberAuditlogs = "\Log_Directory\Amount_Of_Audit_Logs.csv"
	$AuditLog = "\Log_Directory\AuditLog.txt"
	$LogDirectory = "\Log_Directory"
	$CSVoutput = "\Log_Directory\AuditRecords.csv"
	$LogDirectoryPath = Join-Path $PSScriptRoot $LogDirectory
	$LogFile = Join-Path $PSScriptRoot $AuditLog
	$OutputDirectory = Join-Path $PSScriptRoot $OutputFileNumberAuditlogs
	$OutputFile = Join-Path $PSScriptRoot $CSVoutput	
  
	#The maximum number of results Microsoft allows is 5000 for each PowerShell session.
	$ResultSize = 5000
	$RetryCount = 3
	$CurrentTries = 0

	If(!(test-path $LogDirectoryPath)){
		New-Item -ItemType Directory -Force -Path $LogDirectoryPath}

	Function Write-LogFile ([String]$Message){
		$final = [DateTime]::Now.ToString() + ":" + $Message
		$final | Out-File $LogFile -Append} 

	Switch ($script:input){
	#Show available log sources and amount of logs
	"1" {
		Users
		write-host ""
		
		$StartDate = Get-StartDate
		$EndDate = Get-EndDate
		
		$UserCredential = Get-Credential
		Connect-ExchangeOnline -Credential $UserCredential
		
		$RecordTypes = "ExchangeAdmin","ExchangeItem","ExchangeItemGroup","SharePoint","SyntheticProbe","SharePointFileOperation","OneDrive","AzureActiveDirectory","AzureActiveDirectoryAccountLogon","DataCenterSecurityCmdlet","ComplianceDLPSharePoint","Sway","ComplianceDLPExchange","SharePointSharingOperation","AzureActiveDirectoryStsLogon","SkypeForBusinessPSTNUsage","SkypeForBusinessUsersBlocked","SecurityComplianceCenterEOPCmdlet","ExchangeAggregatedOperation","PowerBIAudit","CRM","Yammer","SkypeForBusinessCmdlets","Discovery","MicrosoftTeams","ThreatIntelligence","MailSubmission","MicrosoftFlow","AeD","MicrosoftStream","ComplianceDLPSharePointClassification","ThreatFinder","Project","SharePointListOperation","SharePointCommentOperation","DataGovernance","Kaizala","SecurityComplianceAlerts","ThreatIntelligenceUrl","SecurityComplianceInsights","MIPLabel","WorkplaceAnalytics","PowerAppsApp","PowerAppsPlan","ThreatIntelligenceAtpContent","LabelContentExplorer","TeamsHealthcare","ExchangeItemAggregated","HygieneEvent","DataInsightsRestApiAudit","InformationBarrierPolicyApplication","SharePointListItemOperation","SharePointContentTypeOperation","SharePointFieldOperation","MicrosoftTeamsAdmin","HRSignal
","MicrosoftTeamsDevice","MicrosoftTeamsAnalytics","InformationWorkerProtection","Campaign","DLPEndpoint","AirInvestigation","Quarantine","MicrosoftForms","ApplicationAudit","ComplianceSupervisionExchange","CustomerKeyServiceEncryption","OfficeNative","MipAutoLabelSharePointItem","MipAutoLabelSharePointPolicyLocation","MicrosoftTeamsShifts","MipAutoLabelExchangeItem","CortanaBriefing","Search","WDATPAlerts","MDATPAudit"
		
		If(!(test-path $OutputDirectory)){
			Write-host "Creating the following file:" $OutputDirectory}
		else{
			$OutputFile = "Amount_Of_Audit_Logs.csv"
			$date = [datetime]::Now.ToString('HHmm') 
			$OutputFile = "\Log_Directory\"+$date+"_"+$OutputFile
			$OutputDirectory = Join-Path $PSScriptRoot $OutputFile}
		
		echo ""
		Write-Host "---------------------------------------------------------------------------"
		Write-Host "|The number of logs between"$StartDate" and "$EndDate" is|"
		Write-Host "---------------------------------------------------------------------------" 
		echo ""
		Write-Host "Calculating the number of audit logs" -ForegroundColor Green
		$TotalCount = Search-UnifiedAuditLog -UserIds $script:Userstoextract -StartDate $StartDate -EndDate $EndDate -ResultSize 1 | out-string -Stream | select-string ResultCount
		Foreach ($record in $RecordTypes){	
			$SpecificResult = Search-UnifiedAuditLog -UserIds $script:Userstoextract -StartDate $StartDate -EndDate $EndDate -RecordType $record -ResultSize 1 | out-string -Stream | select-string ResultCount
			if($SpecificResult){
				$number = $SpecificResult.tostring().split(":")[1]
				Write-Output $record":"$number
				Write-Output "$record - $number" | Out-File $OutputDirectory -Append}
			else {}}
		if($TotalCount){
			$numbertotal =$TotalCount.tostring().split(":")[1]
			Write-Host "--------------------------------------"
			Write-Host "Total count:"$numbertotal
			Write-host "Count complete file is written to $outputDirectory"
			$StringTotalCount = "Total Count:"
			Write-Output "$StringTotalCount $numbertotal" | Out-File $outputDirectory -Append}
		else{
			Write-host "No records found."}
			
		echo ""
		Menu}
	
	#2 Extract all audit logs
	"2" {
		Users
		write-host ""
	
		If(!(test-path $OutputFile)){
			Write-host "Creating the following file:" $OutputFile}
		else{
			$date = [datetime]::Now.ToString('HHmm') 
			$OutputFile = "Log_Directory\"+$date+"AuditRecords.csv"
			$OutputDirectory = Join-Path $PSScriptRoot $OutputFile}
		echo ""
		
		[DateTime]$StartDate = Get-StartDate
		[DateTime]$EndDate = Get-EndDate
		
		echo ""
		write-host "Recommended interval: 60"
		Write-host "Lower the time interval for environments with a high log volume"
		echo ""
		
		
		$IntervalMinutes = read-host "Please enter a time interval or ENTER for 60"
		if ([string]::IsNullOrWhiteSpace($IntervalMinutes)) { $IntervalMinutes = "60" }
		
		$ResetInterval = $IntervalMinutes
		
		Write-LogFile "Start date provided by user: $StartDate"
		Write-LogFile "End date provided by user: $EndDate"
		Write-Logfile "Time interval provided by user: $IntervalMinutes"
		[DateTime]$CurrentStart = $StartDate
		[DateTime]$CurrentEnd = $EndDate
		
		$UserCredential = Get-Credential
		Connect-ExchangeOnline -Credential $UserCredential
		
		echo ""
		Write-Host "------------------------------------------------------------------------------------------"
		Write-Host "|Extracting all available audit logs between "$StartDate" and "$EndDate                "|"
		$prefix = "|Time interval: $IntervalMinutes                                                          "
    	1..$IntervalMinutes.ToString().Length | % {$prefix = $prefix.Substring(0,$prefix.Length-1)}
    	Write-Host $prefix "|"
		Write-Host "------------------------------------------------------------------------------------------" 
		echo ""
		 
		while ($true){
			$CurrentEnd = $CurrentStart.AddMinutes($IntervalMinutes)
			
			$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
			if($AmountResults){
				$number = $AmountResults.tostring().split(":")[1]
				$script:integer = [int]$number
				
				while ($script:integer -gt 5000){
					$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
					if($AmountResults){
						$number = $AmountResults.tostring().split(":")[1]
						$script:integer = [int]$number
						if ($script:integer -lt 5000){
							if ($IntervalMinutes -eq 0){
								Exit
								}
							else{
								write-host "INFO: Temporary lowering time interval to $IntervalMinutes minutes" -ForegroundColor Yellow
								}}
						else{
							$IntervalMinutes = $IntervalMinutes / 2
							$CurrentEnd = $CurrentStart.AddMinutes($IntervalMinutes)}}
							
					else{
						Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
						Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
						$Intervalmin = $IntervalMinutes
						$CurrentStart = $CurrentStart.AddMinutes($Intervalmin)
						$CurrentEnd = $CurrentStart.AddMinutes($Intervalmin)
						$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
						if($AmountResults){
							$number = $AmountResults.tostring().split(":")[1]
							$script:integer = [int]$number}}}
					}
							
			ELSE{
				$IntervalMinutes = $ResetInterval}
				
			
			if ($CurrentEnd -gt $EndDate){				
				$DURATION = $EndDate - $Backupdate
				$durmin = $DURATION.TotalMinutes
				
				$CurrentEnd = $Backupdate
				$CurrentStart = $Backupdate
				
				$IntervalMinutes = $durmin /2
				if ($IntervalMinutes -eq 0){
					Exit}
				else{
					write-host "INFO: Temporary lowering time interval to $IntervalMinutes minutes" -ForegroundColor Yellow
					$CurrentEnd = $CurrentEnd.AddMinutes($IntervalMinutes)}
					}
			
			ELSEIF($CurrentEnd -eq $EndDate){
				Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
				Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
				
				[Array]$results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -SessionID $SessionID -UserIds $script:Userstoextract -SessionCommand ReturnNextPreviewPage -ResultSize $ResultSize
				if($results){
					$results | epcsv $OutputFile -NoTypeInformation -Append
				}
				write-host "Quiting.." -ForegroundColor Red
				break
				Menu
			}
				
			$CurrentTries = 0
			$SessionID = [DateTime]::Now.ToString().Replace('/', '_')
			Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
			Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
			
			 
			while ($true){		
				$CurrentEnd = $CurrentEnd.AddSeconds(-1)				
				[Array]$results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -SessionID $SessionID -UserIds $script:Userstoextract -SessionCommand ReturnNextPreviewPage -ResultSize $ResultSize
				$CurrentEnd = $CurrentEnd.AddSeconds(1)
				$CurrentCount = 0
				
				if ($results -eq $null -or $results.Count -eq 0){
					if ($CurrentTries -lt $RetryCount){
						$CurrentTries = $CurrentTries + 1
						continue}
					else{
						Write-LogFile "WARNING: Empty data set returned between $($CurrentStart) and $($CurrentEnd). Retry count reached. Moving forward!"
						break}}
						
				$CurrentTotal = $results[0].ResultCount
				$CurrentCount = $CurrentCount + $results.Count
				
				if ($CurrentTotal -eq $results[$results.Count - 1].ResultIndex){
					$message = "INFO: Successfully retrieved $($CurrentCount) records out of total $($CurrentTotal) for the current time range. Moving on!"
					$results | epcsv $OutputFile -NoTypeInformation -Append
					write-host $message
					Write-LogFile $message
					break}}
			
			$CurrentStart = $CurrentEnd
			[DateTime]$Backupdate = $CurrentEnd}
		
		#SHA256 hash calculation for the output files
		$HASHValues = Join-Path $PSScriptRoot "\Log_Directory\Hashes.csv"
		Get-ChildItem $LogDirectoryPath -Filter *AuditRecords.csv | Get-FileHash -Algorithm SHA256 | epcsv $HASHValues
		echo ""
		Menu}
	 
	#3Extract group of logs
	"3" {
	
		Write-host "1: Extract all Exchange logging"
		Write-host "2: Extract all Azure logging"
		Write-host "3: Extract all Sharepoint logging"
		Write-host "4: Extract all Skype logging"
		write-host "5: Back to menu"
		
		$inputgroup = Read-Host "Select an action"
		
		IF($inputgroup -eq "1"){
			$RecordTypes = "ExchangeAdmin","ExchangeAggregatedOperation","ExchangeItem","ExchangeItemGroup","ExchangeItemAggregated","ComplianceDLPExchange","ComplianceSupervisionExchange","MipAutoLabelExchangeItem"
			$RecordFile = "AllExchange"}
		ELSEIF($inputgroup -eq "2"){
			$RecordTypes = "AzureActiveDirectory","AzureActiveDirectoryAccountLogon","AzureActiveDirectoryStsLogon"
			$RecordFile = "AllAzure"}
		ELSEIF($inputgroup -eq "3"){
			$RecordTypes = "ComplianceDLPSharePoint","SharePoint","SharePointFileOperation","SharePointSharingOperation","SharepointListOperation", "ComplianceDLPSharePointClassification","SharePointCommentOperation", "SharePointListItemOperation", "SharePointContentTypeOperation", "SharePointFieldOperation","MipAutoLabelSharePointItem","MipAutoLabelSharePointPolicyLocation"
			$RecordFile = "AllSharepoint"}
		ELSEIF($inputgroup -eq "4"){
			$RecordTypes = "SkypeForBusinessCmd","SkypeForBusinessPSTNUsage","SkypeForBusinessUsersBlocked"
			$RecordFile = "AllSkype"}
		ELSE{
			Menu}
		
		write-host ""
		Users
		Write-host ""
		
		[DateTime]$StartDate = Get-StartDate
		[DateTime]$EndDate = Get-EndDate
		
		echo ""
		write-host "Recommended interval is 60"
		Write-host "Lower the time interval for environments with a high log volume"
		echo ""
		
		$IntervalMinutes = read-host "Please enter a time interval or ENTER for 60"
		if ([string]::IsNullOrWhiteSpace($IntervalMinutes)) { $IntervalMinutes = "60" }
		
		$ResetInterval = $IntervalMinutes
		
		Write-LogFile "Start date provided by user: $StartDate"
		Write-LogFile "End date provided by user: $EndDate"
		Write-Logfile "Time interval provided by user: $IntervalMinutes"
		
		$UserCredential = Get-Credential
		Connect-ExchangeOnline -Credential $UserCredential
		
		echo ""
		Write-Host "----------------------------------------------------------------------------"
		Write-Host "|Extracting audit logs between "$StartDate" and "$EndDate"|"
		$prefix = "|Time interval: $IntervalMinutes                                                          "
    	1..$IntervalMinutes.ToString().Length | % {$prefix = $prefix.Substring(0,$prefix.Length-1)}
    	Write-Host $prefix "|"
		Write-Host "----------------------------------------------------------------------------" 
		Write-Host "The following RecordTypes are configured to be extracted:" -ForegroundColor Green
		Foreach ($record in $RecordTypes){
			Write-Host "-$record"}
		echo ""
		
		Foreach ($record in $RecordTypes){
			$SpecificResult = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
	
			if($SpecificResult){
				$NumberOfLogs = $SpecificResult.tostring().split(":")[1]
				$CSVOutputFile = "\Log_Directory\"+$RecordFile+"_AuditRecords.csv"
				$OutputFile = Join-Path $PSScriptRoot $CSVOutputFile
				
				If(!(test-path $OutputFile)){
						Write-host "Creating the following file:" $OutputFile}
					
				[DateTime]$CurrentStart = $StartDate
				[DateTime]$CurrentEnd = $EndDate
				Write-Host "Extracting:  $record"
				echo ""
				
				while ($true){
					$CurrentEnd = $CurrentStart.AddMinutes($IntervalMinutes)
					$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
					
					if($AmountResults){
						$number = $AmountResults.tostring().split(":")[1]
						$script:integer = [int]$number
					
						while ($script:integer -gt 5000){
							$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
							if($AmountResults){
									$number = $AmountResults.tostring().split(":")[1]
									$script:integer = [int]$number
									if ($script:integer -lt 5000){
										if ($IntervalMinutes -eq 0){
											Exit}
										else{
											write-host "INFO: Temporary lowering time interval to $IntervalMinutes minutes" -ForegroundColor Yellow}}
									else{
										$IntervalMinutes = $IntervalMinutes / 2
										$CurrentEnd = $CurrentStart.AddMinutes($IntervalMinutes)}}
									
							else{
								Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
								Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
								$Intervalmin = $IntervalMinutes
								$CurrentStart = $CurrentStart.AddMinutes($Intervalmin)
								$CurrentEnd = $CurrentStart.AddMinutes($Intervalmin)
								$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
								if($AmountResults){
									write-host $AmountResults
									$number = $AmountResults.tostring().split(":")[1]
									$script:integer = [int]$number}}}}
							
						ELSE{
							$IntervalMinutes = $ResetInterval}
						if ($CurrentEnd -gt $EndDate){				
							$DURATION = $EndDate - $Backupdate
							$durmin = $DURATION.TotalMinutes
							
							$CurrentEnd = $Backupdate
							$CurrentStart = $Backupdate
							
							$IntervalMinutes = $durmin /2
							if ($IntervalMinutes -eq 0){
								Exit
								}
							else{
								write-host "INFO: Temporary lowering time interval to $IntervalMinutes minutes" -ForegroundColor Yellow
								}
							$CurrentEnd = $CurrentEnd.AddMinutes($IntervalMinutes)}
						
						ELSEIF($CurrentEnd -eq $EndDate){
							Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
							Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
							
							[Array]$results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -SessionID $SessionID -UserIds $script:Userstoextract -SessionCommand ReturnNextPreviewPage -ResultSize $ResultSize
							if($results){
								$results | epcsv $OutputFile -NoTypeInformation -Append
							}
							write-host "Quiting.." -ForegroundColor Red
							break
							Menu
						}
							
						$CurrentTries = 0
						$SessionID = [DateTime]::Now.ToString().Replace('/', '_')
						Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
						Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
						$CurrentCount = 0
						
						while ($true){
							$CurrentEnd = $CurrentEnd.AddSeconds(-1)
							[Array]$results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -SessionID $SessionID -SessionCommand ReturnNextPreviewPage -ResultSize $ResultSize
							$CurrentEnd = $CurrentEnd.AddSeconds(1)
							
							if ($results -eq $null -or $results.Count -eq 0){
								if ($CurrentTries -lt $RetryCount){
									$CurrentTries = $CurrentTries + 1
									continue}
								else{
									Write-LogFile "WARNING: Empty data set returned between $($CurrentStart) and $($CurrentEnd). Retry count reached. Moving forward!"
									break}}
									
							$CurrentTotal = $results[0].ResultCount
							$CurrentCount = $CurrentCount + $results.Count
							
							if ($CurrentTotal -eq $results[$results.Count - 1].ResultIndex){
								$message = "INFO: Successfully retrieved $($CurrentCount) records out of total $($CurrentTotal) for the current time range. Moving on!"
								$results | epcsv $OutputFile -NoTypeInformation -Append
								Write-LogFile $message
								Write-host $message
								break}}
							
						$CurrentStart = $CurrentEnd
						[DateTime]$Backupdate = $CurrentEnd}}
						
						else{
							Write-Host "No logs available for $record"  -ForegroundColor red
							echo ""}}
							
					#SHA256 hash calculation for the output files
					$HASHValues = Join-Path $PSScriptRoot "\Log_Directory\Hashes.csv"
					Get-ChildItem $LogDirectoryPath -Filter *_AuditRecords.csv | Get-FileHash -Algorithm SHA256 | epcsv $HASHValues
					
					echo ""
					Menu}
				
	#4 Extract specific audit logs
	"4" {		
		#All RecordTypes can be found at:
		#https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#enum-auditlogrecordtype---type-edmint32
		#https://docs.microsoft.com/en-us/powershell/module/exchange/policy-and-compliance-audit/search-unifiedauditlog?view=exchange-ps
		#Known RecordTypes please check the above links as these types get updated: "SharePointFieldOperation","TeamsHealthcare","LabelExplorer","PowerAppsPlan","HygieneEvent","PowerAppsApp","ExchangeItemAggregated","SecurityComplianceInsights","WorkplaceAnalytics","DataGovernance","ThreatFinder","AeD","ThreatIntelligenceAtpContent","ThreatIntelligenceUrl","MicrosoftStream","Project","SharepointListOperation","SecurityComplianceAlerts","ThreatIntelligenceUrl","AzureActiveDirectory","AzureActiveDirectoryAccountLogon","AzureActiveDirectoryStsLogon","ComplianceDLPExchange","ComplianceDLPSharePoint","CRM","DataCenterSecurityCmdlet","Discovery","ExchangeAdmin","ExchangeAggregatedOperation","ExchangeItem","ExchangeItemGroup","MicrosoftTeamsAddOns","MicrosoftTeams","MicrosoftTeamsSettingsOperation","OneDrive","PowerBIAudit","SecurityComplianceCenterEOPCmdlet","SharePoint", "SharePointFileOperation","SharePointSharingOperation","SkypeForBusinessCmdlets","SkypeForBusinessPSTNUsage","SkypeForBusinessUsersBlocked","Sway","ThreatIntelligence","Yammer"
		write-host "Enter the RecordType(s) that need to be extracted, multiple recordtypes can be entered using comma separated values" -ForegroundColor Green
		write-host "The different RecordTypes can be found on our Github page (https://github.com/PwC-IR/Office-365-Extractor)"
		write-host "Example: SecurityComplianceCenterEOPCmdlet,SecurityComplianceAlerts,SharepointListOperation"
		$RecordTypes = read-host ">"
		echo ""
		
		[DateTime]$StartDate = Get-StartDate
		[DateTime]$EndDate = Get-EndDate
		
		echo ""
		write-host "Recommended interval is 60"
		Write-host "Lower the time interval for environments with a high log volume"
		echo ""
		
		$IntervalMinutes = read-host "Please enter a time interval or ENTER for 60"
		if ([string]::IsNullOrWhiteSpace($IntervalMinutes)) { $IntervalMinutes = "60" }
		
		$ResetInterval = $IntervalMinutes
		
		Write-LogFile "Start date provided by user: $StartDate"
		Write-LogFile "End date provided by user: $EndDate"
		Write-Logfile "Time Interval provided by user: $IntervalMinutes"
		$UserCredential = Get-Credential
		Connect-ExchangeOnline -Credential $UserCredential
		echo ""
		Write-Host "----------------------------------------------------------------------------"
		Write-Host "|Extracting audit logs between "$StartDate" and "$EndDate"|"
		$prefix = "|Time interval: $IntervalMinutes                                                          "
    	1..$IntervalMinutes.ToString().Length | % {$prefix = $prefix.Substring(0,$prefix.Length-1)}
    	Write-Host $prefix "|"
		Write-Host "----------------------------------------------------------------------------" 
		Write-Host "The following RecordTypes are configured to be extracted:" -ForegroundColor Green
		
		Foreach ($record in $RecordTypes.Split(",")){
			Write-Host "-$record"}
		echo ""
		Foreach ($record in $RecordTypes.Split(",")){
			$SpecificResult = Search-UnifiedAuditLog -StartDate $StartDate -EndDate $EndDate -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
			if($SpecificResult) {
				$NumberOfLogs = $SpecificResult.tostring().split(":")[1]
				$CSVOutputFile = "\Log_Directory\"+$record+"_AuditRecords.csv"
				$LogFile = Join-Path $PSScriptRoot $AuditLog
				$OutputFile = Join-Path $PSScriptRoot $CSVOutputFile
				
				If(!(test-path $OutputFile)){
						Write-host "Creating the following file:" $OutputFile}
				else{
					$date = [datetime]::Now.ToString('HHmm') 
					$CSVOutputFile = "Log_Directory\"+$date+$record+"_AuditRecords.csv"
					$OutputFile = Join-Path $PSScriptRoot $CSVOutputFile}
					
				[DateTime]$CurrentStart = $StartDate
				[DateTime]$CurrentEnd = $EndDate
				Write-Host "Extracting:  $record"
				Write-LogFile "Extracting:  $record"
				
				while ($true){
				$CurrentEnd = $CurrentStart.AddMinutes($IntervalMinutes)
				
				echo Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
				$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
				if($AmountResults){
					$number = $AmountResults.tostring().split(":")[1]
					$script:integer = [int]$number
					
					while ($script:integer -gt 5000){
						$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
						if($AmountResults){
							$number = $AmountResults.tostring().split(":")[1]
							$script:integer = [int]$number
							if ($script:integer -lt 5000){
								if ($IntervalMinutes -eq 0){
									Exit}
								else{
									write-host "INFO: Temporary lowering time interval to $IntervalMinutes minutes" -ForegroundColor Yellow}}
							else{
								$IntervalMinutes = $IntervalMinutes / 2
								$CurrentEnd = $CurrentStart.AddMinutes($IntervalMinutes)}}
							
						else{
							Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
							Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
							$Intervalmin = $IntervalMinutes
							$CurrentStart = $CurrentStart.AddMinutes($Intervalmin)
							$CurrentEnd = $CurrentStart.AddMinutes($Intervalmin)
							$AmountResults = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -ResultSize 1 | out-string -Stream | select-string ResultCount
							if($AmountResults){
								$number = $AmountResults.tostring().split(":")[1]
								$script:integer = [int]$number}}
								}}
					
				ELSE{
					$IntervalMinutes = $ResetInterval}
				if ($CurrentEnd -gt $EndDate){	
					$DURATION = $EndDate - $Backupdate
					$durmin = $DURATION.TotalMinutes
					
					$CurrentEnd = $Backupdate
					$CurrentStart = $Backupdate
					
					$IntervalMinutes = $durmin /2
					if ($IntervalMinutes -eq 0){
						Exit}
					else{
						write-host "INFO: Temporary lowering time interval to $IntervalMinutes minutes" -ForegroundColor Yellow}
						
					$CurrentEnd = $CurrentEnd.AddMinutes($IntervalMinutes)}
				
				ELSEIF($CurrentEnd -eq $EndDate){
					Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
					Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
					
					[Array]$results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -SessionID $SessionID -SessionCommand ReturnNextPreviewPage -ResultSize $ResultSize
					if($results){
						$results | epcsv $OutputFile -NoTypeInformation -Append
					}
					write-host "Quiting.." -ForegroundColor Red
					break
					Menu
				}
				$CurrentTries = 0
				$SessionID = [DateTime]::Now.ToString().Replace('/', '_')
				Write-LogFile "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)"
				Write-Host "INFO: Retrieving audit logs between $($CurrentStart) and $($CurrentEnd)" -ForegroundColor green
				$CurrentCount = 0
				while ($true){
					$CurrentEnd = $CurrentEnd.AddSeconds(-1)
					[Array]$results = Search-UnifiedAuditLog -StartDate $CurrentStart -EndDate $CurrentEnd -RecordType $record -UserIds $script:Userstoextract -SessionID $SessionID -SessionCommand ReturnNextPreviewPage -ResultSize $ResultSize
					$CurrentEnd = $CurrentEnd.AddSeconds(1)
					
					if ($results -eq $null -or $results.Count -eq 0){
						if ($CurrentTries -lt $RetryCount){
							$CurrentTries = $CurrentTries + 1
							continue}
						else{
							Write-LogFile "WARNING: Empty data set returned between $($CurrentStart) and $($CurrentEnd). Retry count reached. Moving forward!"
							break}}
							
					$CurrentTotal = $results[0].ResultCount
					$CurrentCount = $CurrentCount + $results.Count
					
					if ($CurrentTotal -eq $results[$results.Count - 1].ResultIndex){
						$message = "INFO: Successfully retrieved $($CurrentCount) records out of total $($CurrentTotal) for the current time range. Moving on!"
						$results | epcsv $OutputFile -NoTypeInformation -Append
						Write-LogFile $message
						Write-host $message
						break}}
					
				$CurrentStart = $CurrentEnd
				[DateTime]$Backupdate = $CurrentEnd}}
				
				else{
					Write-Host "No logs available for $record"  -ForegroundColor red
					echo ""}}
			
			#SHA256 hash calculation for the output files
			$HASHValues = Join-Path $PSScriptRoot "\Log_Directory\Hashes.csv"
			Get-ChildItem $LogDirectoryPath -Filter *_AuditRecords.csv | Get-FileHash -Algorithm SHA256 | epcsv $HASHValues -NoTypeInformation -Append	
			
			echo ""
			Menu}
	
	"5" {
@"
		
For a full readme please visit our Github page https://github.com/PwC-IR/Office-365-Extractor

Description of the tool:
For incident response or audit purposes the Microsoft Audit log contains important information. This tool helps you to acquire the logs with their hash values. 

Configuration:
Every command requires date input the format is based on your time locale, the script provides you with the correct format. Optionally you can specify a time as well with the format HH:MM
When one of the extraction methods is selected an audit file will be created and a file with the hashes of the output, which can be used to establish or mantain the chain of custody. 

Available commands

Option 1: "Show available log sources and amount of logging	" A search is executed and the total number of logs within the set timeframe will be displayed and written to a csv file called "Amount_Of_Audit_Logs.csv".

Option 2: "Extract all audit logging" this extraction option allows for extraction of all available audit logs within the set timeframe.	

Option 3: "Extract group audit logging" this extraction option allows for extraction of a group of logs for example extract all Exchange or Azure logging in one go.

Option 4: "Extract specific audit logging (advanced mode)" Use this option if you want to extract a subset of the audit logs. To configure what logs will be extracted the tool needs to be configured with the required Record Types. A full list of recordtypes and what is contained in them can be found at: https://docs.microsoft.com/en-us/office/office-365-management-api/office-365-management-activity-api-schema#enum-auditlogrecordtype---type-edmint32

"@}
	"6" {Write-Host "Quitting" -ForegroundColor Green}}}
function Menu{
$menupart2=@"
Following actions are supported by this script:
1 Show available log sources and amount of logging	
2 Extract all audit logging
3 Extract group audit logging
4 Extract specific audit logging (advanced mode)
5 ReadMe
6 Quit

"@
	$menupart2
	$script:input = Read-Host "Select an action" 
	Main
	While($script:input -ne "1" -and $script:input -ne "2" -and $script:input -ne "3" -and $script:input -ne "4" -and $script:input -ne "5" -and $script:input -ne "6"){
		Write-Host "I don't understand what you want to do." -ForegroundColor Red
		Write-Host " " 
		$script:input = Read-Host $menupart2
	Main}}
	
Menu
