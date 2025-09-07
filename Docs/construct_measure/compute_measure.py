# -*- coding: utf-8 -*-
"""
This script computes the main measure (Website size) on a set of JSON files
Outputs: 
    measure_private_firms_cs2019.csv (treated group)
    small_X.csc and large_X.csv (control group with X={1..10}), the sample of 2.8M firms
"""

def wayback(ticker:str,period:str):
    '''Compute the wayback measures using panda
    Argument:
    ticker -- full path to the JSON file that is to be parsed
    period -- "quarter" or "year"
    Example:
    a=wayback('cdx_28.html')
    '''
    #import modules 
    import pandas as pd
    import numpy as np
    
    #convert JSON into a dataframe and use the first row as the header
    df=pd.read_json(ticker)
    df.columns=df.iloc[0]
    df=df[1:]
    
    #get the number of lines in the JSON file
    df['nlines']=len(df.index)
    
    #The first URL is the main domain
    df['website']=df['urlkey'].iloc[0]
    
    #remove error code (3&4)
    df['code']=df['statuscode'].astype(str).str[0]
    df=df[(df['code']!="3")]
    df=df[(df['code']!="4")]
    df.drop('code',inplace=True,axis=1)
    df.drop('statuscode',inplace=True,axis=1)
    
    #define quarter and year
    df.timestamp=pd.to_datetime(df.timestamp,format="%Y%m%d%H%M%S")
    df["quarter"]=pd.PeriodIndex(df.timestamp,freq='Q')
    df["year"]=pd.PeriodIndex(df.timestamp,freq='Y')
    df.drop('timestamp',inplace=True,axis=1)
        
    #change type of length and define HTML content only    
    df['length']=df['length'].astype(float)
    df['html']=np.where(df['mimetype']=="text/html",df['length'],0)
    
    #compute the average length per URL-period
    grouped = df.groupby(["website","nlines","urlkey", period],as_index=False,sort=False)
    df_mean = grouped[['length','html']].mean()
        
    #compute the measure as the sum of each URL average length over one period
    grouped=df_mean.groupby(["website","nlines",period],as_index=False,sort=False)
    df_q=grouped[["length","html"]].sum()
    #parse the file
    df_q['file']=ticker
    #the function returns a dataframe
    return df_q

def call_wayback(directory:str,outfile_csv:str,process_csv:str,threshold=2000000000,iter=300):
    '''Iterate inside a folder, call the wayback function on each file, and append a csv file
    Arguments:
    directory -- where the JSON files are located 
    outfile_csv -- CSV file to contain the  measure 
    process_csv --  CSV file indicating which files were successfully parsed
    threshold -- size threshold for skipping a file (default 20000000)
    iter -- print execution time every x iterations (default 300)
    Note: it is a good idea to set up different instances with different size thresholds
    '''
    #Import modules
    import os
    import time
    import pandas as pd

    #delete the output file to avoid appending with an old file
    if os.path.exists(outfile_csv):
      os.remove(outfile_csv)
      
    #create an empty directionary to store results of the process for each file
    filelist={"file":[],"size":[],"success":[],"skip":[]}
    
    #initialize the counter and time
    i=0
    start=time.time()
    
    #loop through each file
    for filename in os.listdir(directory):
        #print steps and time every x iterations
        i+=1
        if int(i/iter)==(i/iter):print("file number %d,time=%d"%(i,time.time()-start))
        #get file path and size
        ticker=os.path.join(directory,filename)
        size=os.stat(ticker).st_size
        #record file path and size in the dictionary
        filelist['file'].append(ticker)
        filelist['size'].append(size)
        #if the size is lower than the threshold execute the code and set skip to zero
        if size<threshold:
            filelist['skip'].append(0)
            #try to read the JSON
            try:
                a=wayback(ticker,'quarter')
            #if it fails, set success to zero and go to the next iteration
            except:
                filelist['success'].append(0)
                continue
            #if this was a success, append the csv file and set success to one
            else:
                a.to_csv(outfile_csv,mode='a',header=False)
                filelist['success'].append(1)
        #if the size is too high, just skip the file, set skip to 1 and success to zero
        else:
            filelist['skip'].append(1)
            filelist['success'].append(0)
            continue
    #print total time
    print(time.time()-start)
    
    #Write the success/skip dictionary into a csv file   
    pd.DataFrame(filelist).to_csv(process_csv)

 
##############################################################################
#Calling the main program
##############################################################################

import os

#Folder of input files
root_download=""
#Folder where to store the results
root_output=""

#output files (the measure itself + a file which gives the outcome of the process for each file)    
out=os.path.join(root_output,"measure_private_firms_cs2019.csv")
pr=os.path.join(root_output,"process_measure_private_cs2019.csv")
call_wayback(root_download,out,pr,threshold=80000000,iter=50)




