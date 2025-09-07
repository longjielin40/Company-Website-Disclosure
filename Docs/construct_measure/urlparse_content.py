#coding: utf-8
"""
Parse JSON files on a given year and return the size dedicated to each topic.  
Execute in command line to allow for parallelization.
Output: content_private_dataX.json with X={1..44}

"""
#import modules
import os
import re
import time
import json
from urllib.parse import urlparse
import sys

#******************************************************************************
    #Functions
#******************************************************************************

# Use dictionaries created with public firms
def load_words(file):
    '''
    Function to load dictionaries
    '''
    with open(file) as text_file:
        list_words=set(text_file.read().split())
    return list_words

#load all 4 dictionaries
path_dic='data/dic_topics'
ir=load_words(os.path.join(path_dic,'ir.txt'))
pmc=load_words(os.path.join(path_dic,'pmc.txt'))
geo=load_words(os.path.join(path_dic,'geo.txt'))
hr=load_words(os.path.join(path_dic,'hr.txt'))
    
def parse_content(url):
    #initialize content
    content=[1,0,0,0,0]
    #extract each word in the URL and check it belongs to one of the dictionaries
    list_path=urlparse(url).path.rsplit('/',-1)
    for i in list_path:
        list_kw=re.split(r'\W+|_',i)
        for j in list_kw:
            if j.lower() in ir:content[1]=1
            if j.lower() in pmc:content[2]=1        
            if j.lower() in hr:content[3]=1               
            if j.lower() in geo:content[4]=1
    return content

def parse_website(file,year):
    i=0
    #initialize list of HTML urls.
    list_topics=[]
    #open JSON file
    with open(file) as data_file:
        data=json.load(data_file)
        #go through each line
        for element in data:
            #execute only if HTML content on a given year 
            if (element[3]=="text/html" and element[1][0:4]==year):    
                i+=1
                #check whether one of the keywords belong to the topic
                topics=parse_content(element[2])
                #multiply the vector by the size of the URL
                result_list = [x * float(element[6]) for x in topics]
                #append it
                list_topics.append(result_list)          
            else:
                   continue
    topics= [sum(x) for x in zip(*list_topics)]       
    return topics


def  loop_website(directory,year,start_obs,end_obs,iter):
    dict_website={}
    start=time.time()
    i=0
    for filename in sorted(os.listdir(directory)):
         #print steps and time every x iterations
             i+=1
             if int(i/iter)==(i/iter):print("file number %d,time=%d"%(i,time.time()-start))
             #if files are in the range, execute the program
             if (i>=float(start_obs) and i<float(end_obs)):
                try:
                     z=parse_website(os.path.join(directory,filename),year)
                     #try to extract the website name
                     try:
                         found = re.search(r'url=(.+?)\&show', filename).group(1) 
                     #otherwise, just keep the filename
                     except AttributeError:
                         found = filename
                     #append the dictionary
                     dict_website[i]={'f':found,'t':z}
                except:
                        continue
            #if not in file range, stop execution
             else:
                 continue
    return dict_website
         

#******************************************************************************
    #Main program
#******************************************************************************    
'''
start=int(sys.argv[1])
end=int(sys.argv[2])
filename=str(sys.argv[3])
'''

#directory where the JSON files are located
directory=''
year='2019'
iter=100
start=1
end=5000
filename='2019'

#run the program
dict_content=loop_website(directory,year,start,end,iter)
#write the resulting dictionnary in a JSON file
file='content_private_'+filename+'.json'
json_output=os.path.join('',file)
with open(json_output, 'w') as filehandle:
    json.dump(dict_content, filehandle)

