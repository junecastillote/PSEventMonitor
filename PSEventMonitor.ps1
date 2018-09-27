<#	
.NOTES
===========================================================================
Created on:		26-Sept-2018
Author:			June Castillote
Email:			june.castillote@gmail.com, tito.castillote-jr@dxc.com
Filename:		PSEventMonitor.ps1
Version:		1.0 (26-Sept-2018)
===========================================================================

.LINK
https://www.lazyexchangeadmin.com/2018/09/PSEventMonitor.html
https://github.com/junecastillote/PSEventMonitor

.SYNOPSIS
Use PSEventMonitor.ps1 to retrieve and report on your monitored event IDs
This was based on the script from this site:
http://community.spiceworks.com/scripts/show/1714-central-monitor-powershell-event-log-email-reporter
		
.DESCRIPTION
FILES
==========
[PSEventMonitor.ps1]
> This is the main script file

[APPLICATION.TXT]
> File containing the list of events to monitor
> Can be any filename. See [EventsList] below under "FIELDS"

[CONFIG.XML]
> Configuration file that must be modified.
> See FIELDS below

FIELDS inside CONFIG.XML
===========
[SendEmail]
> Description: Your choice determines whether the report will be sent via email
> Acceptable Values: "$true", "$false"
			
[MailFrom]
> Description: This is the sender address that will appear in the report
> Acceptable Values: Email Address (eg. "event-alert@domain.com" -OR- "Event Monitor &lt;event-alert@domain.com&gt;"")
				
[MailTo]
> Description: Recipient(s) address. For multiple recipients, separate with a COMMA (,) with no spaces.
> Acceptable Values: Email Address (eg. "recipient@domain.com" -OR- "recipient1@domain.com,recipient2@domain.com")
				
[MailSubject]
> Description: The subject/title of the email report
> Acceptable Values: Nothing specific. (eg. "Event Alert!!!")
				
[MailServer]
> Description: The SMTP Relay server to use if you choice is to send the report via email.
> Acceptable Values: FQDN, Hostname, IP Address (eg. "relay.domain.com" -OR- "relay" -OR- "127.0.0.1")
				
[LogDepth]
> Description: The number of events to retrieve from the newest. If you are running this against a busy server that generates a lot of events, you may want to increase the value. Otherwise, the recommended value is "100"
> Acceptable Values: Number (eq. "100")
				
[RunInterval]
> Description: The interval, in minutes, with the process iterates.
> Acceptable Values: Number. (eg. to run the procedure every five minutes - "5")
				
[LogName]
> Description: The name of which event log to inspect.
> Acceptable Values: Any existing Event Log name (eg. "Application" -OR- "System")
				
[EventsList]
> Description:
* The name of the file that contains the list of events to query.
* This is a CSV file with only two fields - Source and ID
* The file must located in the same folder as the script
* Do not indicate the whole path, just the filename
> Acceptable Values: filename (eg. "application.txt")
				
[Computers]
> Description: List of computers to be monitored. Separate multiple computer names with COMMA (,)
> Acceptable Values: Hostname or Fqdn (eg. "COMPUTER1,COMPUTER2")	
#>
$scriptVersion = "1.0"
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$myCSSFile = $PSScriptRoot + "\style.css"
[xml]$xmlConfig = Get-Content ($PSScriptRoot + "\config.xml")
$eventsList = ($PSScriptRoot + "\" + $xmlConfig.Configuration.EventsList)

$LogName = $xmlConfig.Configuration.LogName
$historyLog = $PSScriptRoot + "\" + $LogName + "_Log_History.xml"
$LogDepth = $xmlConfig.Configuration.LogDepth
 
#run interval in minutes - set to zero for runonce, "C" for 0 delay continuous loop. 
$RunInterval = $xmlConfig.Configuration.RunInterval

$SendEmail = $xmlConfig.Configuration.SendEmail
$MailFrom = $xmlConfig.Configuration.MailFrom
[string[]]$MailTo = $xmlConfig.Configuration.MailTo.split(",")
$MailSubject = $xmlConfig.Configuration.MailSubject 
$MailServer = $xmlConfig.Configuration.MailServer 

#the list of the servers to be monitored is defined in the INI file "computers" key. 
[string[]]$computers = $xmlConfig.Configuration.computers.split(",")
$ListOfEvents = @{}
#import the list of Event Source and ID
Import-Csv $eventsList |ForEach-Object {$ListOfEvents[$_.source + '#' + $_.id] = 1}
 
#see if we have a history file to use, if not create an empty $logHistory
if (Test-Path $historyLog){$logHistory = Import-Clixml $historyLog} 
 else {$logHistory = @{}}
 
$timer = [System.Diagnostics.Stopwatch]::StartNew() 
 
Function SendReport { 
Write-Host "Sending Report"
Send-MailMessage -From $MailFrom -To $MailTo -Subject $MailSubject -Body $xEmailBody -SMTPServer $MailServer -BodyAsHtml -Priority High
} 
#START OF RUN PASS 
$run_pass = {
 
#$EmailBody = "<table><th>Event Log Monitor has detected the following events: `n</th></table><br>"
 
$computers |ForEach-Object{
$timer.reset() 
$timer.start() 
 
Write-Host "Started processing $($_)" 
 
#Get the index number of the last log entry 
$index = (Get-EventLog -ComputerName $_ -LogName $LogName -newest 1).index 
 
#if we have a history entry calculate number of events to retrieve 
#if we don't have an event history, use the $LogDepth to do initial seeding 
if ($logHistory[$_]){$n = $index - $logHistory[$_]} 
 else {$n = $LogDepth} 
  
if ($n -lt 0){ 
 Write-Host "Log index changed since last run. The log may have been cleared. Re-seeding index." 
 $events_found = $true
 $events_found | Out-Null
 $n = $LogDepth 
 } 
  
Write-Host "Processing $($n) events."
 
#get the log entries 
$log_hits = Get-EventLog -ComputerName $_ -LogName $LogName -Newest $n | 
Where-Object {$ListOfEvents[$_.source + "#" + $_.eventid]} 
 
#save the current index to $logHistory for the next pass 
$logHistory[$_] = $index
 
#report number of alert events found and how long it took to do it 
if ($log_hits){ 
 $events_found = $true 
 $hits = $log_hits.count 
 $EmailBody += '<table id="SectionLabels"><tr><th class="data">'+ $_ + '</th></tr></table>'
 $EmailBody += '<table id="data"><tr><th>TimeGenerated</th><th>EntryType</th><th>Source</th><th>EventID</th><th>Message</th></tr>'

 $log_hits | ForEach-Object{
	$EmailBody += "<tr><td>$($_.TimeGenerated)</td><td>$($_.EntryType)</td><td>$($_.Source)</td><td>$($_.EventID)</td><td>$($_.Message)</td></tr>"
	 }
	 $EmailBody += "</table>"
 }
 else {$hits = 0}
$duration = ($timer.elapsed).totalseconds 
write-host "Found $($hits) alert events in $($duration) seconds." 
"-"*60 
" " 
if ($ShowEvents){$log_hits | Format-List | Out-String |Where-Object {$_}} 
} 
 
#save the history file to disk for next script run  
$logHistory | export-clixml $historyLog

#add CSS formatting to Message Body
if ($events_found -eq $true)
{
	$xEmailBody = "<html><head><title>$($MailSubject)</title><meta http-equiv=""Content-Type"" content=""text/html; charset=ISO-8859-1"" />"
	$xStyle = @(Get-Content $myCSSFile) | Out-String
	$xEmailBody += "</head><body>"
	$xEmailBody +=$xStyle
	$xEmailBody +=$EmailBody
	$xEmailBody += '<p><table id="SectionLabels">'
	$xEmailBody += '<tr><th>----END of REPORT----</th></tr></table></p>'
	$xEmailBody += '<p><font size="2" face="Tahoma"><br />'
	$xEmailBody += '<br />'
	$xEmailBody += 'SMTP Server: ' + $MailServer + '<br />'
	$xEmailBody += 'Recipients: ' + $MailTo.Split(";") + '<br />'
	$xEmailBody += 'Generated from Server: ' + (Get-Content env:computername) + '<br />'
	$xEmailBody += 'Script Path: ' + $PSScriptRoot + ' <br />'
	$xEmailBody += 'Computers Monitored: ' + $computers + ' <br />'
	$xEmailBody += '</p><p>'
	$xEmailBody += '<a href="https://www.lazyexchangeadmin.com/2018/09/PSEventMonitor.html">PSEventMonitor v.'+$scriptVersion+'</a></p>'
	$xEmailBody += "</body></html>"	
	$xEmailBody | Out-File ($PSScriptRoot + "\out.html")
}
 
#Send email if there were any monitored events found. 
if ($events_found -eq $true -and $SendEmail -eq $true){SendReport}
 
}
#END OF RUN PASS

Write-Host "`n$("*"*60)" 
Write-Host "Log monitor started at $(get-date)" 
Write-Host "$("*"*60)`n" 
 
#run the first pass
$start_pass = Get-Date 
&$run_pass 
 
#if $RunInterval is set, calculate how long to sleep before the next pass 
while ($RunInterval -gt 0){ 
if ($RunInterval -eq "C"){&$run_pass} 
 else{ 
 $last_run = (Get-Date) - $start_pass 
 $sleep_time = ([TimeSpan]::FromMinutes($RunInterval) - $last_run).totalseconds 
 Write-Host "`n$("*"*10) Sleeping for $($sleep_time) seconds `n" 
  
#sleep, and then start the next pass
 Start-Sleep -seconds $sleep_time 
 $start_pass = Get-Date  
 &$run_pass 
 }
 }