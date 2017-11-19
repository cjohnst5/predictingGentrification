set trace on
set tracedepth 2
set more off
timer clear
clear
graph drop _all
set matsize 800
set seed 123
sysuse auto




/*===========================================================================================*/
/*                                     Main Program                                          */
/*===========================================================================================*/
capture program drop main
program define main
    paths

    // =============== 0 Comment in/out subprograms you wish to run ================
	

	cleanNHGIS, county("San Francisco County")
	


	
	
end

//TODO



/*===========================================================================================*/
/*                                    Sub Programs                                           */
/*===========================================================================================*/
 
/*---------------------------------------------------------*/
/* Define Path Macros 					                   */
/*---------------------------------------------------------*/
capture program drop paths
program define paths

	*Paths for EML server
	global dataRAW  "C:/Users/Daniel and Carla/Dropbox/projects/predictingGentrification/build/dataRAW/"	
	global dataCLEAN "C:/Users/Daniel and Carla/Dropbox/projects/predictingGentrification/build/dataCLEAN/"
	global code "C:/Users/Daniel and Carla/Dropbox/projects/predictingGentrification/build/code"
	
	*Creating a string with current date and time
	local c_date = c(current_date)
	local c_time = c(current_time)
	local c_time_date = "`c_date'"+"_"+"`c_time'"
	local time_string = subinstr("`c_time_date'", ":", "_", .)
	local time_string = subinstr("`time_string'", " ", "_", .)
	//starting a log file
	*Creating a string with current date and time
	local c_date = c(current_date)
	local c_time = c(current_time)
	local c_time_date = "`c_date'"+"_"+"`c_time'"
	local time_string = subinstr("`c_time_date'", ":", "_", .)
	local time_string = subinstr("`time_string'", " ", "_", .)
	capture log close
	log using "$code/logFiles/build`time_string'.log", replace
	
end;	
//paths

/*---------------------------------------------------------*/
**** First Program ****
/*---------------------------------------------------------*/
capture program drop cleanNHGIS
program define cleanNHGIS
syntax[, county(string)]
	
	tempfile household race housing incomeEducation age
	
	/*=====================
	Race variables
	=======================*/
	*White, black, asian
	import delimited "$dataRAW/NHGIS/nhgis0017_csv/nhgis0017_ds172_2010_tract.csv", clear	
	keep if state == "California"
	keep if county == "`county'"

	rename tracta tractID	
	rename h7x001 totalPop
	rename h7x002 white
	rename h7x003 black
	rename h7x005 asian
	
	gen prcntWhite = white/totalPop
	gen prcntBlack = black/totalPop
	gen prcntAsian = asian/totalPop
	
	keep year gisjoin tractID county totalPop white black asian prcntWhite ///
		prcntBlack prcntAsian	
	save `race', replace

	*Hispanic
	import delimited "$dataRAW/NHGIS/nhgis0017_csv/nhgis0017_ds176_20105_2010_tract.csv", clear	
	keep if state == "California"
	keep if county == "`county'"
	
	rename tracta tractID
	rename jmke001 totalPop
	rename jmke003 hisp
	
	gen prcntHisp = hisp/totalPop
	
	keep tractID prcntHisp
	merge 1:1 tractID using `race', nogen
	save `race', replace

	

	/*=====================
	Household variables
	=======================*/
	import delimited "$dataRAW/NHGIS/nhgis0016_csv/nhgis0016_ds181_2010_tract.csv", clear
	
	keep if state == "California"
	keep if county == "`county'"

	rename tracta tractID	
	rename lhc001 totalHouseholds
	rename lhc002 husWifeFam
	rename lhc003 husWifeChild
	rename lhc016 snglMom
	
	gen prcntSnglMom = snglMom/totalHouseholds
	gen prcntHusWifeFam = husWifeFam/totalHouseholds
	gen prcntHusWifeChild = husWifeChild/totalHouseholds
	
	keep tractID totalHouseholds husWifeFam husWifeChild snglMom prcnt*
	save `household', replace
	
	/*=====================
	Housing variables
	=======================*/
	import delimited "$dataRAW/NHGIS/nhgis0015_csv/nhgis0015_ds172_2010_tract.csv", clear
	
	keep if state == "California"
	keep if county == "`county'"
	
	rename tracta tractID
	rename ife001 totHousingUnits
	rename ife002 totOccUnits
	rename ife003 totVacUnits
	rename iff004 totRentUnits
	
	gen occRate = totOccUnits/totHousingUnits
	gen prcntRentOcc = totRentUnits/totHousingUnits
	
	keep tractID totHousingUnits totOccUnits totVacUnits totRentUnits occRate prcntRentOcc
	save `housing', replace
	
	/*=====================
	Education and Income levels
	=======================*/		
	import delimited "$dataRAW/NHGIS/nhgis0018_csv/nhgis0018_ds176_20105_2010_tract.csv", clear
	
	keep if state == "California"
	keep if county == "`county'"
	
	rename tracta tractID
	rename joim001 medianInc
	
	keep tractID medianInc
	save `incomeEducation'
	
	import delimited "$dataRAW/NHGIS/nhgis0014_csv/nhgis0014_ds176_20105_2010_tract.csv", clear
	
	keep if state == "California"
	keep if county == "`county'"
	
	rename tracta tractID
	rename jn9e002 totalPop
	rename jn9e015 maleBachelorDeg
	rename jn9e016 maleMastersDeg
	rename jn9e017 maleProfDeg
	rename jn9e018 malePhD

	rename jn9e032 femaleBachelorDeg
	rename jn9e033 femaleMastersDeg
	rename jn9e034 femaleProfDeg
	rename jn9e035 femalePhD
	
	gen bachelorDeg = maleBachelorDeg + femaleBachelorDeg
	gen mastersDeg = maleMastersDeg + femaleMastersDeg
	gen profDeg = maleProfDeg + femaleProfDeg
	gen phD = malePhD + femalePhD
	gen prcntHighEdu = (bachelorDeg + mastersDeg + profDeg + phD)/totalPop
	
	keep tractID bachelorDeg mastersDeg profDeg phD prcntHighEdu
	
	merge 1:1 tractID using `incomeEducation', nogen
	save `incomeEducation', replace
	
	/*=====================
	Age variables
	=======================*/
	import delimited "$dataRAW/NHGIS/nhgis0013_csv/nhgis0013_ds172_2010_tract.csv", clear
	
	keep if state == "California"
	keep if county == "`county'"
	
	rename tracta tractID	
	rename h76001 totalPop
	
	egen under18 = rowtotal(h76003-h76006 h76027-h76030)
	egen age18_29 = rowtotal(h76007-h76011 h76031-h76035)
	egen age30_44 = rowtotal(h76012-h76014 h76036-h76038)
	egen age44_64 = rowtotal(h76015-h76019 h76039-h76043)
	egen age65plus = rowtotal(h76020-h76025 h76044-h76049)
	
	keep tractID under18 age18_29 age30_44 age44_64 age65plus

	foreach dataSet in `race' `household' `housing' `incomeEducation'{
		merge 1:1 tractID using `dataSet', nogen 	
	}	
	compress
	save "$dataCLEAN/nhgisVariables.dta", replace
