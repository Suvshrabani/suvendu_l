%macro history(source=,target=,metapath=) ;
%local library tablename type datevar1 datevar2 active_d active_m active_q active_y lib_prx;
%let library=%sysfunc(scan(&target.,1,'.')) ;
%let tablename=%sysfunc(scan(&target.,2,'.')) ;
%let lib_prx=%sysfunc(scan(&library.,1,'_')) ;  /* add by ML 21062021 to seperate dw and dwh ctrl tables */

data _null_;
test="&lib_prx";
test1=reverse(test); 
if lowcase(substr(test1,1,1))='h' then call symput('lib_prx','dwh');
else call symput('lib_prx', 'dw');
run;


/* Passwords can be max 8 characters long */

%let alterpass=%sysfunc(substr(&alterpass.,1,8));

/* Get history rules into local macro variables */
%history_get_rules;

/* Get history dates */
%history_dates_by_calendar;

filename drop_ind temp;
filename make_ind temp;

/* Perform actual history clear and load according to the type */
%if "&type."="l" %then %do;
	%history_library;
%end;

%if "&type."="t" %then %do;
	%history_table;
%end; 

%if "&type."="d" %then %do;
	%history_dimension;
%end;

/* Delete temp tables */
proc datasets library=work nolist;
delete history_dates_1;
delete history_dates_2;
run; quit; 

filename drop_ind clear;
filename make_ind clear;

%mend;

