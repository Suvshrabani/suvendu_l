/*This macro copies itrm shadow table rows from active date into resu shadow tables*/
%macro copy_itrm_shadow_to_resu(table, key_variables);	
	/*If tables does not exist - abort*/
	data	_null_;
	r=exist("mac_resu.&table._s");
	s=exist("mac_isar.&table._s");

	if		r ne 1
			then do;
			put "ERROR: Resu shadow table does not exist";
			abort abend;
			end;
			
	if		s ne 1
			then do;
			put "ERROR: Itrm shadow table does not exist";
			abort abend;
			end;
			
	if		strip("&key_variables.")=''
			then do;
			put "ERROR: Table has no primary_index keys";
			abort abend;
			end;
	run;
	
	/*Merge itrm shadow table with resu shadow table*/
	data mac_resu.&table._s (alter=&alterpass.);
		merge mac_resu.&table._s (in=a) mac_isar.&table._s (in=b where=(information_date=&active_date.));
		by &key_variables.;
		if b then loaded_dt = datetime();
	run;
	
	/*recreate index for shadow*/
	proc datasets lib = mac_resu nolist; 
		modify &table._s(ALTER=&alterpass ); 
		index create primary_index = (&key_variables.)
         /unique;
	quit; 


	/*Empty itrm shadow*/
	%put Empty itrm shadow table &table._s;
	proc sql; delete * from  mac_isar.&table._s where information_date=&active_date; quit;
	

%mend;


/*List of mac_resu/mac_isar tables*/
proc sort data=mac_ctrl.ctrl_itrm_tables (where=(type="resu")) out=find_max; by type; run;
data _null_;
	set find_max;
	find_max= max(0,_n_);
	call symputx('maximi', find_max);
run;
%put maximi: &maximi.;

/*Loop all resu tables and make the shadow copy*/
data _null_;
	set find_max ;
	if type="resu";
	do i = 1 to &maximi.;
		put i;
		if _n_ = i then do;
			put "table_name_itrm: " table_name_itrm;
			put "itrm_primary_key: " itrm_primary_key;
			call execute('%copy_itrm_shadow_to_resu('!!table_name_itrm!!', '!!itrm_primary_key!!');');
		end;
	end;	
run;
