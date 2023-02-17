<<<<<<< current
cap program drop datefix

program datefix

syntax , Date(varname) Name(varname) [FLAGmargin(integer 10) ERRor(string) NOChange]

// Make report default option if nothing specified
if "`error'" == "" local error "report"

// Only allow specified options for error
if inlist("`error'", "drop", "report", "fix") {

    // Initialise temporary variables
    tempvar firstletter fl weekday newday datecopy flag

    // Generate intermediate variables
    qui {
        gen `weekday' = .
        // Obtain first letter of address
        gen str1 `firstletter' = regexs(0) if regexm(`name',"^.")
        // Force all letters to be lowercase
        replace `firstletter' = lower(`firstletter')
        // Encode first letters to numbers for easy comparison
        encode `firstletter', generate(`fl')
        // Flag observation to be a new day if first letter of address is earlier in the alphabet than previous observation's
        gen `newday' = `fl' < `fl'[_n-1]
        // Do not flag first observation
        replace `newday' = 0 in 1

        // Flag observations with potentially wrong dates (e.g. sorting mistake)
        gen `flag' = `fl' > `flagmargin' & `newday' == 1
        replace `flag' = `flag'[_n-1] if `newday' == 0
    }

    // Report potentially wrong observations
    if "`error'"=="report"{
        forvalues i = 2/`=_N' {
            if `flag'[`i']==1{
                di "Potential error at observation `i'"
            }
        }
    }

    // Drop potentially wrong observations
    if "`error'"=="drop" {
        // Initialise local to remember obervation numbers
        local errors
        // Obtain observation numbers of potential mistakes
        forvalues i = 2/`=_N' {
            if `flag'[`i']==1{
                local errors "`i' `errors'"
            }
        }
        // Drop potential wrong observations
        foreach n of local errors {
            di "Dropped observation `n'"
            qui drop in `n'
        }
    }

    // Fix potentially wrong observations by incorporating them in the preceding day
    if "`error'"=="fix"{
        qui {
            // Remove new day indicator if flagged as error
            replace `newday' = 0 if `flag'==1
            // Copy date variable
            gen `datecopy' = `date'
            // Change date by one for every new day
            replace `datecopy' = `datecopy'[_n-1] - `newday' in 2/`=_N'
            // Sort based on "new" date and first letter of address, so that flagged observations are now part of preceding day
            gsort -`datecopy' +`fl'
            // Drop copy of dates
            drop `datecopy'
            // Report what observations have changed
            forvalues i = 2/`=_N'{
                if `flag'[`i']==1{
                    n di "Changed observation `i'"
                }
            }
        }


    }

    // Changing the actual dates
    if "`nochange'"==""{
        qui {
            // First pass: replace dates with previous observation's date minus new day flag
            replace `date' = `date'[_n-1] - `newday' in 2/`=_N'
            // Loop to correct for weekends
            while 1 {
                // Reset new day flag to one
                replace `newday' = `newday'>0
                // Obtain day of the week for each date
                replace `weekday' = dow(`date')
                // Change new day flag to two if previous day is a Sunday
                replace `newday' = 2 if `newday'==1 & `weekday'[_n-1]==0
                // Change new day flag to three if previous day is a Monday
                replace `newday' = 3 if `newday'==1 & `weekday'[_n-1]==1
                // Copy current dates
                gen `datecopy' = `date'
                // Replace dates with previous observation's date minus new day flag
                replace `date' = `date'[_n-1] - `newday' in 2/`=_N'
                // Check if any dates have changed, if none, stop
                count if `datecopy'!=`date'
                if (`r(N)'==0) continue, break
                // Drop the copy of old dates
                drop `datecopy'
            }
        }

    }


}
else {
    di as err "option error() incorrectly specified"
    exit(198)
}

end

// sorting program
cap program drop flsort

program flsort

syntax, Date(varname) Name(varname) [EXTRA(varlist)]

tempvar firstletter fl
local exsort ""
if "`extra'"!="" {
    foreach var of local extra {
        local exsort "+`var' `exsort'"
    }
}
qui{
    // Obtain first letter of address
    gen str1 `firstletter' = regexs(0) if regexm(`name',"^.")
    // Force all letters to be lowercase
    replace `firstletter' = lower(`firstletter')
    // Encode first letters to numbers for easy comparison
    encode `firstletter', generate(`fl')
    // Sort
    gsort -`date' +`fl' `exsort'
}


end
=======
cap program drop datefix

