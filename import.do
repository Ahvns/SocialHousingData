
quietly {
	n di "Obtaining API key and web URL"
	url	// obtain url and API key in locals

	n di "Importing new dataset"
	import excel /// import social housing data from online
		"`url'", /// download file from social housing website
		clear // clear currently opened data

	n di "Cleaning new data"
	drop if _n < 6	// drop empty cells
	n di "Dropped empty cells"
	foreach var of varlist * {	// loop over all variables to rename them
		rename `var' `=strtoname(`var'[1])'	// rename variable to value of first observation
	}
	n di "Renamed variables"
	drop in 1	// drop first observation (contains only variable names)

	destring, replace	// convert variables to numeric where possible
	n di "Converted variables to numeric where possible"

	replace Adres = ustrto(ustrnormalize(Adres, "nfd"), "ascii", 2)	// replace accented characters
	n di "Cleaned address strings"

	keep if Reden == "Verhuurd"	// only keep postings that were rented out
	n di "Dropped postings that were not rented out"

	local today : di daily("$S_DATE", "DMY")	// create local containing current day
	gen year = year(`today')	// generate variable containing current year
	gen month = month(`today')	// generate variable containing current month
	gen day = day(`today')	// generate variable containing current day
    gen date = mdy(month,day,year)
    format date %tdDD_Month_CCYY


	gen regdate = date(Inschrijfdatum, "DMY")	// generate numeric date of registration
	format regdate %tdDD_Month_CCYY
	gen regyear = year(regdate)	// extract year of registration
	drop if regyear >2090 & regyear !=.	// drop errors : in category Wens&Wacht, some registrations are recorded as if after 2090


	quietly{	// label variables
		lab var regyear "year of registration"
		lab var regdate "date of registration"
		lab var year "year rented out"
		lab var month "month rented out"
		lab var Kenmerken "Trait for Rotterdam Act"
		lab var Positie "Position on waiting list"
		lab var Aantal_reacties "Number of applications"
		lab var Volgorde "Selection method"
		lab var Inschrijfdatum "date of registration"
		lab var Adres "Address"
	}
	n di "Labeled variables"

	quietly {	//	several variables are initiated below
		gen geocode = 0
		gen str6 pc6 = ""
		gen str5 pc5 = ""
		gen str4 pc4 = ""
		gen str16 lat = ""
		gen str16 lon = ""
		gen str64 street = ""
		gen str10 huisnr = ""
	}
	n di "Generated new variables for geocoding"


	quietly{	// label new variables
		lab var geocode "Indicator if observation has been geocoded"
		lab var pc6 "6 digit postcode"
		lab var pc5 "5 digit postcode"
		lab var pc4 "4 digit postcode"
		lab var lat "latitude"
		lab var lon "longitude"
		lab var street "street of address"
		lab var huisnr "house number of address"
	}
	n di "Labeled new variables"

	label data "Last update: `c(current_date)'"	// update description of dataset
	local today :  di %tdCYND daily("$S_DATE", "DMY")	// change format of date local
	save "archive/verantwoording`today'.dta", replace	// save dataset
    save "working/verantwoording`today'.dta", replace
	n di "Saved dataset"
}
