%macro history_table;

%local maxdate;
/*	1. Normalize initial status: original and shadow tables and audit data for both must exist before entering the actual history macro */
%if ^%sysfunc(exist(&library..&tablename.,DATA)) %then %do;
	proc append base=&library..&tablename. data=&source.(obs=0); run;
%end;
%if ^%sysfunc(exist(&library..&tablename.,AUDIT)) %then %do;
	proc datasets nolist library=&library.; audit &tablename.(alter=&alterpass.); initiate; run; quit;
%end;
%if ^%sysfunc(exist(&library..&tablename._s)) %then %do;
	proc append base=&library..&tablename._s data=&source.(obs=0); run;
%end;
%if ^%sysfunc(exist(&library..&tablename._s,AUDIT)) %then %do;
	proc datasets nolist library=&library.; audit &tablename._s(alter=&alterpass.); initiate; run; quit;
%end;               
%if ^%sysfunc(exist(&library..&tablename._a))	%then %do; proc append base=&library..&tablename._a data=&source.(obs=0); run; %end;
%if ^%sysfunc(exist(&library..&tablename._s_a))	%then %do; proc append base=&library..&tablename._s_a data=&source.(obs=0); run; %end;


/*	2. Store audit data for the original and shadow table before terminating audit for the duration of history manipulation. */

	/* 2a Use the unify datastructure to create a combination of the existing audit report and the audit log of the table */
	%unify_datastructure(input_data_1=&library..&tablename._a,input_data_2=&library..&tablename.(type=audit),output_data=audit_result);
	%unify_datastructure(input_data_1=&library..&tablename._s_a,input_data_2=&library..&tablename._s(type=audit),output_data=audit_result_s);

	/* 2b Stored audit results are protected with the same password which allows data structure change of non audit data */
	data &library..&tablename._a(alter=&alterpass. write=&alterpass. );
	set audit_result;
	run;
	data &library..&tablename._s_a(alter=&alterpass. write=&alterpass.);
	set audit_result_s;
	run;

	/* 2c Terminate audit */
	proc datasets nolist library=&library.; audit &tablename.(alter=&alterpass.); terminate; run; quit;
	proc datasets nolist library=&library.; audit &tablename._s(alter=&alterpass.); terminate; run; quit;


/* 3. Check the history preservation period */
	%let history_dates=;
	proc sql noprint;
	select	strip(put(history_date,8.))
	into	:history_dates separated by ','
	from	history_dates_2
	;
	quit;


/*	4. Generate a unified structure for the original and shadow tables */
	
	/* 4a Unify source table with those stored history table rows that fit in the history preservation period*/
	%unify_datastructure(input_data_1=&library..&tablename.(where=(&datevar1. in (&history_dates.) or &datevar1. gt &active_date.)),input_data_2=&source.(where=(&datevar1. = &active_date.)),output_data=&library..&tablename.(alter=&alterpass.));

	/* 4b unify source table structure, but no data with the shadow table */

	%unify_datastructure(input_data_1=&library..&tablename._s,input_data_2=&source.(obs=0),output_data=&library..&tablename._s(alter=&alterpass.));

/* 5. Get index information from metadata and add indexes for table and shadow table */
	%read_index_metadata(metapath=&metapath.);

	%let has_primary_index=0;
	proc sql noprint ; select count(*) into :has_primary_index from metaindex where lowcase(index_name)='primary_index' ; quit ;
	%put NOTE: has_primary_index=&has_primary_index;

	data _null_;
	if &has_primary_index ne 1 then do;
	  file log ;
	  put "ERROR: Table &metapath has no primary_index." ;
	  abort abend;
	end;


	/* 5a Create indexes for table */
	filename make_ind temp;

	data _null_;
	set metaindex nobs=_nmax;
        * Temporarily force unique primary_index ;
	if is_uniq='1' or lowcase(index_name)='primary_index' then uniqopt=' /unique'; else uniqopt=' ' ;
        * Later require unique primary_index ;
	if is_uniq ne '1' and lowcase(index_name)='primary_index' then do ;
	  file log ;
	  put "ERROR: Table &metapath. has primary_index, but it is not unique." ;
	  abort abend;
	end;
	file make_ind ;
	if _n_=1 then put "proc datasets nolist library=&library. ;" ;
	if _n_=1 then put "modify &tablename.(alter=&alterpass.) ;" ;
	if strip(index_name)=strip(index_keys)
		then do;
		put "index create " index_name uniqopt ";" ;
		end;
		
		else do;
		put "index create " index_name "=(" index_keys ")" uniqopt ";" ;
		end;

	if _n_=_nmax then put "run; quit;" ;
	run;
