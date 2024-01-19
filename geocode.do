use "working/complete/verantwoording.dta", clear

duplicates drop adres, force

cap confirm file "sources/geocode.dta"
if _rc == 0 {
    merge m:1 adres using "sources/geocode.dta", update replace nogen keep(1 3 4 5)
}

drop date inschrijfdatum-regyear freq waittime

url // obtain API key
qui {
	count if geocode == 0
	local newobs = `r(N)'
	n di as result `newobs' as text " uncoded addresses"
	local count = 1
	while `newobs' > 0 {
		n di as text _newline "Attempt " as result "`count'"
		n _dots 0, title(Geocoding) reps(`newobs')
		local address ""
		replace geocode = 0 if pc6 == ""
		gsort -geocode
		local counter = 0
		local countersuccess = 0
		forvalues k = 1/`=_N' {
			if geocode[`k'] == 0 {
				
				local address = subinstr("`=adres[`k']'", " ", "%20", .)
				insheetjson pc6 huisnr lat lon street /// 
					using "http://api.positionstack.com/v1/forward?access_key=`API_key'&query=`address'&fields=results&limit=1", ///
					table("data") columns("postal_code" "number" "latitude" "longitude" "street")	/// 
					offset(`=`k'-1') limit(1) replace
				
				local ++counter
				if pc6[`k']!= "" & pc6[`k']!= "null"{
					local ++countersuccess
					n _dots `counter' 0
				}
				else {
					n _dots `counter' 1
				}		
			}
		}
		
		n di as text _newline "Geocoded " as result `countersuccess' as text " addresses"
		
		
		replace huisnr  = regexs(0) if regexm(huisnr,"^[0-9]+")	// keep only numbers of housenumber
		
		tempvar pc4copy		
		gen `pc4copy'	= regexs(0) if regexm(pc6, "^....")
		destring `pc4copy', replace force
		count if `pc4copy' < 2600 | `pc4copy' > 3300 & `pc4copy' != .
		n di as text "Out of which " as error r(N) as text " coded incorrectly by API"
		
		replace pc6		= "null" if `pc4copy' < 2600 | `pc4copy' > 3300
		replace pc5     = regexs(0) if regexm(pc6,"^.....|....")	// extract 5 digit postcode
        replace pc4		= regexs(0) if regexm(pc6,"^....")	// extract 4 digit postcode
		replace lat		= "" if pc6 == "null"
		replace lon		= "" if pc6 == "null"
		
		replace geocode = 1 if pc6 != ""
		count if geocode == 0
		local newobs = `r(N)'
		local ++count
		
		
		if `count' > 5 & `newobs' > 0 {
			n di as error "Uncoded addresses remain after 5 attempts, error in data or code likely"
			exit
		}
	}
	
	 merge m:1 pc6 huisnr using "sources/pc6hnr_buurten.dta", ///
		update keep(1 3 4 5) nogen	// obtain neighbourhood district and municipality name
	replace wk_naam = regexs(2) if regexm(wk_naam, "^(Wijk [0-9][0-9])(.+)")
	n di as text "Added neighbourhood, district, and municipality names"
}

sort adres
label data "previously geocoded addresses"
save "sources/geocode.dta", replace

use "working/complete/verantwoording.dta", clear
qui {
	merge m:1 adres using "sources/geocode.dta", update replace keep(1 3 4 5)
	flsort, n(adres) d(date) extra(_merge)
	drop _merge
}
