# -*- coding: cp1252 -*-
"""
Translate JSON dictionnaries created in urlparse_content.py into Stata-readable csv files
Output: private_content.csv
    
"""
import os

#******************************************************************************
    #Functions
#******************************************************************************
'''
    data = {
    'entry1': {'f': '1206603.onlineleasing.realpage.com', 't': [18048.0, 0.0, 0.0, 0.0, 18048.0, 0.0]},
    'entry2': {'f': 'example.com', 't': [12345.0, 45678.0, 789.0, 0.0, 0.0, 0.0]}
}
'''

#translate one JSON file into CSV   
def translate_dic(json_input,csv_output):
    import json
    import csv
    data_file=open(json_input)
    data=json.load(data_file)
    data_file.close()
    # Append to the CSV file and write the header
    with open(csv_output, 'a', newline='',encoding='utf-8') as csv_file:
        fieldnames = ['Entry Name', 'f', 't0', 't1','t2','t3','t4','t5']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        # Iterate through the dictionary and write each entry to the CSV file
        for entry_name, entry_data in data.items():
           row = {
                'Entry Name': entry_name,
                'f': entry_data['f']
            }
           if len(entry_data['t']) >= 5:        
                row['t0'] = entry_data['t'][0]
                row['t1'] = entry_data['t'][1]
                row['t2'] = entry_data['t'][2]
                row['t3'] = entry_data['t'][3]
                row['t4'] = entry_data['t'][4]
                row['t5'] = entry_data['t'][5]
           writer.writerow(row)

#******************************************************************************
    #Main program
    #Loop through each dictionnary and append to a CSV file
#******************************************************************************

#delete the file if it already exists
csv_output="private_content.csv"
if os.path.exists(csv_output):
  os.remove(csv_output)
  print("File deleted")
else:
  print("The file does not exist")

#input directory
directory=''
files = [f for f in os.listdir(directory)  if f.endswith('.json')]
it=10
i=1
for count,filename in enumerate(files):
    i+=1
    if int(i/it)==(i/it):print(f'file number={i}')
    ticker=os.path.join(directory,filename)
    translate_dic(ticker,csv_output)
print(f'Number of files processed={count+1}')


     


