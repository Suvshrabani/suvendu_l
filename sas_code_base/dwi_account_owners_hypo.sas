%global dw_inlib dw_inlib_play dw_inlib_int dw_outlib dw_replib dw_paylib nobs run_type tenant
date_active acc_monthly_date_active onefactor_date_active country_date_active max_limit_date rwael_date_active loan_date_active 
timedep_date_active acc_monthly_start_date card_date_active card_info_date card_dt_active profit_date_active;

%let timestamp_start=%sysfunc(datetime());

%include "/sasdw/prod/int/programs/stp/finance/macros_dwi.sas";
	/* loads macros and runs macro for tenant and libs */	
%start_dwi();
%start_dwi_manual(path=hypo);

/* GET ACCOUNT OWNERS */
PROC SQL;
   CREATE TABLE WORK.QUERY1 AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.owner_id, 
          t1.source_system_cd, 
          t1.extracted_dt, 
          t1.loaded_dt, 
          /* total_owner_count */
            (COUNT(t1.owner_id)) AS total_owner_count
      FROM &dw_inlib..ACCOUNT_OWNERS t1
      WHERE t1.information_date = &date_active
      GROUP BY t1.information_date,
               t1.bank_id,
               t1.account_id;
QUIT;

/* ENDOWMENT INSURANCE nr 1*/
PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_DWI_ENDOWMENT_INSURANC AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.owner_id, 
          t1.endowment_insurance_holder_id, 
		  t2.customer_type as endowment_holder_customer_type,
          t1.account_close_date, 
          t1.valid_from_date, 
          t1.valid_to_date, 
          t1.active, 
          t1.loaded_dt
      FROM DWI_FINA.DWI_ENDOWMENT_INSURANCE t1
		INNER JOIN 
		&dw_inlib..CUSTOMER_L t2 on t1.bank_id=t2.bank_id and t1.endowment_insurance_holder_id=t2.customer_id
      WHERE t1.information_date = &date_active;
QUIT;

/* ENDOWMENT INSURANCE nr 2*/
PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_DWI_ENDOWMENT_INS_0000 AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          /* MAX_of_active */
            (MAX(t1.active)) AS MAX_of_active
      FROM DWI_FINA.DWI_ENDOWMENT_INSURANCE t1
      WHERE t1.information_date = &date_active
      GROUP BY t1.information_date,
               t1.bank_id,
               t1.account_id;
QUIT;

/* ACCOUNT */
PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_ACCOUNT AS 
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
          t1.close_date
      FROM &dw_inlib..ACCOUNT t1
      WHERE t1.information_date = &date_active;
QUIT;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_DWI_ENDOWMENT_INS_0001 AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
            (MIN(t1.valid_from_date)) FORMAT=FINDFDD10. AS MIN_of_valid_from_date
      FROM WORK.QUERY_FOR_DWI_ENDOWMENT_INSURANC t1, WORK.QUERY_FOR_DWI_ENDOWMENT_INS_0000 t2
      WHERE (t1.bank_id = t2.bank_id AND t1.account_id = t2.account_id AND t1.active = t2.MAX_of_active)
      GROUP BY t1.information_date,
               t1.bank_id,
               t1.account_id;
QUIT;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_DWI_ENDOWMENT_INS_0002 AS 
   SELECT DISTINCT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.owner_id, 
          t1.endowment_insurance_holder_id, 
          /* MIN_of_endowment_insurance_holde */
            (MIN(t1.endowment_insurance_holder_id)) AS MIN_of_endowment_insurance_holde, 
          /* first_owner_flag */
            (case when t1.valid_from_date=MIN_of_valid_from_date then 1 else 0 end) AS first_owner_flag, 
          t1.endowment_holder_customer_type, 
          t1.valid_from_date, 
          t1.active
      FROM WORK.QUERY_FOR_DWI_ENDOWMENT_INSURANC t1, WORK.QUERY_FOR_DWI_ENDOWMENT_INS_0001 t2
      WHERE (t1.bank_id = t2.bank_id AND t1.account_id = t2.account_id AND t1.valid_from_date = 
           t2.MIN_of_valid_from_date)
      GROUP BY t1.information_date,
               t1.bank_id,
               t1.account_id,
               t1.endowment_holder_customer_type;
