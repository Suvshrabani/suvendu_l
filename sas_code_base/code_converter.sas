%macro code_converter(source=,target=,output=,keep=) ;
%local library tablename;
/* Macro variables not in use
%let library=%sysfunc(scan(&target.,1,'.')) ;
%let tablename=%sysfunc(scan(&target.,2,'.')) ;
*/

%let target_table = %sysfunc(strip(%sysfunc(lowcase(&target))));


/* Get rules from parameter into work table */
%code_converter_prepare(&target_table.);

/* Get history dates */
%code_converter_calculate(&source., &target_table.);

/*Keep selected fields only*/
%put fields to stay: &keep.;
data &output. (keep = &keep.); 
	set &target.;
run;

/* Delete temp tables */
proc datasets library=work nolist;
delete temp1;
delete temp2;
run; quit; 


%mend;

