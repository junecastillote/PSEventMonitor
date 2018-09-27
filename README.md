# PSEventMonitor
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