end


/*---------------------------------------------------------*/
**** Second Program ****
/*---------------------------------------------------------*/
capture program drop eitcEligible
program define eitcEligible
syntax[, matchIncome(string) randomSample(string) percentSample(integer 5) trips(string) ///
	purchases(string) years(string) inputDir(string)] 
	
	
	
	
	*******Constructing EITC tax tables	
	use "$dataRAWCarla/eitcTaxTables/statebyhh_eitcparameters.dta", clear
	rename taxyear year
	rename stfips fips_state_code
	rename numchild number_children
	replace inrate = inrate/100
	replace outrate = outrate/100
	drop if year < 2002
	sort fips_state_code number_children year
	local genLagged year fedmaxcredit inrate plateaustart_single outrate plateauend_single zero_transfer_single plateaustart_married plateauend_married zero_transfer_married totmaxcredit staterate
	foreach variab in `genLagged'{
		by fips_state_code number_children: gen L`variab' = `variab'[_n-2]
	}
	keep L* year number_children fips_state_code pce_inflator
	
	tempfile eitcParameters
	save `eitcParameters'
	
	
	**********Constructing EITC eligible variables	
	//Saving the first and last year of the merged panelists data we used for file name purposes
	local counter = 0
	foreach year in `years'{
		local counter `=`counter'+1'
		if `counter' == 1{
			local firstYear = "`year'"
		}
		local yearPresent = "`year'"
	}
	use "`inputDir'/panelists_RS`randomSample'_PS`percentSample'_T`trip'_P`purchases'_years`firstYear'to`yearPresent'.dta", clear
	
	rename panel_year year
	
	
	*impute income as midpoint of income category
	gen household_income_est = 0
	replace household_income_est = 2500 if household_income == 3
	replace household_income_est = 6500 if household_income == 4
	replace household_income_est = 9000 if household_income == 6
	replace household_income_est = 11000 if household_income == 8 
	replace household_income_est = 13500 if household_income == 10
	replace household_income_est = 17500 if household_income == 11
	replace household_income_est = 22500 if household_income == 13
	replace household_income_est = 27500 if household_income == 15
	replace household_income_est = 32500 if household_income == 16
	replace household_income_est = 37500 if household_income == 17
	replace household_income_est = 42500 if household_income == 18
	replace household_income_est = 47500 if household_income == 19
	replace household_income_est = 55000 if household_income == 21
	replace household_income_est = 65000 if household_income == 23
	replace household_income_est = 85000 if household_income == 26
	replace household_income_est = 100000 if household_income  >= 27
	tab household_income_est
	
	*Dummy for households with only one head. We will use this variable
	*to determine tax-filing status (we will not use marital_status variable
	*anymore). 
	gen single_head = 0
	replace single_head = 1 if marital_status != 1
	//I'm including divorced and widowed in my sample.  
	replace single_head = 0 if female_head_age != 0 & male_head_age != 0 
	//About 1/3 of our sample is single
	
	*Imputing the number of children
	gen number_children = 0
	gen one_family_household = 0
	replace one_family_household = 1 if type_of_residence == 1 | type_of_residence == 2
	*Single households with children
	replace number_children = household_size - 1 if one_family_household == 1 ///
		& single_head == 1 ///
		& household_size != 9 ///
		& age_and_presence_of_children != 9 
	//Largest tax credit applies to familes with 3 or more kids
	replace number_children = 3 if number_children > 3 & !missing(number_children)
		
	*Married households with children
	replace number_children = household_size - 2 if one_family_household == 1 ///
		& single_head == 0 ///
		& household_size != 9 ///
		& age_and_presence_of_children != 9 
	replace number_children = 3 if number_children > 3 & !missing(number_children) 

	*Merge Nielsen data with eitc parameters
	merge m:1 fips_state_code year number_children using `eitcParameters', nogen keep(3)


	
	*Calculating federal tax return using income. We are using the tax rules from 2 years before the survey year. 
	*Single head of households
	gen federalEITC = 0
	replace federalEITC = household_income_est*Linrate if household_income_est < Lplateaustart_single & single_head == 1
	replace federalEITC = Ltotmaxcredit if household_income_est >= Lplateaustart_single ///
		& household_income_est <=Lplateauend_single & single_head == 1 
	replace federalEITC = Ltotmaxcredit - Loutrate*(household_income_est - Lplateauend_single) ///
		if household_income_est > Lplateauend_single ///
		& household_income_est <=Lzero_transfer_single & single_head == 1
	*Married head of households
	replace federalEITC = household_income_est*Linrate ///
		if household_income_est < Lplateaustart_married & single_head == 0
	replace federalEITC = Ltotmaxcredit ///
		if household_income_est >= Lplateaustart_married ///
		& household_income_est <=Lplateauend_married & single_head == 0 
	replace federalEITC = Ltotmaxcredit - Loutrate*(household_income_est-Lplateauend_married) ///
		if household_income_est > Lplateauend_married ///
		& household_income_est <=Lzero_transfer_married & single_head == 0
	
	*Calculating maximum tax return (including state tax return in total)
	gen totalEITC = federalEITC*(1+Lstaterate/100)
	
	*******Calculating maxEITC receipt using education, marital status and number of children. 
	*Using mother's education as a measure of eligibility
	gen head_edu = . 
	replace head_edu = female_head_edu if female_head_edu !=0 
	//If female education is missing then use male's education 
	replace head_edu = male_head_edu if female_head_edu == 0 
	
	*Determining maximum EITC eligibility, federal and state
	gen maxFedEITC = 0
	//a household is EITC eligible if the mother has less than some education
	//maxchild is the maximum EITC they could get back given the household's
	//filing status and number of children. 	
	replace maxFedEITC = Ltotmaxcredit if head_edu <= 4 
	gen maxTotEITC = maxFedEITC *(1 + Lstaterate/100)
	
	***Convertings this to 2010 dollars
	gen federalEITC2010 = federalEITC*pce_inflator
	gen maxFedEITC2010 = maxFedEITC*pce_inflator
	gen maxTotEITC2010 = maxTotEITC*pce_inflator
	gen totalEITC2010 = totalEITC*pce_inflator
	
	**Dropping unneccessary variables
	drop L* pce_inflator
	
	*Labeling new variables
	*label variable stateRate "Percent of Federal EITC that the state will match"  
	label variable federalEITC "Estimated dollar amount of federal EITC"
	label variable federalEITC2010 "Estimated dollar amount of federal EITC-2010 dollars"	
	label variable totalEITC "Total EITC (state and federal) dollar amount"
	label variable totalEITC2010 "Total EITC (state and federal) dollar amount-2010 dollars"
	label variable head_edu "Female household head's education. If there is no female head, then male head education"
	label variable maxFedEITC "Maximum federal EITC dollar amount possible given marital status and number of children" 
	label variable maxFedEITC2010 "Maximum federal EITC dollar amount possible given marital status and number of children. 2010 dollars" 
	label variable maxTotEITC "Maximum fed and state EITC dollar amount possible given marital status and number of children"
	label variable maxTotEITC2010 "Maximum fed and state EITC dollar amount given marital status and number of children. 2010 dollars"

	*Saving the dataset for now. Later we might wait to save if we have more to do
	save "$dataRAWCarla/NielsenScannerData/eitcElg/panelists_RS`randomSample'_PS`percentSample'_T`trip'_P`purchases'_years`firstYear'to`yearPresent'_EITCYes.dta", replace
 	
	

end

/*---------------------------------------------------------*/
 /* Comparing our sample to CPS                            */
 /*--------------------------------------------------------*/
capture program drop compareCPS
program define compareCPS
syntax [, randomSample(string) percentSample(integer 5) trips(string) ///
	purchases(string) years(string)]

	local counter = 0
	foreach year in `years'{
		*Saving the first and last year we want to merge data over
		local counter `=`counter'+1'
		if `counter' == 1{
			local firstYear = "`year'"
		}
		local yearPresent = "`year'"
	}
	import excel "$dataRAWCarla/CPS/incomeTables/hinc2014_cleaned.xls", sheet("sheet1") firstrow clear
	*Dropping the observation "Total"
	gen bin = _n
	rename number_households num_house_cps
	sum num_house_cps if bin == 1
	local total=r(max)
	drop if bin == 1
	rename IncomeofHousehold hinc2014
	*Now bin is an id for income categories
	replace bin = bin-1
	sum bin
	local maxBin = r(max)
	
	*We need to combine some bins so that CPS bins match with Nielsen bins
	*Reshape the data in wide format to make adding bins together easier
	replace bin = 11 if bin == 12
	replace bin = 13 if bin == 14
	forval b = 16/20{
		replace bin = 15 if bin == `b'
	}
	forval b = 22/`maxBin'{
		replace bin = 21 if bin == `b'
	}
	
	collapse (sum) num_house_cps, by(bin)
	replace bin = _n 
	rename bin hinc14
	tempfile cps
	save `cps'
	
	*Import Nielsen data
	import delimited "$dataNielsen/HMS/2014/Annual_Files/panelists_2014.tsv", clear
	replace household_income = 4 if household_income == 6
	replace household_income = 8 if household_income == 10
	sort household_income
	collapse (sum) num_house_nielsen = projection_factor, by(household_income)
	rename household_income hinc14
	replace hinc14 = _n
	
	#delimit ;
	label define hinc14 
            1 "Under $5,000"
            2 "$5,000 - $9,999"
            3 "$10,000 - $14,999"
            4 "$15,000 - $19,000"
            5 "$20,000 - $24,999"
            6 "$25,000 - $29,999"
	    7 "$30,000 - $34,999"
	    8 "$35,000 - $39,999"
	    9 "$40,000 - $44,999"
	    10 "$45,000 - $49,999"
	    11 "$50,000 - $59,999"
	    12 "$60,000 - $69,999"
	    13 "$70,000 - $99,999"
	    14 "$100,000 and above" ;
	#delimit cr; 
	
	merge 1:1 hinc14 using `cps'
	twoway (histogram hinc14 [fweight = num_house_nielsen], discrete color(green)) ///
		(histogram hinc14 [fweight = num_house_cps], discrete ///
		fcolor(none) lcolor(black)), legend(order(1 "Nielsen" 2 "CPS" )) ///
		title("Histogram of 2014 Household Income")
	graph export "$figures/incomeHist2014.pdf", replace
	
	di"***********************************Import CPS ACES data"
	**Importing price inflator
	use "$dataRAWCarla/eitcTaxTables/statebyhh_eitcparameters.dta", clear
	contract taxyear pce_inflator
	rename taxyear year
	tempfile inflator
	save `inflator'
	***Looking at the whole population CPS
	use "$dataRAWCarla/CPS/aces/cps_00002.dta", clear
	replace eitcred = . if eitcred == 9999
	merge m:1 year using `inflator', nogen keep(3)
	gen eitcred2010 = eitcred*pce_inflator
	sum eitcred2010 if eitcred2010 > 0 & year <=2013, detail
	*Percent households that receive the EITC
	gen yesEITC = 0
	replace yesEITC = 1 if eitcred2010 > 0 
	sum yesEITC 
	tempfile cpsaces
	save `cpsaces'

	
	*Use CPS MORG files for demographics 
	*Age, number of single mothers, education, income
	use "$dataRAWCarla/CPS/morg/morgAllYears.dta", clear
	label define reflabel 1" Ref pers w/relations" 2 "Ref pers w/o relations" ///
		3 "Spouse" 4 "child"  
	label values relref95 reflabel
	drop if year < 2012
	*Female head age
	sum age if (relref95 == 1 | relref95 == 3 | relref95 == 2) & sex == 2, detail
	*Male head age
	sum age if (relref95 == 1 | relref95 == 3 | relref95 == 2) & sex == 1, detail
	*Race
	label define raceLabel 1 "White" 2 "Black" 
	label values race raceLabel
	tab race
	*Female household head education
	gen education = 0
	replace education = 1 if ged == 1
	replace education = 2 if grprof == 1
	replace education = 3 if ms123 == 1 |  ms123 == 2 | ms123 == 3
	label define educLabel 1 "Highschool" 2 "College" 3 "Higher degree"
	label values education educLabel
	tab education if sex == 2 & relref95 == 1 | relref95 == 2| relref95 == 3
	*hist education if sex == 2 & relref95 == 1 | relref95 == 2, ///
		discrete addlabels percent
	
	*Percent households with children
	gen children = 0
	replace children = 1 if chldpres! = 0
	tab children if relref95 == 1 | relref95 == 2
	*Percent households with single mothers
	//First we need to find the total number of households in our sample
	count if relref95 == 1 | relref95 == 2
	local numberHouseholds = r(N)
	//Creating a single parent dummy
	gen singleParent = 0 
	//I'm including widowed and divorced in my sample of single head
	replace singleParent = 1 if chldpres != 0 & marital != 1	
	count if sex == 2 & singleParent == 1 & relref95 == 1 
	local numberSingle = r(N)
	di "Percent single mothers"  = `numberSingle'/`numberHouseholds'		
	
	*Percent of married households with children
	//I count a household as married if the reference person is married
	count if marital == 1 & relref95 == 1 & chldpres != 0
	local numberMarried = r(N)
	di "Percent married parents" = `numberMarried'/`numberHouseholds'
	
	*****
	di "*****************************************************************************"
	di "**EITC recipients only - CPS data"
	use "$dataRAWCarla/CPS/aces/cps_00002.dta", clear
	keep if eitcred > 0 & year >=2004
	rename relate relref95
	rename marst marital
	rename serial hhid
	*Female head age - whole sample
	sum age if (relref95 == 101 | relref95 == 201) & sex == 2
	*Male head age - whole sample
	sum age if (relref95 == 101 | relref95 == 201) & sex == 1
	*Race
	tab race
	*Female head of household education
	gen education = 0
	replace education = 1 if educ99 == 1 | educ99 == 4 | educ99 == 5
	replace education = 2 if educ99 == 6 | educ99 == 7 | educ99 == 8 | educ99 == 9
	replace education = 3 if educ99 == 10
	replace education = 4 if educ99 == 11 | educ99 == 13 | educ99 == 14
	replace education = 5 if educ99 == 15 
	replace education = 6 if educ99 == 16 | educ99 == 17 | educ99 == 18
	label define educ2label 1 "Gradeschool" 2 "Some high school" ///
		3 "Graduated high school" 4 "Some college" 5 "Graduated college" ///
		6 "Post college"
	label values education educ2label 
	//Only want female head of household education. Assuming heads of households are ref persons or spouses
	tab education if sex == 2 & relref95 == 101 | relref95 == 201 
	

	*Percent households with children
	gen children = 0
	replace children = 1 if nchild! = 0
	tab children if relref == 101
	
	*Percent households with single mothers
	//First we need to find the total number of households in our sample
	count if relref95 == 101 
	local numberHouseholds = r(N)	
	//Creating a single parent dummy
	gen singleParent = 0 
	//I'm including widowed and divorced in my sample of single head
	replace singleParent = 1 if marital != 1	
	count if sex == 2 & singleParent == 1 & relref95 == 101 & nchild != 0
	local numberSingle = r(N)
	di "Percent single mothers"  = `numberSingle'/`numberHouseholds'		
	
	*Percent of married households with children
	//I count a household as married if the reference person is married
	count if marital == 1 & relref95 == 101 & nchild != 0
	local numberMarried = r(N)
	di "Percent married parents" = `numberMarried'/`numberHouseholds'
	
	
	***************************************************************************
	di "***************************************************************************"
	di "****Import and summarize Nielsen data"
	di "**All households"
	use "$dataRAWCarla/NielsenScannerData/eitcElg/panelists_RS`randomSample'_PS`percentSample'_T`trip'_P`purchases'_years`firstYear'to`yearPresent'_EITCYes.dta", clear
	sum federalEITC2010 if federalEITC2010 > 0 & !missing(federalEITC2010) [fweight = projection_factor], detail 

	*Percent households that have EITC - Nielsen
	//Income imputed measure
	gen yesEITC_ii = 0
	replace yesEITC_ii = 1 if federalEITC2010 > 0 & !missing(federalEITC2010) 
	//Demographics imputed
	gen yesEITC_di = 0
	replace yesEITC_di = 1 if maxFedEITC2010 > 0 & !missing(maxFedEITC2010)
	sum yesEITC_ii yesEITC_di [fweight = projection_factor]

	*Average age of heads of household - Nieslen
	gen female_age_est = female_head_age
	replace female_age_est = 25 if female_head_age == 1
	replace female_age_est = 27.5 if female_head_age == 2
	replace female_age_est = 32.5 if female_head_age == 3
	replace female_age_est = 37.5 if female_head_age == 4
	replace female_age_est = 42.5 if female_head_age == 5
	replace female_age_est = 47.5 if female_head_age == 6
	replace female_age_est = 52.5 if female_head_age == 7
	replace female_age_est = 60 if female_head_age == 8
	replace female_age_est = 65 if female_head_age == 9

	gen male_age_est =  male_head_age
	replace male_age_est = 25 if male_head_age == 1
	replace male_age_est = 27.5 if male_head_age == 2
	replace male_age_est = 32.5 if male_head_age == 3
	replace male_age_est = 37.5 if male_head_age == 4
	replace male_age_est = 42.5 if male_head_age == 5
	replace male_age_est = 47.5 if male_head_age == 6
	replace male_age_est = 52.5 if male_head_age == 7
	replace male_age_est = 60 if male_head_age == 8
	replace male_age_est = 65 if male_head_age == 9
	
	sum female_age_est if female_age_est != 0 [fweight = projection_factor], detail
	sum male_age_est if male_age_est !=0 [fweight = projection_factor], detail
	*Race
	label define raceLabel 1 "White" 2 "Black"
	label values race raceLabel
	tab race [fweight =  projection_factor]
	*Female head of household education - Nielsen
	gen education = 0
	replace education = 1 if female_head_edu == 3 | female_head_edu == 4
	replace education = 2 if female_head_edu == 5
	replace education = 3 if female_head_edu == 6
	label define educLabel 1 "Highschool" 2 "College" 3 "Higher degree"
	label values education educLabel
	tab education [fweight = projection_factor]
	*hist education [fweight = projection_factor], discrete addlabels percent 
	
	*Percent households with children
	gen children = 0
	replace children = 1 if age_and_presence != 9
	tab children [fweight = projection_factor]
	*Percent households with single mothers - Nielsen

	gen single_mother = 0
	replace single_mother = 1 if single_head == 1 & male_head_age == 0 & ///
		age_and_presence_of_children != 9
	sum single_mother [fweight = projection_factor]	
	*Percent households with married parents - Nielsen
	gen married_parents = 0
	replace married_parents = 1 if marital_status == 1 & age_and_presence_of_children != 9
	sum married_parents [fweight = projection_factor]
	
	
	
	di "*************************************************************************"
	****
	di "***Looking only at the EITC sample - Nielsen"
	keep if federalEITC > 0 & !missing(federalEITC) 
	
	*Average age of male heads of household- EITC only 
	sum female_age_est if female_age_est != 0 [fweight = projection_factor], detail
	sum male_age_est if male_age_est !=0 [fweight = projection_factor], detail
	
	*Race- EITC only - Nielsen
	tab race [fweight =  projection_factor]
	*Female head of household education - EITC only	- Nielsen
	label define educ2label 1 "Gradeschool" 2 "Some high school" ///
		3 "Graduated high school" 4 "Some college" 5 "Graduated college" ///
		6 "Post college"
	label values female_head_educ educ2label
	tab female_head_edu [fweight = projection_factor]
	*hist female_head_edu [fweight = projection_factor], discrete percent ///
		addlabels title("Female head education")
	
	*Percent households with children
	tab children [fweight = projection_factor]
	*Percent households with single mothers - Nielsen
	sum single_mother [fweight = projection_factor]
	*Percent households with married parents - Nielsen
	sum married_parents [fweight = projection_factor]	
	
end

/*---------------------------------------------------------*/
 /* incomePercentiles                  */
 /*--------------------------------------------------------*/
 capture program drop incomePercentiles
 program define incomePercentiles
 syntax[, otherDataDir(string)] 
	/*
	This program generates a dataset of 3-digit zipcodes with categorical
	variables indicating whether the zipcode falls various percentiles of income.
	*/
	
	******Loading zipcode data and income from the Census
	//Population per 5 digit zipcode. 
	import delimited "`otherDataDir'/nhgisData/nhgis0010_csv/nhgis0010_ds172_2010_zcta.csv", clear
	rename name name_e
	rename h7v001 population
	keep name_e population
	tempfile population
	save `population'
	
	//Income data per 5 digit zipcode
	import delimited "`otherDataDir'/nhgisData/nhgis0009_csv/nhgis0009_ds184_20115_2011_zcta.csv", clear
	merge 1:1 name_e using `population', nogen keep(3)
	gen store_zip3 = substr(name_e, 6, 4)
	destring store_zip3, replace
	rename mp1e001 medianIncome	
	
	//Creating population weights
	sort store_zip3
	by store_zip3: egen totalPop = sum(population)
	gen popWeight = population/totalPop

	//Collapsing median income to 3 digit zipcodes
	collapse (mean) medianIncome [pw= popWeight], by(store_zip3)
	
	//getting percentiles
	_pctile medianIncome, percentiles(10(10)90)

	
	gen bottom10 = 1 if medianIncome <=`r(r1)'
	replace bottom10 = 0 if medianIncome > `r(r1)'
	
	gen bottom20 = 1 if medianIncome <=`r(r2)'
	replace bottom20 = 0 if medianIncome > `r(r2)'
	
	gen bottom30 = 1 if medianIncome <=`r(r3)'
	replace bottom30 = 0 if medianIncome > `r(r3)'
	
	gen top30 = 1 if medianIncome >=`r(r7)'
	replace top30 = 0 if medianIncome < `r(r7)'
	
	gen top20 = 1 if medianIncome >=`r(r8)'
	replace top20 = 0 if medianIncome < `r(r8)'

	gen top10 = 1 if medianIncome >=`r(r9)'
	replace top10 = 0 if medianIncome < `r(r9)'
	save "$dataSTATA/incomePercentiles", replace
	
 end
 
 
/*---------------------------------------------------------*/
 /* Takeup rates percentiles                     */
 /*--------------------------------------------------------*/
 capture program drop takeupPercentiles
 program define takeupPercentiles
 syntax[, otherDataDir(string)] 

	******Loading EITC take-up rate data
	**3 digit Zipcta don't match perfectly with 3 digit zipcodes, 97% of them match
	**so I'm not worrying about doing a crosswalk right now. 
	use "`otherDataDir'/EITC_takeup_brookings/zipcta_eitctakeup.dta", clear
	keep if year == 2010
	tostring zipcta, gen (zipctaString)
	replace zipctaString = "0" + zipctaString if strlen(zipctaString) == 4
	replace zipctaString = "00" + zipctaString if strlen(zipctaString) == 3
	gen zipcta3 = substr(zipctaString, 1, 3)
	sort zipcta3	
	by zipcta3: egen totalPop = sum(zip_pop2010)
	gen popWeight = zip_pop2010/totalPop

	//Collapsing takeup rate to 3 digit zipcodes
	collapse (mean) eitctakeup_rate [pw= popWeight], by(zipcta3)
	
	//getting percentiles
	_pctile eitctakeup_rate, percentiles(10(10)90)
	
	gen bottom10eitc = 1 if eitctakeup_rate <=`r(r1)'
	replace bottom10eitc = 0 if eitctakeup_rate > `r(r1)'
	
	gen bottom20eitc = 1 if eitctakeup_rate <=`r(r2)'
	replace bottom20eitc = 0 if eitctakeup_rate > `r(r2)'
	
	gen bottom30eitc = 1 if eitctakeup_rate <=`r(r3)'
	replace bottom30eitc = 0 if eitctakeup_rate > `r(r3)'
	
	gen top30eitc = 1 if eitctakeup_rate >=`r(r7)'
	replace top30eitc = 0 if eitctakeup_rate < `r(r7)'
	
	gen top20eitc = 1 if eitctakeup_rate >=`r(r8)'
	replace top20eitc = 0 if eitctakeup_rate < `r(r8)'

	gen top10eitc = 1 if eitctakeup_rate >=`r(r9)'
	replace top10eitc = 0 if eitctakeup_rate < `r(r9)'
	destring zipcta3, gen(store_zip3)
	tempfile takeup
	save "$dataSTATA/takeupPercentiles", replace
	
end
/*---------------------------------------------------------*/
 /* plotting consumption and prices                        */
 /*--------------------------------------------------------*/
 capture program drop plotGoods
 program define plotGoods
 syntax[, nielsenDir(string) otherDataDir(string) years(string) ///
	productGroup(string) percentSample(integer 5) ///
	figuresDir(string) bottomPercentile(integer 10) topPercentile(integer 10)] 
		
	

	*Iterating through years, product groups, then files within each product group
	//getting the first and last years specified. 
	local counter = 0
	foreach year in `years'{
		local counter `=`counter'+1'
		if `counter' == 1{
			local firstYear = "`year'"
		}
		local yearPresent = "`year'"
	}
	foreach yr in "`years'"{
		*Getting a random sample of stores if we are debugging
		if `percentSample' != 100{
			set seed 2038947
			import delimited "`nielsenDir'/RMS/`yr'/Annual_Files/stores_`yr'.tsv", clear			
			contract store_code_uc
			gen randomNumber = runiform()
			gen percentSample = `percentSample'/100
			drop if randomNumber > percentSample
			drop randomNumber percentSample
			tempfile randomStores
			save `randomStores'			
		}
		foreach group in "`productGroup'"{
			cd "`nielsenDir'/RMS/`yr'/Movement_Files/`group'_`yr'"
			local files: dir . files "*.tsv" 
			local i = 1
			foreach file in `files' { 
				display "`file'"
				import delimited "`file'", clear
				*Only keeping the random sample determined above
				if `percentSample' != 100{
					merge m:1 store_code_uc using `randomStores', nogen keep(3)
				}
				*Appending all modules in the same group together
				*gen fileNumber = `i'
				*local i=`i'+1
				capture append using `allGoods'
				tempfile allGoods
				save `allGoods'
			}

			*Reformatting date
			tostring week_end, replace
			gen week_date = date(week_end, "YMD")
			format week_date %td
			gen month = month(week_date)
			
			*Creating total units sold and price change variables
			gen total_units = units*prmult
			gen unit_price = price/prmult
			gen lnunit_price = log(unit_price)			
			sort store_code_uc upc month week_date
			//Average price excluding Feb, march, December and November
			by store_code_uc upc: egen avg_price_temp = mean(unit_price) 
				///if month != 2 & month != 3 & month != 11 & month!= 12 //TODO: Do we want to exclude any months from the average prices?
			by store_code_uc upc: egen avg_price = max(avg_price_temp)
			gen lnavg_price = log(avg_price)
			gen price_change = lnunit_price - lnavg_price		
				
			                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
			tempfile allGoods
			save `allGoods'
		
			*Merging with stores and zipcode incomes. 
			import delimited "`nielsenDir'/RMS/`yr'/Annual_Files/stores_2014.tsv", clear			
			merge 1:m store_code_uc using `allGoods', keep(3) nogen
			merge m:1 store_zip3 using "$dataSTATA/incomePercentiles", nogen keep(3)
			merge m:1 store_zip3 using "$dataSTATA/takeupPercentiles", nogen keep(3)
			tempfile goodsAndIncome
			save `goodsAndIncome'	
			
			*getting total units sold of appliances by week	
			collapse (sum) total_units (first) month, by(week_date)
			gen lntotal_units = log(total_units)
			reg lntotal_units i.month, robust //is it better to plot coefficients?
			twoway scatter lntotal_units week_date, ///
				title("Number of appliance units purchased") 
			graph export "`figuresDir'/productGroup`productGroup'_years_`yr'_PS`percentSample'.pdf", as(eps) replace
			
			*****Income percentiles*********************
			*Bottom percentile consumption
			use `goodsAndIncome', clear
			collapse (sum) total_units = total_units if bottom`bottomPercentile' == 1, by(week_date)
			gen lntotal_units = log(total_units)
			twoway scatter lntotal_units week_date, ///
				title("Number of appliance units purchased") note("Bottom `bottomPercentile' Percentile") name(bottomCons)
			*graph export "`figuresDir'/productGroup`productGroup'_years_`yr'_lowincome`bottomPercentile'_PS`percentSample'.pdf", replace 
			
			*Top percentle consumption
			use `goodsAndIncome', clear
			collapse (sum) total_units = total_units if top`topPercentile' == 1, by(week_date)
			gen lntotal_units = log(total_units)
			twoway scatter lntotal_units week_date, ///
				title("Number of appliance units purchased") note("Top `topPercentile' Percentile") name(topCons)
			*graph export "`figuresDir'/productGroup`productGroup'_years_`yr'_highincome`topPercentile'_PS`percentSample'.pdf", replace
			
			graph combine bottomCons topCons, title("Consumption in bottom and top percentile of income") col(1) 
			graph export "`figuresDir'/productGroup`productGroup'_years_`yr'_highincome`topPercentile'_lowincome`bottomPercentile'_PS`percentSample'.pdf", replace
			
			*Bottom percentile price changes
			use `goodsAndIncome', clear
			collapse (mean) price_change if bottom`bottomPercentile' == 1, by(week_date)

			twoway scatter price_change week_date, ///
				title("Average percentage change of prices for appliances") note("Bottom `bottomPercentile' Percentile") ///
				ytitle("Percentage price change") xlabel(#13) name(bottomPrice)
			*graph export "`figuresDir'/priceChange_productGroup`productGroup'_years_`yr'_lowincome`bottomPercentile'_PS`percentSample'.pdf", replace 
			
			*Top percentile price changes
			use `goodsAndIncome', clear
			collapse (mean) price_change if top`topPercentile' == 1, by(week_date)
			twoway scatter price_change week_date, ///
				title("Average percentage change of prices for appliances") note("Top `topPercentile' Percentile") ///
				ytitle("Percentage price change") xlabel(#13) name(topPrice)
			*graph export "`figuresDir'/priceChange_productGroup`productGroup'_years_`yr'_highincome`topPercentile'_PS`percentSample'.pdf", replace 
			graph combine bottomPrice topPrice, title("Price changes in top and bottom percentile of income") col(1)
			graph export "`figuresDir'/priceChange_productGroup`productGroup'_years_`yr'_highincome`topPercentile'_lowincome`bottomPercentile'_PS`percentSample'.pdf", replace
			
			********EITC rate percentiles
			*Bottom percentile consumption
			use `goodsAndIncome', clear
			collapse (sum) total_units = total_units if bottom`bottomPercentile'eitc == 1, by(week_date)
			gen lntotal_units = log(total_units)
			twoway scatter lntotal_units week_date, ///
				title("Number of appliance units purchased") ///
				note("Bottom `bottomPercentile' Percentile, eitc take up rates") name(bottomConseitc)
			
			*Top percentle consumption
			use `goodsAndIncome', clear
			collapse (sum) total_units = total_units if top`topPercentile'eitc == 1, by(week_date)
			gen lntotal_units = log(total_units)
			twoway scatter lntotal_units week_date, ///
				title("Number of appliance units purchased") ///
				note("Top `topPercentile' Percentile by eitc takeup rates") name(topConseitc)
			
			graph combine topConseitc bottomConseitc, title("Consumption in bottom and top percentile of eitc takeup") col(1) 
			graph export "`figuresDir'/productGroup`productGroup'_years_`yr'_higheitc`topPercentile'_loweitc`bottomPercentile'_PS`percentSample'.pdf", replace
			
			*Bottom percentile price changes
			use `goodsAndIncome', clear
			collapse (mean) price_change if bottom`bottomPercentile'eitc == 1, by(week_date)

			twoway scatter price_change week_date, ///
				title("Average percentage change of prices for appliances") ///
				note("Bottom `bottomPercentile' Percentile eitc take up rate") ///
				ytitle("Percentage price change") xlabel(#13) name(bottomPriceeitc)
			*graph export "`figuresDir'/priceChange_productGroup`productGroup'_years_`yr'_lowincome`bottomPercentile'_PS`percentSample'.pdf", replace 
			
			*Top percentile price changes
			use `goodsAndIncome', clear
			collapse (mean) price_change if top`topPercentile'eitc == 1, by(week_date)
			twoway scatter price_change week_date, ///
				title("Average percentage change of prices for appliances") ///
				note("Top `topPercentile' Percentile. Eitc take up rate") ///
				ytitle("Percentage price change") xlabel(#13) name(topPriceeitc)
			*graph export "`figuresDir'/priceChange_productGroup`productGroup'_years_`yr'_highincome`topPercentile'_PS`percentSample'.pdf", replace 
			graph combine topPriceeitc bottomPriceeitc, title("Price changes in top and bottom percentile of eitc takeup") col(1)
			graph export "`figuresDir'/priceChange_productGroup`productGroup'_years_`yr'_higheitc`topPercentile'_loweitc`bottomPercentile'_PS`percentSample'.pdf", replace
			
		}
	}
	
	
 end
 
 /*---------------------------------------------------------*/
 /* Creating a random sample of scanner data         */
 /*--------------------------------------------------------*/
 capture program drop randomSampleScanner
 program define randomSampleScanner
 syntax[, nielsenDir(string) otherDataDir(string) years(string) ///
	productGroup(string) percentSample(integer 5)]
	
		foreach yr in `years'{
		foreach group in `productGroup'{
			cd "`nielsenDir'/RMS/`yr'/Movement_Files/`group'_`yr'"
			local files: dir . files "*.tsv" 
			local i = 1
			foreach file in `files' { 
				display "`file'"
				import delimited "`file'", clear				
				*taking a random sample
				if `percentSample' != 100{
					set seed 2038947	
					gen randomNumber = runiform()
					gen percentSample = `percentSample'/100
					drop if randomNumber > percentSample
					drop randomNumber percentSample
				}
				compress
				local fileName=regexr("`file'", ".tsv","")
				di "`fileName'"
			
				save "`otherDataDir'/scannerRandomSamples/`yr'/`group'_`fileName'_percent`percentSample'", replace
				
				}
			}
		}
		

 end
 
 
