%macro history_library;

/* This macro is not complete as functionality of library level history is not completely defined by requitrements */

data _null_;
put "ERROR: Library level history processing not complete";
abort;
run;

/* 1. List all timestamped datasets belonging to this table */

ods output members=setlist_1;
proc datasets library=&library. memtype=data; run; quit;
ods output close;

data	setlist_2;
set		setlist_1;
where	memtype="DATA" and index(upcase(name),upcase("&tablename."))=1 and length(name)=length("&tablename.")+9;
date_char=substr(name,length("&tablename.")+2);
date=input(date_char,ND8601DA.);
keep name date;
run;

proc sql;
create table	setlist_3 as
select			name
from			setlist_2
where			date is not null
and				date not in	(
							select distinct date
							from history_dates_2
							)
order by		name;
;
quit;

/* 2. Delete timestamped datasets not in the list of dates to keep */
data	_null_;
set		setlist_3;
by		name;

if first.name then call execute("proc datasets library=&library. nolist;");
call execute("delete " || name ||"(alter="&alterpass.");");
if last.name then call execute("run; quit;");

run;

/* 3. Load the data into a new timestamped dataset and a 0 row dummy set for DIS without timestamp */
data	&target.(where=(1=0) alter="&alterpass.")
		&target._&tilanne_pv_char.(alter="&alterpass.");
set		&source.;
run;

/* 4. Begin audit of the generated dataset */
proc datasets nolist library=&library.; audit &tablename._&tilanne_pv_char.(alter="&alterpass."); initiate; run; quit;

/* 5. Generate index for the timestamped data */
data _null_;
set indexcommands nobs=_nmax;
file make_ind;
if _n_=1 then put "proc datasets nolist library=work ;" ;
if _n_=1 then put "modify &tablename._&tilanne_pv_char.(alter="&alterpass.") ;" ;
put creator;
if _n_=_nmax then put "run; quit;" ;
run;
%include make_ind;

/* 6. Delete temporary datasets */
proc datasets library=work nolist;
delete setlist_1;
delete setlist_2;
delete setlist_3;
run; quit;
%mend;
