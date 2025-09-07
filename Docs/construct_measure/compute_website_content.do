/******************************************************************************
Object: Compute Website Content
*****************************************************************************/
set more off
global dropbox ""
*link to CSV files (from json_to_csv.py)
cd ""
*classification of words
global classification="keywords_classification.xlsx"
*output folder
global temp=""

*-------------------------------
* Utility programs 
*-------------------------------
*format date
capture program drop datewb
program def datewb
	format timestamp %16.0g
	capture tostring timestamp,replace usedisplayformat  
	gen date=date(substr(timestamp,1,4)+substr(timestamp,5,2)+substr(timestamp,7,2),"YMD")
	format date %td
end
*format statuscode
capture program drop statuscode
program def statuscode
	format statuscode %9s
	tostring statuscode,replace usedisplayformat
	gen code=substr(statuscode,1,1)
end

*-------------------------------
* Compute website content
*-------------------------------
*read sheets from the Excel dictionnary file and copy them in a stata dataset (one sheet=one topic)
clear
tempfile kw
gen keywords=.
gen freq=.
gen topics1=.
gen topics2=.
save `kw'
foreach topic in "FIN" "PMC" "GEO" "COM" "HR" {
	import excel using $classification,sheet(`topic') clear firstrow
	append using `kw',force
	save `kw',replace
	}
*store each set of keywords in a local macro
foreach topic in "fin" "pmc" "geo" "com" "hr" {
	quie levelsof keywords if topics1=="`topic'",local(kw_`topic')
}
*erase the output file before the first iteration
capture erase "$temp/wb_keywords.dta"
*Loop over each file and compute the size for each topic of interest
local filelist:dir . files "*.csv"
foreach file of local filelist{
	dis "`file'"
	capture{
	insheet using "`file'",clear
	*-------------------------
	* get website name
	*---------------------------
	gen t=urlkey[1]
	gen str website= regexs(2)+"."+regexs(1)  if regexm(t, "(.*),(.*)\)")
	drop t
	*-------------------------
	* Processing date and errors
	*---------------------------
	*Date
	datewb
	gen q=qofd(date)
	format q %tq
	gen y=year(date)
	drop timestamp
	*Remove errors
	statuscode
	drop if code=="3"|code=="4"
	drop code statuscode
	*Define length
	capture destring length,replace
	*Keep one url per quarter
	bys q urlkey:keep if _n==1
	drop urlkey
	*loop through topics and keywords
	foreach topic in "fin" "pmc" "geo" "com" "hr"{	
		gen t1=0
		foreach word of local kw_`topic'{
			qui replace t1=regexm(original,"`word'")+t1
		}
		gen `topic'=(t1>0)*length
		drop t1
		bys q:egen `topic'_count=sum(`topic')
		drop `topic'
	}
	bys q:keep if _n==1
	drop original mimetype digest length dupecount date
	gen filename="`file'"
	*save (for the first iteration) or append to the existing dataset
	capture confirm file "$temp/wb_keywords.dta"
	if _rc==0{
		append using "$temp/wb_keywords.dta",force
		save "$temp/wb_keywords.dta",replace
	}
	else{
		save "$temp/wb_keywords.dta",replace
	}
	}
}

*---------------------------------------------------------------------------
* Compute total website size as the total size of URLs that we can classify
*---------------------------------------------------------------------------
use "$temp/wb_keywords.dta",clear
rename *_count *
gen total=pmc+fin+geo+hr
keep website q y fin pmc hr geo total
gen pmc_prop=pmc/total
gen fin_prop=fin/total
gen geo_prop=geo/total
gen hr_prop=hr/total
save "$temp/wb_keywords.dta",replace