program datefix

syntax , Date(varname) Name(varname) [FLAGmargin(integer 10) ERRor(string) NOChange]
    
// Make report default option if nothing specified
if "`error'" == "" local error "report"

// Only allow specified options for error
if inlist("`error'", "drop", "report", "fix") {
    
    // Initialise temporary variables
    tempvar firstletter fl weekday newday datecopy flag 
    
    // Generate intermediate variables
    qui {
        gen `weekday' = .
        // Obtain first letter of address
        gen str1 `firstletter' = regexs(0) if regexm(`name',"^.")
        // Force all letters to be lowercase
        replace `firstletter' = lower(`firstletter')
        // Encode first letters to numbers for easy comparison
        encode `firstletter', generate(`fl')
        // Flag observation to be a new day if first letter of address is earlier in the alphabet than previous observation's
        gen `newday' = `fl' < `fl'[_n-1]
        // Do not flag first observation
        replace `newday' = 0 in 1
        
        // Flag observations with potentially wrong dates (e.g. sorting mistake)
        gen `flag' = `fl' > `flagmargin' & `newday' == 1
        replace `flag' = `flag'[_n-1] if `newday' == 0
    }
    
    // Report potentially wrong observations
    if "`error'"=="report"{
        forvalues i = 2/`=_N' {
            if `flag'[`i']==1{
                di "Potential error at observation `i'"
            }
        }
    }
    
    // Drop potentially wrong observations
    if "`error'"=="drop" {
        // Initialise local to remember obervation numbers
        local errors
        // Obtain observation numbers of potential mistakes
        forvalues i = 2/`=_N' {
            if `flag'[`i']==1{
                local errors "`i' `errors'"
            }
        }
        // Drop potential wrong observations
        foreach n of local errors {
            di "Dropped observation `n'"
            qui drop in `n'
        }
    }
    
    // Fix potentially wrong observations by incorporating them in the preceding day
    if "`error'"=="fix"{
        qui {
            // Remove new day indicator if flagged as error
            replace `newday' = 0 if `flag'==1
            // Copy date variable
            gen `datecopy' = `date'
            // Change date by one for every new day
            replace `datecopy' = `datecopy'[_n-1] - `newday' in 2/`=_N'
            // Sort based on "new" date and first letter of address, so that flagged observations are now part of preceding day
            gsort -`datecopy' +`fl'
            // Drop copy of dates
            drop `datecopy'
            // Report what observations have changed
            forvalues i = 2/`=_N'{
                if `flag'[`i']==1{
                    n di "Changed observation `i'"
                }
            }
        }

        
    }
    
    // Changing the actual dates
    if "`nochange'"==""{
        qui {
            // First pass: replace dates with previous observation's date minus new day flag
            replace `date' = `date'[_n-1] - `newday' in 2/`=_N'
            // Loop to correct for weekends
            while 1 {
                // Reset new day flag to one
                replace `newday' = `newday'>0
                // Obtain day of the week for each date
                replace `weekday' = dow(`date')
                // Change new day flag to two if previous day is a Sunday
                replace `newday' = 2 if `newday'==1 & `weekday'[_n-1]==0
                // Change new day flag to three if previous day is a Monday
                replace `newday' = 3 if `newday'==1 & `weekday'[_n-1]==1
                // Copy current dates
                gen `datecopy' = `date'
                // Replace dates with previous observation's date minus new day flag
                replace `date' = `date'[_n-1] - `newday' in 2/`=_N'
                // Check if any dates have changed, if none, stop
                count if `datecopy'!=`date'
                if (`r(N)'==0) continue, break
                // Drop the copy of old dates
                drop `datecopy'
            }
        }
        
    }
    
    
}
else {
    di as err "option error() incorrectly specified"
    exit(198)
}

end

// sorting program
cap program drop flsort

program flsort

syntax, Date(varname) Name(varname) [EXTRA(varlist)]

tempvar firstletter fl
local exsort ""
if "`extra'"!="" {
    foreach var of local extra {
        local exsort "+`var' `exsort'"
    }
}
qui{
    // Obtain first letter of address
    gen str1 `firstletter' = regexs(0) if regexm(`name',"^.")
    // Force all letters to be lowercase
    replace `firstletter' = lower(`firstletter')
    // Encode first letters to numbers for easy comparison
    encode `firstletter', generate(`fl')
    // Sort
    gsort -`date' +`fl' `exsort'
}


end
>>>>>>> before discard
