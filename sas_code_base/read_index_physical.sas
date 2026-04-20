%macro read_index_physical(library, tablename);

proc contents data=&library..&tablename. out2=temp_1(drop=libname member numvars type recreate message ondelete onupdate ref where inactive idxunique idxnomiss icown numvals upercmx uperc msgtype ); run;

proc sort data=temp_1; by name; run;

proc transpose data=temp_1 out=temp_2(where=(_NAME_ ne 'Name' and strip(COL1) ne '') drop= _LABEL_);
by name;
var _all_;
run;

proc sort data=temp_2; by name; run;

data physindex;
format index_keys $1024.;
retain index_keys;
set temp_2;
by name;
rename name=index_name;
drop _NAME_ COL1;

if first.name then index_keys='';
index_keys=strip(index_keys) || ' ' || strip(COL1);
if last.name then output;

run;

proc datasets library=work;
delete temp_1;
delete temp_2;
run; quit;

%mend;
