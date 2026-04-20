/* --- Start of code for "get tenant". --- */
%global dw_inlib dw_inlib_play dw_inlib_int dw_outlib dw_replib dw_paylib dw_inlib_miss nobs run_type tenant
date_active acc_monthly_date_active onefactor_date_active country_date_active max_limit_date rwael_date_active loan_date_active 
timedep_date_active acc_monthly_start_date card_date_active card_info_date card_dt_active profit_date_active env;

%let env=prod;
%let timestamp_start=%sysfunc(datetime());

%if &syshostname=aablstgsas21 %then %do;
	%let env=test;
%end;

%include "/sasdw/&env/int/programs/stp/finance/macros_dwi.sas";
	/* loads macros and runs macro for tenant and libs */	
/*%start_dwi_manual(path=hypo);
%start_dwi_manual(path=hypo);
%start_dwi();*/

/* CHANGE PATH TO FINANCE IF RUNNING EG PROJECT MANUALLY FOR ÅAB
** CHANGE PATH TO HYPO IF RUNNING EG PROJECT MANUALLY FOR HYPO
** WHEN RUNNING PROJECT AS STORED PROCESS THJE PATH IS DETERMINED FROM THE STP PATH AUTOMATICALLY INSTEAD OF THIS VARIABLE
*/

%start_dwi_manual(path=hypo);

/* --- End of code for "get tenant". --- */

/* --- Start of code for "get partner account types". --- */
%include "/sasdw/&env/int/programs/stp/finance/macros_hypo.sas";
/* temporary date setting */



/* Analys tabell Åt borgo med historisk data skapas upp dirket från dwh_dw */




proc sql noprint;
select max(information_date) into :last_loanapp_date from dwi_hypo.dwi_loan_app_changes;
quit;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_LOAN_APPLICATION AS 
   SELECT t1.information_date, 
          t1.case_id, 
          t1.application_id, 
          t1.partner_name, 
          t1.application_type, 
          t1.application_purpose, 
          t1.total_credit_amount, 
          t1.application_status, 
          t1.decision_status, 
          t1.application_pd, 
          t1.risk_classification, 
          t1.currency_cd, 
          t1.created_dt, 
          t1.updated_dt, 
          t1.termination_dt, 
          t1.change_flag, 
		  t1.desired_disbursement_dt, /* Adam Ö 2022-12-14 */
		  t1.desired_increase_amount, /* Adam Ö 2022-12-14 */
		  t1.purpose_of_use, /* Adam Ö 2022-12-14 */
          t1.loaded_dt
      FROM DWH_DW.LOAN_APPLICATION t1
      WHERE change_flag is not missing;
QUIT;
/* --- End of code for "Query Builder (2)". --- */

/* --- Start of code for "Query Builder (5)". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_LOAN_APPLICATION_CAL);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_LOAN_APPLICATION_CAL AS 
   SELECT t1.information_date, 
          t1.application_id, 
          t1.ltv_system_ratio, 
          t1.lti_system_ratio, 
          t1.ltv_application_ratio, 
          t1.lti_application_ratio, 
          t1.kalp, 
          t1.loaded_dt
      FROM DWH_DW.LOAN_APPLICATION_CAL t1;

QUIT;
/* --- End of code for "Query Builder (5)". --- */

/* --- Start of code for "Query Builder (14)". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_LOAN_ADDITIONAL_DATA);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_LOAN_ADDITIONAL_DATA AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.external_application_id, 
          t1.first_withdrawal_date
      FROM DWH_DW.LOAN_ADDITIONAL_DATA t1;
QUIT;
/* --- End of code for "Query Builder (14)". --- */


