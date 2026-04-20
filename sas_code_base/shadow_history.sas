%macro shadow(source, target, metapath)

%local	shadow_keys;

%read_index_metadata;

%let	shadow_keys=;

proc sql;
select	index_keys
into	:shadow_keys
from	indexcommands;
where	strip(index_name)='primary_index';
run;

%let library=%sysfunc(scan(&target.,1,'.'));
%let tablename=%sysfunc(scan(&target.,2,'.'));

proc sql;
select	 type, datevar1, datevar2, active_d, active_m, active_q, active_y
into	:type,:datevar1,:datevar2,:active_d,:active_m,:active_q,:active_y	
from	c_ctrl.history_rules
where	upcase(library)=upcase("&library.")
and		upcase(tablename)=upcase("&tablename.")
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
run;
