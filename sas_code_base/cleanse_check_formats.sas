%macro cleanse_check_formats;
/* Check if any unknown formats have been introduced and add them to the cleanse list*/

%if ^%sysfunc(exist(c_cleans.formatlist)) = 1
	%then %do;
	proc sql;
	create table c_cleans.formatlist
	(
	checktime num format=IS8601DT.,
	argument char(74) format=$74.,
	id num format=8.
	);
	quit;
	%end;

proc sql;
	create table missing_formats as
	select argument from cleanse_rules1 where strip(rule)='dim'
	except
	select argument from c_cleans.formatlist
	;
quit;

%let max_format_id=0;
proc sql;
	select max(id)
	into :max_format_id
	from c_cleans.formatlist
	;
quit;

data new_formats;
	format checktime IS8601DT. ;
	retain max_format_id;
	max_format_id=&max_format_id.;
	if max_format_id=. then max_format_id=0;

	set missing_formats;
	id=_n_ + max_format_id;
	checktime=.;
	drop max_format_id;
run;

proc append base=c_cleans.formatlist data=new_formats; run;

/* Check if any of the formats is older than the data it's based on and update when needed */
proc sql;
	create table formatcheck as
	select id
	from c_cleans.formatlist
	inner join cleanse_rules1
	on formatlist.argument=cleanse_rules1.argument
	where strip(rule)='dim'
	;
quit;

data _null_;
	set formatcheck;
	call execute('%update_format(' || formatid || ');');
run;
%mend;