/* --- Start of code for "Query Builder (13)". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_LOAN_APPLICATION_0006);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_LOAN_APPLICATION_0006 AS 
   SELECT DISTINCT t1.information_date, 
          t1.case_id, 
          t1.application_id, 
          t1.partner_name, 
          t1.application_type, 
          t1.application_purpose, 
          t1.total_credit_amount, 
          t1.application_status, 
          t1.decision_status, 
          t1.application_pd, 
          t1.risk_classification, 
          t1.currency_cd, 
          t1.created_dt, 
          t1.updated_dt, 
          t1.termination_dt, 
          t1.change_flag, 
          t2.ltv_system_ratio, 
          t2.lti_system_ratio, 
          t2.ltv_application_ratio, 
          t2.lti_application_ratio, 
          t2.kalp, 
          /* loan_first_withdrawal_date */
            (MIN(t3.first_withdrawal_date)) FORMAT=FINDFDD10. AS loan_first_withdrawal_date,
		  t1.desired_disbursement_dt, /* Adam Ö 2022-12-14 */
		  t1.desired_increase_amount, /* Adam Ö 2022-12-14 */
		  t1.purpose_of_use,  /* Adam Ö 2022-12-14 */
		  t4.credit_decision_date

      FROM WORK.QUERY_FOR_LOAN_APPLICATION t1
           LEFT JOIN WORK.QUERY_FOR_LOAN_APPLICATION_CAL t2 ON (t1.information_date = t2.information_date) AND 
          (t1.application_id = t2.application_id)
           LEFT JOIN WORK.QUERY_FOR_LOAN_ADDITIONAL_DATA t3 ON (t1.information_date = t3.information_date) AND 
          (t1.application_id = t3.external_application_id)
		   LEFT JOIN dwi_hypo.BG_LOAN_APPLICATION_ANALYSE t4 ON (t1.application_id = t4.application_id)    AND
		  (t1.information_date = t4.information_date) 
      GROUP BY t1.information_date,
               t1.case_id,
               t1.application_id;
QUIT;



proc sql;
create table DWI_LOAN_APPLICATION_ANALYSIS as
select *

from WORK.QUERY_FOR_LOAN_APPLICATION_0006;


proc sql;
create table DWI_LOAN_APPLICATION_ANALYSIS_2 as
select 
	information_date
	,application_id
	,application_status
	,decision_status
	,change_flag
	,created_dt
	,updated_dt
	,termination_dt 

from DWI_LOAN_APPLICATION_ANALYSIS;
quit;


proc sql;  /* För att skapa lead kolumn */
create table ANALYSIS_2_SORTED as
select *
from DWI_LOAN_APPLICATION_ANALYSIS_2
Order by application_id, updated_dt desc;
quit; 

data Lead_data;
	set ANALYSIS_2_SORTED;
	by application_id;
	lead_updated_dt = lag(updated_dt);
	if first.application_id then lead_updated_dt = .;

run;

proc sort data = Lead_data;
by updated_dt;
run;


proc sql;
  create table last as 
  select application_id as max_application_id, information_date 
	from Lead_data
  group by application_id
  having decision_status = 'PENDING' and application_status ne 'APPLICATION_TERMINATED' and change_flag ne 'DELETED' and information_date = max(information_date);
quit;


%let timestamp_start=%sysfunc(datetime(), datetime20.);

/*%put &timestamp_start; */

proc sql;
create table lagged_date as
select 
t1.information_date
,t1.application_id
,t1.application_status
,t1.change_flag
,t1.created_dt
,t1.decision_status
,t1.updated_dt
,t1.termination_dt 
,t3.lead_updated_dt format=datetime20.
,t2.max_application_id
,case when t1.application_id = t2.max_application_id then intck('hour', t1.updated_dt, "&timestamp_start"dt)  else 
intck('hour', t1.updated_dt, t3.lead_updated_dt) end as Antal_timmar

from Lead_data t1
           LEFT JOIN last t2 ON (t1.information_date = t2.information_date) AND 
          (t1.application_id = t2.max_application_id)
           LEFT JOIN lead_data t3 ON (t1.information_date = t3.information_date) AND 
          (t1.application_id = t3.application_id)

order by t1.information_date, t1.application_id;
quit;



proc sql;
create table dwi_hypo.BG_LOAN_APPLICATION_ANALYSE as
select t1.*
,t2.Antal_timmar as Antal_timmar_status

from DWI_LOAN_APPLICATION_ANALYSIS t1
LEFT JOIN lagged_date t2 on t1.application_id = t2.application_id and t1.information_date = t2.information_date;

quit;




proc datasets lib=work nolist;
  delete QUERY_FOR_LOAN_APPLICATION QUERY_FOR_LOAN_APPLICATION_CAL QUERY_FOR_LOAN_ADDITIONAL_DATA QUERY_FOR_LOAN_APPLICATION_0006 DWI_LOAN_APPLICATION_ANALYSIS DWI_LOAN_APPLICATION_ANALYSIS_2 ANALYSIS_2_SORTED Lead_data last lagged_date ;
run;quit;

