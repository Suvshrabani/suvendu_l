***********************************;
*macro code_converter_calculate    ;
*								   ;
*Usage: 						   ;
* Used to convert data mart values ;
* into Anacredit codevalues        ;
***********************************;
%macro code_converter_calculate(source, table);
	%*Set the calculation order;
	%put table: &table.;

    data &table.; set &source.; run;

	proc sort data=cc_for_&table. 
        out=temp1;
		by target_column bank_id descending internal_value_prio ;
	run;

	data temp2; set temp1; row=_n_; run;

	%let laps=0;
	data _null_; set temp2;
		call symputx('laps', max(row));
	run;
	%put laps: &laps.;
	%if &laps.>0 %then %do;
		%do i=1 %to &laps.;

			data _null_; set temp2;
				if row=&i. then  call symput("expression",internal_value_clause_final);
			run;

			data &table.; set &table.;
				&expression.;
			run;
		%end;
	%end;
%mend;
