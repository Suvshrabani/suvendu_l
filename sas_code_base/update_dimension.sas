%macro update_dimension;
proc sort data=&target. out=active_data; by &dimfields.; run;
proc sort data=&source. out=update_data; by &dimfields.; run;

data	new_active(where=(&datevar2. eq .))
		new_inactive(where=(&datevar2. ne .));
merge	&target.(in=a) update_data(in=u);
by		&dimfields.;

if		a eq 1 and u ne 1	then &datevar2.=&tilanne_pv.; /* Active row but not found in latest data -> set stop date to current */
if		a ne 1 and u eq 1	then &datevar1.=&tilanne_pv.; /* Row in latest data but not in active data -> set start date to current*/

run;


proc sort data=new_active out=&target. presorted; by &dimfields.; run;
proc append base=&target._na data=new_inactive; run;

proc datasets library=work;
delete	active_data;
delete	update_data;
delete	new_inactive;
delete	new_active;
run;
quit;
%mend;
