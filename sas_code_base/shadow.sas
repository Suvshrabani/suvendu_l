/*
  Modifications
  %local shadow_keys shadow_lib shadow_tbl; 
  &library>>&shadow_lib, &tablename>>&shadow_tbl
  %let shadow_lib=%sysfunc(scan(&source.,1,'.')) ;
  %let shadow_tbl=%sysfunc(scan(&source.,2,'.')) ;
from	indexcommands; >>from metaindex;
*/
%macro shadow(source, target, metapath);

  %local shadow_keys shadow_lib shadow_tbl; * reversed ;
  %let shadow_lib=%sysfunc(scan(&source.,1,'.')) ;
  %let shadow_tbl=%sysfunc(scan(&source.,2,'.')) ;

%read_index_metadata(metapath=&metapath.);

%let shadow_keys=;

proc sql noprint ;
select trim(index_keys) into :shadow_keys
  from metaindex 
  where strip(index_name)='primary_index';
quit;

%put NOTE: index_keys of primary_index: &shadow_keys ;

proc sql noprint ;
select	 type, datevar1, datevar2, active_d, active_m, active_q, active_y
into	:type,:datevar1,:datevar2,:active_d,:active_m,:active_q,:active_y	
from	c_ctrl.history_rules
where	upcase(library)=upcase("&shadow_lib.")
and		upcase(tablename)=upcase("&shadow_tbl.")
;
quit;

data	_null_;
o=exist("&source.");
s=exist("&source._s");
if		o ne 1
		then do;
		put "ERROR: Original table does not exist";
		abort abend;
		end;
if		s ne 1
		then do;
		put "ERROR: Shadow table does not exist";
		abort abend;
		end;
if		strip("&shadow_keys.")=''
		then do;
		put "ERROR: Table has no primary_index keys";
		abort abend;
		end;
run;

data	&target.;
merge	&source. &source._s;
by		&shadow_keys.;
where	&datevar1.=&active_date.;
run;

%mend;
%put NOTE: Macro shadow output.;

