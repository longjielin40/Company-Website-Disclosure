/******************************************************************************
Object: Compute Website Size and Website Component
*****************************************************************************/
set more off
global dropbox ""
*link to CSV files (from json_to_csv.py)
cd ""
*output folder
global temp=""

*-------------------------------
* Programs 
*-------------------------------

*Format date
capture program drop datewb
program def datewb
	format timestamp %16.0g
	capture tostring timestamp,replace usedisplayformat  
	gen date=date(substr(timestamp,1,4)+substr(timestamp,5,2)+substr(timestamp,7,2),"YMD")
	format date %td
end
*Format statuscode
capture program drop statuscode
program def statuscode
	format statuscode %9s
	tostring statuscode,replace usedisplayformat
	gen code=substr(statuscode,1,1)
end

*Main program
capture program drop wayback
program define wayback
	insheet using "`1'",clear
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

	*-------------------------
	* Build quarterly statistics
	*---------------------------
	*Nb of captures per quarter
	bys q:gen captures_q=_N
	*Number of distinct URLs per quarter
	bys q:egen url_q=nvals(urlkey)
	*compute the average size of each URL per quarter
	bys urlkey q:egen size_url_q=mean(length)
	*Keep one url per quarter
	bys q urlkey:keep if _n==1
	*compute the number of new URLs per quarter
	sort urlkey
	by urlkey:gen a=(_n==1)
	bys q:egen newurl_q=sum(a)
	drop a
	*compute the absolute size of the website as the sum of each URL average length
	bys q:egen size_website_q=sum(size_url_q)

	*------------------------------
	*Analyze website's meta-content
	*-----------------------------

	*A /  Identify meta content
	*identify video
	g mim_video=regexm(mimetype,"video/")
	*identify audio
	g mim_audio=regexm(mimetype,"audio/")
	*identify image
	g mim_image=regexm(mimetype,"image/")
	*identify text
	g mim_text=regexm(mimetype,"text/")
	*identify application
	g mim_application=regexm(mimetype,"application/")
	*unclassified meta data
	g mim_other=(mim_video==0 & mim_audio==0 & mim_image==0 & mim_text==0 & mim_application==0)


	*B/ identify applications (see here for mimetype:https://filext.com/faq/office_mime_types.php)
	* identify PDF 
	g mim_pdf=(regexm(mimetype,"pdf") & mim_application==1)
	*identify WORD
	g mim_word=(regexm(mimetype,"word") & mim_application==1)
	*identify ZIP
	g mim_zip=(regexm(mimetype,"zip") & mim_application==1)
	*identify FLASH
	g mim_flash=(regexm(mimetype,"flash") & mim_application==1)
	*identify JAVASCRIPT
	g mim_java=(regexm(mimetype,"java") & mim_application==1)
	*identify EXCEL
	g ex1=(regexm(mimetype,"excel") & mim_application==1)
	g ex2=(regexm(mimetype,"spreadsheet") & mim_application==1)
	gen t=ex1+ex2
	gen mim_excel=(t>=1)
	drop ex1 ex2 t
	*identify POWERPOINT
	g pwp1=(regexm(mimetype,"powerpoint") & mim_application==1)
	g pwp2=(regexm(mimetype,"presentationml") & mim_application==1)
	gen t=pwp1+pwp2
	gen mim_powerpoint=(t>=1)
	drop pwp1 pwp2 t
	*unclassified applications
	g mim_other_application=(mim_application==1 & mim_pdf==0 & mim_word==0 & mim_zip==0 & mim_flash==0 & mim_java==0 & mim_excel==0 & mim_powerpoint==0)

	
	*C/ compute quarterly size per elements

	quie desc mim_*,varlist
	foreach var of varlist `r(varlist)'{
		gen t=`var'*size_url_q if `var'==1
		bys q:egen count_`var'_q=sum(`var')
		bys q:egen size_`var'_q=sum(t)
		drop t
	}


	*------------------------------------------
	*IV/ Tag certain keywords here
	*------------------------------------------
	*Investor relation
	gen kw_investor=(regexm(original,"investor")) 
	gen kw_analyst=(regexm(original,"analyst")) 
	gen kw_filing=(regexm(original,"filings")) 
	gen kw_report=(regexm(original,"report")) 
	gen kw_sp=(regexm(original,"stock")) 
	gen kw_client=(regexm(original,"client")) 
	gen kw_subscription=(regexm(original,"client")) 
	gen kw_placement=(regexm(original,"client")) 
	gen kw_acquisition=(regexm(original,"client")) 
	gen kw_meeting=(regexm(original,"meeting")) 
	*social networks
	gen kw_twitter=(regexm(original,"twitter")) 
	gen kw_facebook=(regexm(original,"facebook")) 
	gen kw_rss=(regexm(original,"rss")) 
	*product market
	gen kw_product=(regexm(original,"product")) 
	*CSR/ESG
	gen kw_csr=(regexm(original,"csr")) 
	*C/ compute quarterly size per elements

	quie desc kw_*,varlist
	foreach var of varlist `r(varlist)'{
		bys q:egen count_`var'_q=sum(`var')
	}
	
	*--------------------------------------------------
	*IV/ Make quarterly statistics and save the file
	*-------------------------------------------------
	bys q:keep if _n==1
	drop urlkey original mimetype digest length dupecount y size_url_q  kw_* mim_*
	capture confirm file "$temp/wb.dta" 
	if _rc == 0 {
		append using "$temp/wb.dta",force
		save "$temp/wb.dta",replace
	}
	else { 
		save "$temp/wb.dta"
	} 
end

*-------------------------------
* Call the program
*-------------------------------
/*Test the program on one single file
wayback "cdx[610].csv" 
*/
*erase the output file before the first iteration
capture erase "$temp/wb.dta"

*Loop through each CSV file in the folder
local filelist:dir . files "*.csv"
foreach file of local filelist {
	dis "`file'"
	capture noisily wayback "`file'"
}