/*---------------------------------------------------------*/
 /* Summary statistics on durable goods                    */
 /*--------------------------------------------------------*/
 capture program drop sumStatsDurables
 program define sumStatsDurables
 syntax[, nielsenDir(string) otherDataDir(string) years(string) ///
	productGroup(string) percentSample(integer 5) ///
	bottomPercentile(integer 10) topPercentile(integer 10)]
	
	*Iterating through years, product groups, then files within each product group
	//getting the first and last years specified. 
	local counter = 0
	foreach year in `years'{
		local counter `=`counter'+1'
		if `counter' == 1{
			local firstYear = "`year'"
		}
		local yearPresent = "`year'"
	}
	foreach yr in `years'{
		*Getting a random sample of stores if we are debugging
		if `percentSample' != 100{
			set seed 2038947
			import delimited "`nielsenDir'/RMS/`yr'/Annual_Files/stores_`yr'.tsv", clear			
			contract store_code_uc
			gen randomNumber = runiform()
			gen percentSample = `percentSample'/100
			drop if randomNumber > percentSample
			drop randomNumber percentSample _freq
			tempfile randomStores
			save `randomStores'			
		}
		
		foreach group in `productGroup'{
			*Creating a dataset that will contain the summaryStats
			clear
			set obs 1
			gen dummy = 1
			tempfile sumStats
			save `sumStats', replace
			
			*iterating over all the modules in the group
			cd "`nielsenDir'/RMS/`yr'/Movement_Files/`group'_`yr'"
			local files: dir . files "*.tsv" 
			local i = 1
			foreach file in `files' { 
				display "`file'"
				import delimited "`file'", clear
				
				*Only keeping the random sample determined above
				if `percentSample' != 100{
					merge m:1 store_code_uc using `randomStores', nogen keep(3)
				}
				
				*Average number of goods purchased each week in a zipcode
				preserve	
					import delimited "`nielsenDir'/RMS/`yr'/Annual_Files/stores_`yr'.tsv", clear
					tempfile stores
					save `stores'
				restore
				merge m:1 store_code_uc using `stores', keep(3) nogen
				egen total_units = total(units*prmult)
				sum total_units
				local total_units = r(mean)
				bys week_end: gen index = _n
				bys store_zip3: gen index2 = _n
				count if index ==  1
				local num_wks = r(N)
				count if index2 == 1
				local num_zip = r(N)
				local avg_units = `total_units'/`num_wks'/`num_zip'
				drop index*
				
				*Appending all modules in the same group together
				*gen fileNumber = `i'
				*local i=`i'+1
				capture append using `allGoods'
				tempfile allGoods
				save `allGoods'
				
				*Inputting average number of goods into results dataset				
				use "`sumStats'", clear
				local fileName=regexr("`file'", ".tsv","")
				di "`fileName'"
				gen v`fileName' = `avg_units'
				save "`sumStats'", replace
				
			}	
	
			*Calculating the number of goods a week for a group (eg Household appliances)
			use `allGoods', clear
			*Reformatting date
			tostring week_end, replace
			gen week_date = date(week_end, "YMD")
			format week_date %td
			gen month = month(week_date)
			
			*Creating total units sold 
			gen week_units = units*prmult	                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
	
		
			*Merging with stores and zipcode incomes. 	
			merge m:1 store_zip3 using "$dataSTATA/incomePercentiles", nogen keep(3)
			merge m:1 store_zip3 using "$dataSTATA/takeupPercentiles", nogen keep(3)
			tempfile goodsAndIncome
			save `goodsAndIncome'	
			
			*getting average number of appliances in a zipcode every week	
			bys store_zip3: gen index2 = _n
			count if index2 ==  1
			local numZip = r(N)
			collapse (sum) week_units (first) month, by(week_date)
			gen zip_wk_units = week_units/`numZip'
			export excel "$tables/sumStats_yr`yr'_gr`group'_ps`percentSample'", ///
				firstrow(variables) sheet("groupWeeklyStats", replace)
				
			*Exporting module summary statistics
			use `sumStats', clear
			gen description = "The average number of goods sold per week in a 3-digit zipcode area"
			gen group = "`group'"

			export excel "$tables/sumStats_yr`yr'_gr`group'_ps`percentSample'", ///
				firstrow(variables) sheet("Module stats", replace)
	
		}
	}
 end
/*---------------------------------------------------------*/
 /* Run Main Program                                       */
 /*--------------------------------------------------------*/


main
//main program
log close
exit
