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
%start_dwi_manual(path=hypo);

/* --- End of code for "get tenant". --- */

/* --- Start of code for "Program". --- */
proc sql noprint;
select max(booking_date) into :maxdate from dwi_hypo.bg_loan_transaction where booking_date>today()-20;
quit;
/* --- Lägger till konto ,’595’ på Hermans begäran - Oscar D 20230707 --- */
/*Ändrat till interval englit önskemål från Borgo. Miaomiao 20230901*/
%let partner_acc_types= '580' and '599';
/* --- End of code for "Program". --- */

/* --- Start of code for "Query Builder (4)". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_ACCOUNT_L);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_ACCOUNT_L AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.iban_number_id, 
          t1.account_number_official, 
          t1.account_type_cd, 
          t1.currency_cd, 
          t1.owner_id, 
          t1.owner_ssn_id, 
          t1.shared, 
          t1.result_office_id, 
          t1.opened_date, 
          t1.changed_date, 
          t1.end_date, 
          t1.close_date, 
          t1.statement_period_cd, 
          t1.group_account_id, 
          t1.reference_date, 
          t1.source_system_cd, 
          t1.extracted_dt, 
          t1.loaded_dt, 
          t1.blocked_account_cd, 
          t1.closed_account_cd, 
          t1.statement_type_cd, 
          t1.statement_channel_cd, 
          t1.account_address, 
          t1.secret_account, 
          t1.account_text, 
          t1.statement_fee, 
          t1.reminder_letter_cd, 
          t1.open_channel_cd, 
          t1.account_purpose_cd, 
          t1.estimate_balance_cd, 
          t1.maximum_deposite, 
          t1.maximum_withdrawals, 
          t1.origin_of_funds, 
          t1.account_origin_country
      FROM DWH_DW.ACCOUNT t1
      WHERE t1.information_date = &date_active AND t1.account_type_cd between  &partner_acc_types;
QUIT;
/* --- End of code for "Query Builder (4)". --- */

/* --- Start of code for "dröjsmålsräntor etc exempel". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_TRANSACTION_0001);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_TRANSACTION_0001 AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.transaction_id, 
          t1.transaction_sub_id, 
          t1.cbs_transaction_type_cd, 
          t1.main_account_id, 
          t1.counterparty_account_id, 
          t1.customer_account_id, 
          t1.booking_date, 
          t1.value_date, 
          t1.payment_date, 
          t1.creation_dt, 
          t1.teller_id, 
          t1.packet_id, 
          t1.cost_center_id, 
          t1.transaction_amt, 
          t1.transaction_currency_cd, 
          t1.exchange_rate, 
          t1.book_amt, 
          t1.user_id, 
          t1.reference_number_id, 
          t1.system_cd, 
          t1.registration_cd, 
          t1.account_type_cd, 
          t1.archive_code_cd, 
          t1.payment_system_cd, 
          t1.messages_cd, 
          t1.authentication_type_cd, 
          t1.source_system_cd, 
          t1.extracted_dt, 
          t1.loaded_dt
      FROM DWH_DW.TRANSACTION t1
      WHERE t1.information_date > &maxdate AND t1.customer_account_id NOT = '0' AND t1.cbs_transaction_type_cd NOT = '04';
QUIT;
/* --- End of code for "dröjsmålsräntor etc exempel". --- */

/* --- Start of code for "ica transactions". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_TRANSACTION_0002);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_TRANSACTION_0002 AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.transaction_id, 
          t1.transaction_sub_id, 
          t1.cbs_transaction_type_cd, 
          /* main_account_id */
            (t1.customer_account_id) AS main_account_id, 
          t1.counterparty_account_id, 
          t1.customer_account_id, 
          t1.booking_date, 
          t1.value_date, 
          t1.payment_date, 
          t1.creation_dt, 
          t1.teller_id, 
          t1.packet_id, 
          t1.cost_center_id, 
          t1.transaction_amt, 
          t1.transaction_currency_cd, 
          t1.exchange_rate, 
          t1.book_amt, 
          t1.user_id, 
          t1.reference_number_id, 
          t1.system_cd, 
          t1.registration_cd, 
          /* account_type_cd */
            (t2.account_type_cd) AS account_type_cd, 
          t1.archive_code_cd, 
          t1.payment_system_cd, 
          t1.messages_cd, 
          t1.authentication_type_cd, 
          t1.source_system_cd, 
          t1.extracted_dt, 
          t1.loaded_dt

      FROM WORK.QUERY_FOR_TRANSACTION_0001 t1, WORK.QUERY_FOR_ACCOUNT_L t2
      WHERE (t1.bank_id = t2.bank_id AND t1.customer_account_id = t2.account_id);
QUIT;
/* --- End of code for "ica transactions". --- */

