##############################################
# "Crypto Canary" Powershell deployment script
# Written 2016-22-04 by P. Gill 
# Last modified 2016-16-06
##############################################

#Detect OS version
$serverInfo=Get-WmiObject -class Win32_OperatingSystem
$osVersion=$serverInfo.Version.Substring(0,3)
Write-host "OS Version =" $osVersion

#Define FQDN
$hostname=$env:computername + "." + $env:userdnsdomain

#Retrieve all server drives except for C drive.
$drives = gwmi win32_logicaldisk -filter "DriveType=3 AND VolumeName!='System'" | Select -ExpandProperty DeviceID

#Create Crypto Canary config directory
New-Item -ItemType directory -Path "C:\Scripts" -erroraction 'silentlycontinue'
New-Item -ItemType directory -Path "C:\Scripts\CryptoCanary" -erroraction 'silentlycontinue'
New-Item -ItemType directory -Path "C:\Scripts\CryptoCanary\config" -erroraction 'silentlycontinue'
New-Item -ItemType directory -Path "C:\Scripts\CryptoCanary\DAT" -erroraction 'silentlycontinue'

$configPath = "C:\Scripts\CryptoCanary\config\"

#Determine if FSRM is installed or not
if ($osVersion -eq "6.1"){Import-Module Servermanager}

if ($osVersion -eq "6.3") {
	  if (-not(Get-WindowsFeature FS-Resource-Manager | Where-Object {$_.Installed -match “True”}))
              {"Add-WindowsFeature –Name FS-Resource-Manager –IncludeManagementTools"}
	  else 
              {Write-host "FSRM 2012 R2 is already installed" -ForegroundColor Green}
	
 } elseif ($osVersion -eq "6.1") {
      if ("Get-WindowsFeature FS-Resource-Manager" | Where-Object {$_.Installed -eq “False”})
              {"Import-Module servermanager"; "Add-WindowsFeature File-Services"; "Add-WindowsFeature FS-Resource-Manager"}
      else 
		      {Write-host "FSRM 2008 R2 is already installed" -ForegroundColor Green}
    }

