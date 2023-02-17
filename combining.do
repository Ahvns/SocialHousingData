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

local x: dir working files "*"
qui foreach i of local x {
    use "working/`i'", clear
    local current `i'
    continue, break
}
local x: list x - current

foreach i of local x {
    di as txt "`i'"
    qui merge 1:1 date adres volgorde aantal_reacties positie regdate using "working/`i'"
    qui count if _merge==3
    local overlap = `=r(N)'
    flsort, n(adres) d(date) extra(_merge)
    local iteration = 1
    qui while `overlap'< 100 {
        drop if _merge==2
        drop _merge
        forvalues it = 1/`iteration' {
            gen weekday = dow(date)
            replace date = date - 1 if inlist(weekday,2,3,4,5)
            replace date = date - 3 if weekday == 1
            drop weekday
        }
        merge 1:1 date adres volgorde aantal_reacties positie regdate using "working/`i'"
        flsort, n(adres) d(date) extra(_merge)
        qui count if _merge==3
        local overlap = `=r(N)'
        forvalues it = 1/`=`iteration'' {
            gen weekday = dow(date)
            replace date = date + 1 if inlist(weekday,1,2,3,4)
            replace date = date + 3 if weekday == 5
            drop weekday    
        }
        local ++iteration
        if `iteration' > 3 {
            continue, break
        }
    }
    qui while `overlap'< 100 {
        drop if _merge==2
        drop _merge
        forvalues it = 1/`=`iteration'-3' {
            gen weekday = dow(date)
            replace date = date + 1 if inlist(weekday,1,2,3,4)
            replace date = date + 3 if weekday == 5
            drop weekday    
        }
        merge 1:1 date adres volgorde aantal_reacties positie regdate using "working/`i'"
        flsort, n(adres) d(date) extra(_merge)
        qui count if _merge==3
        local overlap = `=r(N)'
        forvalues it = 1/`=`iteration'-3' {
            gen weekday = dow(date)
            replace date = date - 1 if inlist(weekday,2,3,4,5)
            replace date = date - 3 if weekday == 1
            drop weekday
        }
        local ++iteration
        if `iteration' > 6 {
            n di as error "Could not merge dataset `i'"
            exit
        }
    }
    if `iteration' > 4 {
        n di as res "Increased date by " `=`iteration' - 4' " days"
        n di as text ""
    }
    if inrange(`iteration',2,4) {
        n di as res "Decreased date by " `=`iteration'-1' " days"
        n di as text ""
    }
    
    qui duplicates drop date adres volgorde aantal_reacties positie regdate, force
    drop _merge
}

cap gen waittime = 0
replace regyear     = year(regdate)
replace waittime    = (date - regdate) / 365 * 12

label data "Full sample, `c(current_date)'"
save "working/complete/verantwoording.dta", replace


