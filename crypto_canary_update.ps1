##############################################
# "Crypto Canary" Powershell update script
# Written 2016-20-05 by P. Gill 
# Last modified 2016-16-06
##############################################

#Define variables
$filePath =  "[REDACTED]/ransomware.dat"
$DATFile = "C:\Scripts\CryptoCanary\DAT\ransomware.dat"

# Import Ransomware DAT file
$wc = New-Object System.Net.Webclient 
$wc.DownloadFile($filePath, $DATFile)
$list = Import-Csv $DATFile

#Modify DAT file for each OS and convert to string or string array
$anyVar='*'
$08delimChar='|'
$12delimChar=','
$12doubleQuotes='"'

[string]$08DAT = get-content $DATFile | %{$_.split('"')[1]} | % {$anyVar+$_+$08delimChar} | Foreach {$_.Trim()}
[string[]]$12DAT = get-content $DATFile | %{$_.split('"')[1]} | % {$anyVar+$_} | Foreach {$_.Trim()}

#Drop the last character from each string
$08DAT = $08DAT -replace ".{1}$"

#Detect OS version
$serverInfo=Get-WmiObject -class Win32_OperatingSystem
$osVersion=$serverInfo.Version.Substring(0,3)

#Determine correct syntax for OS and update patterns
#Server 2012 R2
if ($osVersion -eq "6.3") {	

#Create FSRM File Group
$group = Get-FSRMFileGroup "Cryptoware"
$12DATlist = $group.IncludePattern + $12DAT | select -Unique 
Set-FsrmFileGroup -Name "Cryptoware" –IncludePattern $12DATlist

#Server 2008 R2
} elseif ($osVersion -eq "6.1") {

#Update FSRM File Group
Filescrn filegroup modify /filegroup:"Cryptoware" /members:"$08DAT"
}
