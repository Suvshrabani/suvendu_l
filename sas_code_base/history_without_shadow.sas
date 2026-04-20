%macro history_without_shadow(source=,target=,metapath=) ;
%local library tablename type datevar1 datevar2 active_d active_m active_q active_y;
%let library=%sysfunc(scan(&target.,1,'.')) ;
%let tablename=%sysfunc(scan(&target.,2,'.')) ;

/* Passwords can be max 8 characters long */

%let alterpass=%sysfunc(substr(&alterpass.,1,8));

/* Get history rules into local macro variables */
%history_get_rules;

/* Get history dates */
%history_dates_by_calendar;

filename drop_ind temp;
filename make_ind temp;


%if "&type."="t" %then %do;
	%history_without_shadow_table;
%end; 



/* Delete temp tables */
proc datasets library=work nolist;
delete history_dates_1;
delete history_dates_2;
run; quit; 

filename drop_ind clear;
filename make_ind clear;

%mend;

