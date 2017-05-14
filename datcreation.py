###############################################
# "Crypto Canary" Python DAT file update script
# Written 2016-31-05 by P. Gill
# Updated 2017-01-05
###############################################

import boto3
import os
import sys
import csv
import urllib

def crypto_dat_file_creation(json_input, context):
    # Download CSV from the web and save it to S3
    s3 = boto3.resource('s3')
    bucket = s3.Bucket('[REDACTED]')
    urlFilePath = 'https://docs.google.com/spreadsheets/d/1TWS238xacAto-fLKh1n5uTsdijWdCEsGIM0Y0Hvmc5g/pub?output=csv'
    try:
        localFile = urllib.URLopener()
    except: 
        print("Unable to download CSV file")
    try:
        localFile.retrieve(urlFilePath, '/tmp/ransomware.csv')
    except:
        print("Unable to save CSV file locally")
    try:
        csvDownload = bucket.upload_file('/tmp/ransomware.csv','ransomware.csv')
    except:
        print("Unable to upload CSV file to S3")

    # Read in column data to a dictionary list
    from collections import defaultdict
    columns = defaultdict(list)
    with open ('/tmp/ransomware.csv') as f:
        reader = csv.DictReader(f,delimiter=',' ) # read rows into a dictionary format
        for row in reader: # read a row as {column1: value1, column2: value2,...}
            for (k,v) in row.items(): # go over each column name and value 
                columns[k].append(v)# append the value into the appropriate list
                                    # based on column name k


    # Convert column 'Extensions' to a string
    extensionColumn = columns['Extensions']
    ransomwareList = '\n'.join(set((extensionColumn)))

    # Remove duplicates
    extensionList = ''.join(set([ransomwareList]))

    # Remove entries from string
    extensionList = extensionList.replace('4 random characters, e.g., .PzZs, .MKJL','\n')
    
    # Remove common Windows file extension entries from string
    extensionList = extensionList.replace('.mp3','\n')
    extensionList = extensionList.replace('.EXE','\n')
    extensionList = extensionList.replace('.html','\n')
    extensionList = extensionList.replace('.css','\n')
    extensionList = extensionList.replace('.exe','\n')
    extensionList = extensionList.replace('.dll','\n')
    extensionList = extensionList.replace('.url','\n')
    extensionList = extensionList.replace('.PNG','\n')
    extensionList = extensionList.replace('.bin','\n')

    # Breakup lines
    extensionList = extensionList.replace(',','\n')

    # Remove blank lines and add quotes
    extensions = '"\n"'.join([s.strip() for s in extensionList.splitlines(True) if s != '\n'])
    extensions = '"' + extensions + '"'
