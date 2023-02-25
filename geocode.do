// geocoding

cap confirm file "sources/geocode.dta"
if _rc == 0 {
    merge m:1 adres using "sources/geocode.dta", update replace keep(1 3 4 5)
    flsort, n(adres) d(date) extra(_merge)
    drop _merge    
}

url // obtain API key in local

quietly {
    count if geocode==0
    local newobs = `r(N)'
    noisily di "`newobs' uncoded observations"
    local count = 1
    while `newobs' > 0 {
        n di "Attempt `count'"
        n _dots 0, title(Geocoding) reps(`newobs')
        gen id = _n
        local address ""
        replace geocode = 0 if pc6==""
        gsort -geocode
        local counter = 0
        local countersuccess = 0
        forvalues k = 1/`=_N' {
            if geocode[`k'] == 0 {
                local address = subinstr("`=adres[`k']'", " ", "%20", .)
                insheetjson pc6 huisnr lat lon street /// 
                    using "http://api.positionstack.com/v1/forward?access_key=`API_key'&query=`address'&fields=results&limit=1", ///
                    table("data") columns("postal_code" "number" "latitude" "longitude" "street")	/// 
                    offset(`=`k'-1') limit(1)	//
                if pc6[`k'] != "" {
                    local ++counter
                    local ++countersuccess
                    noisily _dots `counter' 0
                }
                else {
                    local ++counter
                    noisily _dots `counter' 1
                }
            }
        }
        noisily di as result _newline "Geocoded `countersuccess' observations"
        gsort +id	// restore to previous sorting
        drop id	// remove id variable
        replace geocode = 1 if pc6 != ""	// indicate geocoded observations
        replace huisnr  = regexs(0) if regexm(huisnr,"^[0-9]+")	// keep only numbers of housenumber
        replace pc5     = regexs(0) if regexm(pc6,"^.....|....")	// extract 5 digit postcode
        replace pc4     = regexs(0) if regexm(pc6,"^....")	// extract 4 digit postcode
        
        count if geocode == 0
        local newobs = `r(N)'
        local ++count

        if `count' > 5 & `newobs' > 0 { // exit after 5 iterations
            noisily di as error "Uncoded observations remain after 5 attempts, error in code or data likely"
            exit
        }
    }
    
    gen pc4copy = pc4
    destring pc4copy, replace force
    replace pc6 = "null" if pc4copy < 2600 | pc4copy >3300
    replace pc5     = regexs(0) if regexm(pc6,"^.....|....")	// extract 5 digit postcode
    replace pc4     = regexs(0) if regexm(pc6,"^....")	// extract 4 digit postcode
    replace lat     = "" if pc4copy < 2600 | pc4copy >3300
    replace lon     = "" if pc4copy < 2600 | pc4copy >3300
    drop pc4copy
    
    // obtain neighbourhood, district, and municipality from seperate dataset
    n di "Obtaining neighbourhood, district, and municipality names - may take a while!"
    gen id = _n	// generate id variable for sorting
    merge m:1 pc6 huisnr using "sources/pc6hnr_buurten.dta", update keep(1 3 4 5) nogen	// obtain neighbourhood district and municipality name
    gsort +id	// restore to previous sorting
    drop id	// remove id variable
    replace wk_naam = regexs(2) if regexm(wk_naam,"^(Wijk [0-9][0-9] )(.+)")	// keep only name of district
    noisily di "Added neighbourhood, district, and municipality names"
    
}


save "working/complete/verantwoording.dta", replace
keep adres geocode-wk_naam
drop freq waittime
duplicates drop adres, force
sort adres
drop if gm_naam==""
label data "previously geocoded addresses"
save "sources/geocode.dta", replace
use "working/complete/verantwoording.dta", clear