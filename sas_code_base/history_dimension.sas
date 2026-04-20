%macro history_dimension;

/* This macro is not complete as functionality of dimension level history is not completely defined by requitrements */

data _null_;
put "ERROR: Dimension level history processing not complete";
abort;
run;

/* 1. Get existing active data and update data for comparison to create new active and incative rows */ 
	proc sort data=&target. out=active_data; by &dimfields.; run;
	proc sort data=&source. out=update_data; by &dimfields.; run;

	data	new_active(where=(&datevar2. eq .))
			new_inactive(where=(&datevar2. ne .));
	merge	&target.(in=a) update_data(in=u);
	by		&dimfields.;

	if		a eq 1 and u ne 1	then &datevar2.=&tilanne_pv.; /* Active row but not found in latest data -> set stop date to current */
	if		a ne 1 and u eq 1	then &datevar1.=&tilanne_pv.; /* Row in latest data but not in active data -> set start date to current*/

	run;

/* 2. Save and halt audit for the duration of batch operations on active data*/
	proc append base=&library..&tablename._a(alter="&alterpass." write="&alterpass.")  data=&library..&tablename.(type=audit); run;
	proc datasets nolist library=&library.; audit &tablename.(alter="&alterpass."); terminate; run; quit;

/* 3. Save new active data */
	proc sort data=new_active out=&target.(alter="&alterpass.") presorted; by &dimfields.; run;

/* 4. Create indexes for active data table */
	data _null_;
	set indexcommands nobs=_nmax;
	filename make_ind;
	if _n_=1 then put "proc datasets nolist library=&library. ;" ;
	if _n_=1 then put "modify &tablename.(alter="&alterpass.") ;" ;
	put creator;
	if _n_=_nmax then put "run; quit;" ;
	run;
	%include make_ind;

/* 5. Initialize audit for active data table */
	proc datasets nolist library=&library.; audit &tablename.(alter="&alterpass."); initiate; run; quit;


/* 6. Save and halt audit for the duration of batch operations on inactive data*/
	proc append base=&library..&tablename._na_a(alter="&alterpass." write="&alterpass.")  data=&library..&tablename._na(type=audit); run;
	proc datasets nolist library=&library.; audit &tablename._na(alter="&alterpass."); terminate; run; quit;

/* 7. Drop indexes on incative data */
	data _null_;
	set indexcommands nobs=_nmax;
	file drop_ind;
	if _n_=1 then put "proc datasets nolist library=&library. ;" ;
	if _n_=1 then put "modify &tablename._na(alter="&alterpass.") ;" ;
	put deletor;
	if _n_=_nmax then put "run; quit;" ;
	run;
	%include drop_ind;

/* 8. Add new incative rows */
	proc append base=&library..&tablename._na data=new_inactive; run;


/* 9. Delete inactive rows not on the list of dates to save */
	proc sql;
	delete
	from	&library..&table._na as a
	where	&datevar2. is not null
	and		not exists	(
						select	1
						from	history_dates_2 as b
						where	b.history_date < a.&datevar2.
						and		b.history_date > a.&datevar1.
						)
	;
	quit;

/* 10. Generate indexes for inactive data */
	data _null_;
	set indexcommands nobs=_nmax;
	filename make_ind;
	if _n_=1 then put "proc datasets nolist library=work ;" ;
	if _n_=1 then put "modify &tablename._na ;" ;
	put creator;
	if _n_=_nmax then put "run; quit;" ;
	run;
	%include make_ind;


/* 11. Initialize audit for inactive data table */
	proc datasets nolist library=&library.; audit &tablename._&tilanne_pv_char.(alter="&alterpass."); initiate; run; quit;

/* 12. Delete temporary datasets */
	proc datasets library=work;
	delete	active_data;
	delete	update_data;
	delete	new_inactive;
	delete	new_active;
	run;
	quit;



