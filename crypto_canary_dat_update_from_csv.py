###############################################
# "Crypto Canary" Python DAT file update script
# Written 2016-31-05 by P. Gill
# Updated 2016-07-06
###############################################

# Get date
import datetime
date = datetime.date.today()
date = date.strftime('%Y%m%d')

# Download CSV from the web
import csv
import urllib
from collections import defaultdict
urlFilePath = 'https://docs.google.com/spreadsheets/d/1TWS238xacAto-fLKh1n5uTsdijWdCEsGIM0Y0Hvmc5g/pub?output=csv'
localFile = urllib.URLopener()
localFile.retrieve(urlFilePath, 'ransomware.csv')

# Read in column data to a dictionary list
columns = defaultdict(list)
with open ('ransomware.csv') as f:
    reader = csv.DictReader(f,delimiter=',' ) # read rows into a dictionary format
    for row in reader: # read a row as {column1: value1, column2: value2,...}
        for (k,v) in row.items(): # go over each column name and value 
            columns[k].append(v) # append the value into the appropriate list
                                 # based on column name k

# Convert column 'Extensions' to a string
extensionColumn = columns['Extensions']
ransomwareList = '\n'.join(set((extensionColumn)))

# Remove duplicates
extensionList = ''.join(set([ransomwareList]))

# Remove entries from string
extensionList = extensionList.replace('.mp3','\n')
extensionList = extensionList.replace('4 random characters, e.g., .PzZs, .MKJL','\n')
extensionList = extensionList.replace('.EXE','\n')
extensionList = extensionList.replace('.html','\n')

# Breakup lines
extensionList = extensionList.replace(',','\n')

# Remove blank lines
extensions = '\n'.join([s.strip() for s in extensionList.splitlines(True) if s != '\n'])

# Output to a file
datFile = 'Ransomware.dat{0}' .format(date)
f = open(datFile, 'w')
f.write(extensions)
f.close()