#Determine correct cmdlets
if ($osVersion -eq "6.3") {	

#Make reports folders
New-Item -ItemType directory -Path "C:\StorageReports\Incident" -erroraction 'silentlycontinue'
New-Item -ItemType directory -Path "C:\StorageReports\Scheduled" -erroraction 'silentlycontinue'
New-Item -ItemType directory -Path "C:\StorageReports\Interactive" -erroraction 'silentlycontinue'	

#Set FSRM Settings		
Set-FsrmSetting -SmtpServer [REDACTED] 
Set-FsrmSetting -AdminEmailAddress "[REDACTED];[REDACTED];[REDACTED]" 
Set-FsrmSetting -FromEmailAddress "FSRM@$hostname" 
Set-FsrmSetting -ReportLocationScheduled "C:\StorageReports\Scheduled"
Set-FsrmSetting -ReportLocationIncident "C:\StorageReports\Incident"
Set-FsrmSetting -ReportLocationOnDemand "C:\StorageReports\Interactive" 
Set-FsrmSetting -EmailNotificationLimit "60" 
Set-FsrmSetting -EventNotificationLimit "5" 
Set-FsrmSetting -CommandNotificationLimit "60" 
Set-FsrmSetting -ReportNotificationLimit "60" 

#Create FSRM File Group
New-FsrmFileGroup -Name "Cryptoware" –IncludePattern @("*RECOVER_INSTRUCTIONS*")

#Configure Email Notification 
$FscreenNotification = New-FsrmAction Email -MailTo "[Admin Email]" -Subject "System alert from the Crypto Canary on [Server]" -Body "The system detected that user [Source Io Owner] saved [Source File Path] on [File Screen Path] on server [Server]. This file matches the [Violated File Group] file group. These files can be harmful as they may contain malicious code or viruses. Please have this user's computer removed from the network as soon as possible, and ensure Security Operations has been contacted."

#Configure Event Log Notification
$EventNotification = New-FsrmAction Event -EventType Warning -Body "The system detected that user [Source Io Owner] saved [Source File Path] on [File Screen Path] on server [Server]. This file matches the [Violated File Group] file group. These files can be harmful as they may contain malicious code or viruses."

#Create File Screen Template & Set
New-FsrmFileScreenTemplate -Name "Crypto Canary" -Description "Crypto Canary" -IncludeGroup "Cryptoware" -Notification @($FscreenNotification, $EventNotification) -Confirm:$false -Active:$false
Set-FsrmFileScreenTemplate -Name "Crypto Canary" -Description "Crypto Canary" -IncludeGroup "Cryptoware" -Notification @($FscreenNotification, $EventNotification) -Confirm:$false -Active:$false

#Configure File Screens & Set
foreach ($drive in $drives){
Set-FsrmFileScreen -Path $drive -Description "Crypto Canary" -IncludeGroup "Cryptoware" -Notification @($FscreenNotification, $EventNotification) -Confirm:$false -Active:$false
    }

#Confirm script info
Write-host "2012 R2 commands ran" -ForegroundColor Green    
    
} elseif ($osVersion -eq "6.1") {

#Set FSRM Settings	
filescrn admin options "/smtp:[REDACTED]" "/from:FSRM@$hostname" "/adminemails:[REDACTED];[REDACTED];[REDACTED]" "/screenaudit:Enabled"  "/runlimitinterval:m,60" "/runlimitinterval:e,5" "/runlimitinterval:c,60" "/runlimitinterval:r,60"  

#Create FSRM File Group
Filescrn filegroup add /filegroup:"Cryptoware" /members:"*RECOVER_INSTRUCTIONS*"

#Configure Email Notification 
New-Item ${configPath}emailnotification.cfg -type file -force
Add-Content ${configPath}emailnotification.cfg "Notification=m"
Add-Content ${configPath}emailnotification.cfg "`nRunLimitInterval=60"
Add-Content ${configPath}emailnotification.cfg "`nTo=[Admin Email]"
Add-Content ${configPath}emailnotification.cfg "`nSubject=System alert from the Crypto Canary on [Server]"
Add-Content ${configPath}emailnotification.cfg "`nMessage=The system detected that user [Source Io Owner] saved [Source File Path] on [File Screen Path] on server [Server]. This file matches the [Violated File Group] file group. These files can be harmful as they may contain malicious code or viruses. Please have this user's computer removed from the network as soon as possible, and ensure Security Operations has been contacted."

#Configure Event Log Notification
New-Item ${configPath}eventnotification.cfg -type file -force
Add-Content ${configPath}eventnotification.cfg "Notification=e"
Add-Content ${configPath}eventnotification.cfg "`nRunLimitInterval=5"
Add-Content ${configPath}eventnotification.cfg "`nEventType=Error"
Add-Content ${configPath}eventnotification.cfg "`nMessage=The system detected that user [Source Io Owner] saved [Source File Path] on [File Screen Path] on server [Server]. This file matches the [Violated File Group] file group. These files can be harmful as they may contain malicious code or viruses."

#Configure File Screen Template
filescrn template modify /template:"Crypto Canary" /add-filegroup:"Cryptoware" "/type:passive" "/Add-Notification:m,${configPath}emailnotification.cfg" "/Add-Notification:e,${configPath}eventnotification.cfg"
filescrn template add /template:"Crypto Canary" /add-filegroup:"Cryptoware" "/type:passive" "/Add-Notification:m,${configPath}emailnotification.cfg" "/Add-Notification:e,${configPath}eventnotification.cfg"

#Configure File Screens
foreach ($drive in $drives){
    $string = $drive+"\"
    filescrn Screen Add /Path:$string /Type:Passive /Add-Filegroup:"Cryptoware" "/Add-Notification:m,${configPath}emailnotification.cfg" "/Add-Notification:e,${configPath}eventnotification.cfg"
    filescrn Screen Modify /Path:$string /sourcetemplate:"Crypto Canary" /Type:Passive
    }
    
#Confirm script info
Write-host "2008 R2 commands ran" -ForegroundColor Green

}
