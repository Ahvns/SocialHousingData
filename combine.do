// preparing for merge

local x: dir working files "*"
qui foreach dset of local x {
    use "working/`dset'", clear
    cap gen date = mdy(month,day,year)
    format date %tdDD_Month_CCYY
    cap drop month
    cap drop day
    cap drop year
    cap drop regmonth
    cap drop waittime
    cap gen geocode = 0
    cap gen str6 pc6 = ""
    cap gen str5 pc5 = ""
    cap gen str4 pc4 = ""
    cap gen str16 lat = ""
    cap gen str16 lon = ""
    cap gen str64 street = ""
    cap gen str10 huisnr = ""
    lab var geocode "Indicator if observation has been geocoded"
    lab var pc6 "6 digit postcode"
    lab var pc5 "5 digit postcode"
    lab var pc4 "4 digit postcode"
    lab var lat "latitude"
    lab var lon "longitude"
    lab var street "street of address"
    lab var huisnr "house number of address"
    
    rename *, lower
    
    datefix, error(drop) date(date) name(adres)
    order date
    
    capture confirm variable freq
    if _rc == 111 {
        qui duplicates tag date adres volgorde aantal_reacties positie regdate, generate(freq)
        qui replace freq = freq + 1
        qui duplicates drop date adres volgorde aantal_reacties positie regdate, force
        lab var freq "Frequency weight"
    }
    
    flsort, d(date) n(adres)
    
    save "working/`dset'", replace
}



// merging

// get list of files in working directory
local x: dir working files "*"
qui foreach i of local x {
    use "working/`i'", clear
    local current `i'
    continue, break
}
local x: list x - current

// merge datasets
foreach i of local x {
    
    // display dataset currently being added
    di as text ""
    di as txt "Currently adding " as result "`i'"
    local iteration = 1
    di as text "Iteration " as result `iteration'
    
    // merge dataset
    qui merge 1:1 date adres volgorde aantal_reacties positie regdate using "working/`i'"
    
    // count overlap
    qui count if _merge==3
    local overlap = `=r(N)'
    di as text "Overlap: " as result `overlap'
    
    // sort observations
    flsort, n(adres) d(date) extra(_merge)

    // decrease date if overlap is too small
    qui while `overlap'< 1200 {
        
        // drop observations from added dataset
        drop if _merge==2
        drop _merge
        
        // decrease date of observations, skipping weekends
        forvalues it = 1/`iteration' {
            gen weekday = dow(date)
            replace date = date - 1 if inlist(weekday,2,3,4,5)
            replace date = date - 3 if weekday == 1
            drop weekday
        }
        
        // merge and sort
        merge 1:1 date adres volgorde aantal_reacties positie regdate using "working/`i'"
        flsort, n(adres) d(date) extra(_merge)
        
        // count new overlap
        qui count if _merge==3
        local overlap = `=r(N)'
        
        // return dates to previous value
        forvalues it = 1/`=`iteration'' {
            gen weekday = dow(date)
            replace date = date + 1 if inlist(weekday,1,2,3,4)
            replace date = date + 3 if weekday == 5
            drop weekday    
        }
        
        // increment iteration
        local ++iteration
        
        // display results
        n di as text "Iteration " as result `iteration'
        n di as text "Overlap: " as result `overlap'
        
        // stop decreasing date if attempted three times
        if `iteration' > 3 {
            continue, break
        }
    }
    
    // increase dates if overlap is too small
    qui while `overlap'< 1200 {
        
        // drop observations from added dataset
        drop if _merge==2
        drop _merge
        
        // increase dates, skipping weekends
        forvalues it = 1/`=`iteration'-3' {
            gen weekday = dow(date)
            replace date = date + 1 if inlist(weekday,1,2,3,4)
            replace date = date + 3 if weekday == 5
            drop weekday    
        }
        
        // merge and sort
        merge 1:1 date adres volgorde aantal_reacties positie regdate using "working/`i'"
        flsort, n(adres) d(date) extra(_merge)
        
        // count new overlap
        qui count if _merge==3
        local overlap = `=r(N)'
        
        // return dates to previous value
        forvalues it = 1/`=`iteration'-3' {
            gen weekday = dow(date)
            replace date = date - 1 if inlist(weekday,2,3,4,5)
            replace date = date - 3 if weekday == 1
            drop weekday
        }
        
        // increment iteration
        local ++iteration
        
        // stop program if unsuccessful after three increases
        if `iteration' > 6 {
            n di as error "Could not merge dataset `i'"
            exit
        }
        
        // display results
        n di as text "Iteration " as result `iteration'-1
        n di as text "Overlap: " as result `overlap'
    }
    
    // report how dates were changed
    if `iteration' > 4 {
        n di as res "Increased date by " `=`iteration' - 4' " days"
    }
    if inrange(`iteration',2,4) {
        n di as res "Decreased date by " `=`iteration'-1' " days"
    }
    
    // drop duplicates
    qui duplicates drop date adres volgorde aantal_reacties positie regdate, force
    drop _merge
    
    // double-check for duplicates
    qui gen id = _n
    sort adres date
    qui gen diff = date - date[_n-1] if ///
        adres == adres[_n-1] & volgorde == volgorde[_n-1] & ///
        aantal_reacties == aantal_reacties[_n-1] & ///
        positie == positie[_n-1] & regdate == regdate[_n-1]
    
    qui drop if inrange(diff,1,3)
    di as result r(N_drop) as text " leftover duplicates have been removed"
    sort id
    drop id diff
}

// calculate waiting time
cap gen waittime = 0
replace regyear     = year(regdate)
replace waittime    = (date - regdate) / 365 * 12

label data "Full sample, `c(current_date)'"
save "working/complete/verantwoording.dta", replace


