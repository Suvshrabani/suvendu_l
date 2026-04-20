%macro cleanse_update_format(id);
data _null_;
set c_cleans.formatlist;
where id=&id.;
call symput('targetlib',scan(strip(argument),1,'.'));
call symput('targetset',scan(strip(argument),2,'.'));
call symput('targetfield',scan(strip(argument),3,'.'));
call symput('checktime',checktime);
run;

%put &checktime.;

ods output attributes=target_attributes;
proc contents data=&targetlib..&targetset. out=members(where=(upcase(strip(name))=upcase(strip("&targetfield.")))); run;
ods output close;

data _null_;
set target_attributes;
where label1='Last Modified';
call symput('updatetime',nValue1);
run;

data _null_;
set members;
if type=2
	then fmtname='$F' || put(&id.,8.) || 'X';
	else fmtname='F' || put(&id.,8.) || 'X';
run;

%if &checktime. = . or &checktime. < &updatetime.
	%then %do;

	data inputdata1;
	set &targetlib..&targetset.;
	hlo=' ';
	start=&targetfield.;
	end=&targetfield.;
	label=0;
	coltype='N';
	fmtname="&fmtname.";
	keep start end label hlo coltype fmtname;
	run;

	proc sort data=inputdata1 out=inputdata2 nodupkey; by start; run;

	proc sql; insert into inputdata2 (start, end, label, hlo, coltype, fmtname) values (., ., 1, 'O', 'N', "&fmtname."); quit;

	proc format library=c_cleans cntlin=inputdata2; run;

	%end;
%mend;
