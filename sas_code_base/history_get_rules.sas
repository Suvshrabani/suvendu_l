%macro history_get_rules;

/* Get history rules and check that they can be enforced */

/* Read rule into macro variables */
proc sql noprint;
select	distinct count(*), type, datevar1, datevar2, active_d, active_m, active_q, active_y
into	:counter,:type,:datevar1,:datevar2,:active_d,:active_m,:active_q,:active_y
from	c_ctrl.history_rules
where	upcase(library)=upcase("&library.")
and		upcase(tablename)=upcase("&tablename.")
;
quit;

/* Check rule internal integrity */
data _null_;
  if &counter. ne 1 then do;
    put "ERROR: &counter. rules found for &target. Need exactly one!" ;
    abort abend;
  end;
  if "&type."="l" and (strip("&datevar1.") ne "" or strip("&datevar2.") ne "") then do;
    put "ERROR: History rules type '&type.' indicates separate tables in library, but datevars have been defined";
    abort abend;
  end;
  if "&type."="t" and (strip("&datevar1.") eq "" or strip("&datevar2.") ne "") then do;
    put "ERROR: History rules type '&type.' indicates single table, but datevar1 is missing or datevar2 have been defined";
    abort abend;
  end;
  if "&type."="d" and (strip("&datevar1.") eq "" or strip("&datevar2.") eq "")  then do;
    put "ERROR: History rules type '&type.' indicates scd2, but a datevar is missing";
    abort abend;
  end;
run;

/* Check that datevars exist if necessary */
%if (&datevar1. ne ) %then %do;
    %let dvs1 =.;
    proc contents noprint data=&source. out=varlist(where=(name="&datevar1.") keep=name); run;
    proc sql noprint; select count(*) into :dvs1 from varlist; quit;
    data _null_;
      if (&dvs1. ne 1) then do;
        putx=COMPBL("ERROR: Datevar1 has been defined as &datevar1. but the variable is not found in the source table.");
        put putx;
      abort abend;
      end;
    run ;
%end;

%if (&datevar2. ne ) %then %do;
    %let dvs2 =.;
    proc contents noprint data=&source. out=varlist(where=(name="&datevar2.") keep=name); run;
    proc sql noprint; select count(*) into :dvs2 from varlist; quit;
    data _null_;
      if (&dvs2. ne 1) then do;
        putx=COMPBL("ERROR: Datevar2 has been defined as &datevar2. but the variable is not found in the source table.");
        put putx;
      abort abend;
      end;
    run ;
%end;

%mend;
%put NOTE: Macro history_get_rules created ;
