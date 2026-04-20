%macro history_dates_by_calendar;
data history_dates_1;
format active_date history_date IS8601DA.;
active_date=&active_date.;
do i = 1 to &active_d. ; history_date=intnx('day',active_date,-i,'end'); output; end;
do i = 1 to &active_m. ; history_date=intnx('month',active_date,-i,'end'); output; end;
do i = 1 to &active_q. ; history_date=intnx('quarter',active_date,-i,'end'); output; end;
do i = 1 to &active_y. ; history_date=intnx('year',active_date,-i,'end'); output; end;
keep	history_date;
run;

proc sort data=history_dates_1 out=history_dates_2(index=(history_date)) nodupkey; by history_date; run;
%mend;
