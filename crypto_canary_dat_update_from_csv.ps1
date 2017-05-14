#Get date
$date = get-date -format yyyyddMM

#Download CSV
$filePath =  "https://docs.google.com/spreadsheets/d/1TWS238xacAto-fLKh1n5uTsdijWdCEsGIM0Y0Hvmc5g/pub?output=csv"
$localPath = "C:\temp\ransomware.csv"
Remove-Item C:\temp\ransomware.csv
$wc = New-Object System.Net.Webclient 
$wc.DownloadFile($filePath, $localPath)
$ransomwareList = Import-Csv $localPath -Delimiter "," | % {$_.Extensions}
$datFile = "C:\temp\Ransomware.dat$date"
$rawExtensionsList = @()

#Write-host $ransomwareList 

foreach($extension in $ransomwareList){

    $rawExtensionsList += $extension -split '[\n]'
    }

#Remove blank entries. 
$extensions = $rawExtensionsList.Split("",[System.StringSplitOptions]::RemoveEmptyEntries)

Write-host $extensions

#Export extensions to CSV file
$extensions | Out-File $datFile