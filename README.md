# Powershell-Crypto-Canary
Crypto Canary built with AWS Lambda (Python), S3 Bucket, Powershell, &amp; Puppet (Ruby)

1.0	Purpose
The purpose of this document is to explain how the Server Engineering “Crypto Canary” works. The Crypto Canary was designed and implemented as a way to provide an early warning system that files on a file share may be getting encrypted by ransomware. 

2.0	Scope
This document applies to Windows Server 2008 R2 and Windows Server 2012 R2 machines that have File Server Resource Manager installed on them. 

3.0	Definitions/Acronyms 
Crypto Canary – File Server Resource Manager Passive file screen configured on Windows file servers to detect certain file types
FSRM – File Server Resource Manager
AWS – Amazon Web Services
S3 – Amazon Simple Storage Service
Lambda - AWS Lambda provides the ability to run code without provisioning or managing servers
DAT file – The term used to describe a list of extensions created by the Crypto Canary
Ransomware - A type of malicious software designed to block access to a computer system until a sum of money is paid

4.0	Procedures
The Crypto Canary consists of 4 separate pieces of code that allows it to function automatously: 1) Canary install, 2) Canary update, 3) DAT update, and 4) Puppet module. A flow chart of the process is provided (Image A). 

4.1	Canary install
The Canary install is provided by a PowerShell script (Appendix A). This PowerShell script checks to see what version of Windows Server the script is running on, 2008 R2 or 2012 R2. Once it determines the version, the script checks to see if FSRM is installed on the server. If it is not installed, then the script will install FSRM, and then proceed to configure it. If it is installed, the script will proceed to configuring FSRM to function as the Canary. 

These configurations include setting email settings, alerting schedule, the name of the FSRM File Group, the name of the FSRM File Screen, and enabling the file screen on the various drives on the server. 

4.2	Canary update
The Canary update is a PowerShell script (Appendix B) that downloads the DAT file from the S3 bucket, saves it to the local server, and as a scheduled task, once a day updates the FSRM File Group patterns to include any new extensions that have been added to the DAT file. The script determines if the server is 2008 R2 or 2012 R2, and executes the PowerShell script accordingly. 

4.3	DAT update
The Canary DAT update (Appendix C) is a Python script handled by an AWS Lambda function. This function downloads a 3rd party provided CSV file that contains all known extensions of ransomware, strips out the extensions column from the CSV file, parses it into a list format, and removes out specified items from the list. It then copies the completed list to an S3 bucket where it can be later downloaded by the servers.

The CSV file is created from this 3rd party provided Google Sheet. It is available here: https://docs.google.com/spreadsheets/d/1TWS238xacAto-fLKh1n5uTsdijWdCEsGIM0Y0Hvmc5g/pubhtml

The completed DAT file created by the AWS Lambda function can be accessed here: [READCTED]/ransomware.dat

The Lambda function has a trigger called “Crypto_Canary_daily_update” that causes it to run every 24 hours: 

CloudWatch Events - Schedule: Crypto_Canary_daily_update
arn:aws:[READCTED]:rule/Crypto_Canary_daily_update
Schedule expression: rate(24 hours)Description: Rule to schedule Crypto Canary to update every 24 hours.

4.4	Puppet Module
The Crypto Canary is designed to be installed on all Windows servers that are named “[REDACTED]”. This is accomplished by the use of a Puppet module (Appendix D). 

The first part of the Puppet module is the node group. The node group is setup to match the regex of “(?:windows)” for the server osfamily. The next regex is set to match “[REDACTED]” for the server hostname. This ensures that it only applies to Windows servers named “[REDACTED]” or “[REDACTED]”. 

The second piece of the Puppet module is the manifests located at “/[REDACTED]/manifests” on “[REDACTED]”. There are two manifest files, “init.pp” and “install_crypto_canary.pp”. 

“Init.pp” calls “install_crypto_canary.pp”. “Install_crypto_canary.pp” checks to see if the file “ransomware.dat” exists on the file server under “c:\Scripts\CryptoCanary\DAT\”. If the file does not exist, it runs the Crypto Canary install and update PowerShell scripts (4.1, 4.2). The Puppet module will always ensure that a scheduled task is created on the servers to run the Crypto Canary update script, and that the PowerShell scripts exist on the server. 