/* --- Start of code for "Amortering och lyft". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_TRANSACTION);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_TRANSACTION AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.transaction_id, 
          t1.transaction_sub_id, 
          t1.cbs_transaction_type_cd, 
          t1.main_account_id, 
          t1.counterparty_account_id, 
          t1.customer_account_id, 
          t1.booking_date, 
          t1.value_date, 
          t1.payment_date, 
          t1.creation_dt, 
          t1.teller_id, 
          t1.packet_id, 
          t1.cost_center_id, 
          t1.transaction_amt, 
          t1.transaction_currency_cd, 
          t1.exchange_rate, 
          t1.book_amt, 
          t1.user_id, 
          t1.reference_number_id, 
          t1.system_cd, 
          t1.registration_cd, 
          t1.account_type_cd, 
          t1.archive_code_cd, 
          t1.payment_system_cd, 
          t1.messages_cd, 
          t1.authentication_type_cd, 
          t1.source_system_cd, 
          t1.extracted_dt, 
          t1.loaded_dt
      FROM DWH_DW.TRANSACTION t1
      WHERE t1.booking_date > &maxdate AND t1.account_type_cd between &partner_acc_types;
QUIT;
/* --- End of code for "Amortering och lyft". --- */

/* --- Start of code for "Append Table". --- */
%_eg_conditional_dropds(WORK.Append_Table);
PROC SQL;
CREATE TABLE WORK.Append_Table AS 
SELECT * FROM WORK.QUERY_FOR_TRANSACTION
 OUTER UNION CORR 
SELECT * FROM WORK.QUERY_FOR_TRANSACTION_0002
;
Quit;

/* --- End of code for "Append Table". --- */

/* --- Start of code for "Query Builder (19)". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_CODES_L);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_CODES_L AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.code_number_cd, 
          t1.code_cd, 
          t1.long_name, 
          t1.short_name, 
          t1.source_system_cd, 
          t1.extracted_dt, 
          t1.loaded_dt
      FROM DWH_DW.CODES_L t1
      WHERE t1.code_number_cd = '7';
QUIT;
/* --- End of code for "Query Builder (19)". --- */

/* --- Start of code for "Query Builder (17)". --- */
%_eg_conditional_dropds(WORK.QUERY_FOR_APPEND_TABLE);

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_APPEND_TABLE AS 
   SELECT t1.bank_id, 
          t1.main_account_id, 
          t2.account_number_official AS account_number, 
          t1.booking_date FORMAT=YYMMDDN8. AS booking_date, 
          t1.value_date FORMAT=YYMMDDN8. AS value_date, 
          t1.transaction_amt AS transaction_amt, 
          t1.cbs_transaction_type_cd AS transaction_cd, 
          t1.transaction_id, 
          t1.transaction_sub_id, 
          t3.long_name AS transaction_cd_txt, 
          t4.transaction_msg, 
          /* loaded_dt */
            (datetime()) FORMAT=datetime20. AS loaded_dt
      FROM WORK.APPEND_TABLE t1
           INNER JOIN WORK.QUERY_FOR_ACCOUNT_L t2 ON (t1.bank_id = t2.bank_id) AND (t1.main_account_id = t2.account_id)
           LEFT JOIN WORK.QUERY_FOR_CODES_L t3 ON (t1.bank_id = t3.bank_id) AND (t1.cbs_transaction_type_cd = 
          t3.code_cd)
           LEFT JOIN DWI_HYPO.PAY_TRANSACTION_MESSAGE t4 ON (t1.bank_id = t4.bank_id) AND (t1.transaction_id = 
          t4.transaction_id)
      ORDER BY t1.transaction_id,
               t1.transaction_sub_id;
QUIT;
/* --- End of code for "Query Builder (17)". --- */

/* --- Start of code for "exportkod transaktion". --- */
options compress=yes;
proc sql noprint;
delete from dwi_hypo.BG_LOAN_TRANSACTION where
	transaction_id in (select transaction_id from WORK.QUERY_FOR_APPEND_TABLE);
insert into dwi_hypo.BG_LOAN_TRANSACTION select * from WORK.QUERY_FOR_APPEND_TABLE;


create table dwi_hypo.BG_LOAN_TRANSACTION_L as select * from dwi_hypo.BG_LOAN_TRANSACTION where booking_date>today()-390;
quit;

/*

proc sql noprint;
create table dwi_hypo.BG_LOAN_TRANSACTION as select * from WORK.QUERY_FOR_APPEND_TABLE;
quit;
*/
/* --- End of code for "exportkod transaktion". --- */

*  Begin EG generated code (do not edit this line);
;*';*";*/;quit;
%STPEND;

*  End EG generated code (do not edit this line);