QUIT;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_DWI_ENDOWMENT_INS AS 
   SELECT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.owner_id, 
          t1.endowment_insurance_holder_id, 
          t1.valid_from_date, 
          t1.first_owner_flag, 
          t1.MIN_of_endowment_insurance_holde, 
            (case when t1.MIN_of_endowment_insurance_holde=endowment_insurance_holder_id then 1 else 0 end) AS 
            min_id_per_type_flag, 
          t1.endowment_holder_customer_type, 
            (MAX(t1.endowment_holder_customer_type)) FORMAT=3. AS MAX_of_customer_type, 
          t1.active, 
            (MAX(t1.active)) AS MAX_of_active, 
            (COUNT(DISTINCT(t1.endowment_insurance_holder_id))) AS COUNT_DISTINCT_of_endowment_insu
      FROM WORK.QUERY_FOR_DWI_ENDOWMENT_INS_0002 t1
      GROUP BY t1.information_date,
               t1.bank_id,
               t1.account_id
      ORDER BY t1.bank_id,
               MAX_of_customer_type DESC,
               COUNT_DISTINCT_of_endowment_insu DESC,
               t1.account_id,
               MAX_of_active DESC,
               t1.endowment_holder_customer_type DESC;
QUIT;

PROC SQL;
   CREATE TABLE WORK.dwi_account_owners AS 
   SELECT DISTINCT t1.information_date, 
          t1.bank_id, 
          t1.account_id, 
          t1.owner_id length=12, 
          /* customer_id */
            (case when t2.endowment_insurance_holder_id is missing then t1.owner_id else 
            t2.endowment_insurance_holder_id end) LABEL=
            "=Kapitalförsäkringstagaren ifall sådan finns, annars kontoägare" AS customer_id, 
          /* endowment_insurance_flag */
            (case when t2.endowment_insurance_holder_id is not missing then 1 else 0 end) LABEL=
            "Kapitalförsäkring=1, annars 0" AS endowment_insurance_flag, 
          t2.active LABEL="=1 om förbehållet är aktivt" AS active_insurance_restr_flag, 
          /* main_account_customer_flag */
            (case 
            when t2.endowment_insurance_holder_id is missing and t1.owner_id=t4.owner_id then 1
            when t3.MAX_of_customer_type=2 and t3.endowment_holder_customer_type=t3.MAX_of_customer_type and 
            min_id_per_type_flag=1 then 1
            when t3.MAX_of_customer_type=1 and min_id_per_type_flag=1 then 1
            else 0
            end) LABEL="=1 om första kapitalförsäkringsägare / kontoägare" AS main_account_customer_flag, 
          /* main_account_owner_flag */
            ( case when 
            t1.owner_id=t4.owner_id then 1
            else 0
            end) LABEL="=1 om owner_id=owner id i ACCOUNT" AS main_account_owner_flag, 
          /* loaded_dt */
            (datetime()) FORMAT=datetime20. AS loaded_dt
      FROM WORK.QUERY1 t1
           LEFT JOIN WORK.QUERY_FOR_DWI_ENDOWMENT_INSURANC t2 ON (t1.bank_id = t2.bank_id) AND (t1.account_id = 
          t2.account_id)
           LEFT JOIN WORK.QUERY_FOR_DWI_ENDOWMENT_INS t3 ON (t2.bank_id = t3.bank_id) AND (t2.account_id = 
          t3.account_id) AND (t2.endowment_insurance_holder_id = t3.endowment_insurance_holder_id)
           INNER JOIN WORK.QUERY_FOR_ACCOUNT t4 ON (t1.bank_id = t4.bank_id) AND (t1.account_id = t4.account_id);
QUIT;

/*Add Vilja accounts. Miaomiao, 2023-06-27*/
data vilja_account_owners;
set dwi_hypo.vilja_account;
bank_id='V';
rename account_owner_ssn=owner_id;
account_id=account_number_official;
keep information_date bank_id	account_id	account_owner_ssn loaded_dt;
where information_date=&DATE_ACTIVE;
run;


data ACCOUNTS_exp_V_och_C;
set dwi_account_owners
vilja_account_owners;
run;

/* --- Start of code for "Export data". --- */

	%dwi_delete(
	del_lib=&dw_outlib,
	del_table=dwi_account_owners,
	del_date=&date_active);

	%dwi_insert(
	from_lib=work,
	from_table=dwi_account_owners,
	to_lib=&dw_outlib,
	to_table=dwi_account_owners);

		%dwi_delete(
	del_lib=&dw_outlib,
	del_table=dwi_account_owners_vilja_test,
	del_date=&date_active);

	%dwi_insert(
	from_lib=work,
	from_table=ACCOUNTS_exp_V_och_C,
	to_lib=&dw_outlib,
	to_table=dwi_account_owners_vilja_test);

	%dwi_create_latest(lib=&dw_outlib,table=dwi_account_owners_vilja_test);

	%dwi_create_latest(lib=&dw_outlib,table=dwi_account_owners);


