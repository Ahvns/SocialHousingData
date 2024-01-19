// Workflow for maintaining dataset

// obtain new data
do import

clear

// combine datasets
do combine

clear

// geocode dataset
use "working/complete/verantwoording.dta", clear
qui do geocode

clear