/*	%include make_ind; */


	/* 5b Create indexes for shadow table */
	data _null_;
	set metaindex nobs=_nmax;
        * Temporarily force unique primary_index ;
	if is_uniq='1' or lowcase(index_name)='primary_index' then uniqopt=' /unique nomiss'; else uniqopt=' ' ;
	file make_ind ;
	if _n_=1 then put "proc datasets nolist library=&library. ;" ;
	if _n_=1 then put "modify &tablename._s(alter=&alterpass.) ;" ;
	if strip(index_name)=strip(index_keys)
		then do;
		put "index create " index_name uniqopt ";" ;
		end;
		
		else do;
		put "index create " index_name "=(" index_keys ")" uniqopt ";" ;
		end;

	if _n_=_nmax then put "run; quit;" ;
	run;
	%include make_ind;


/* 6. Restart audit for table and shadow table */
	proc datasets nolist library=&library.; audit &tablename.(alter=&alterpass.); initiate; run; quit;
	proc datasets nolist library=&library.; audit &tablename._s(alter=&alterpass.); initiate; run; quit;


/* 7. Store data field information for column level cleansup */
	proc contents noprint data=&source. out=fields_1(keep=name) ; run;
	data fields_2;
		format active_date IS8601DA. library $8. tablename $32.;
		set fields_1;
		active_date=&active_date.;
		library="&library.";
		tablename="&tablename.";
	run;
       
	proc sql noprint ;
		delete from dw_ctrl.datafields
		where library="&library."
			and tablename="&tablename."
			and active_date not in (&history_dates.);
	quit;

	proc append base=dw_ctrl.datafields data=fields_2; run;

/*	8. Remove _L and _H views if they exists and recreate (_L with most recent date) */
    proc sql noprint ;
    create table __infdat as 
      select distinct max(&datevar1.) as infdat
        from &library..&tablename.
        where &datevar1. le %sysfunc(today())
      union 
	  select distinct max(&datevar1.) as infdat
        from &library..&tablename._S
        where &datevar1. le %sysfunc(today())
	  ;
      select distinct max(infdat) into :maxdate
        from __infdat where infdat ne .
	  ;
    quit;
	
	proc sql noprint ;
	select trim(index_keys) into :shadow_keys
	  from metaindex 
	  where strip(index_name)='primary_index';
	quit;

	* View for all rows ;
	%if ^%sysfunc(exist(&library..&tablename._h,VIEW)) %then %do;
	  proc sql; drop view &library..&tablename._h; quit; 
	%end;
	data	&library..&tablename._h / view= &library..&tablename._h;
	merge	&library..&tablename. &library..&tablename._s;
	by		&shadow_keys.;
	run;

	* View for the latest rows (not in the future) ;
	%if ^%sysfunc(exist(&library..&tablename._l,VIEW)) %then %do;
	  proc sql; drop view &library..&tablename._l; quit; 
	%end;
	proc sql;
	create view	&library..&tablename._l as
	select		*
	from		&library..&tablename._h
	having		&datevar1.=MAX(&datevar1.)
	;
	quit;
/*	9. Add _S, _H and _L into metadata if not exist */	

data _null_ ;
  folder0="&metapath.";
  folder=substr(folder0,1,find(folder0,'/',-200)-1);
  call symput('metapat_',folder);
run ;

proc metalib;
	omr(library="&library.");
	folder="&metapat_.";
	update_rule=(delete);
	prefix="&library..";
	select
		(
		"&tablename._l"
		"&tablename._h"
		"&tablename._s"
		)
	;
run;
%mend;
